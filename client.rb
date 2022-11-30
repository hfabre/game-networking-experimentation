require "gosu"
require "socket"
require "optparse"
require_relative "./shared/engine"
require_relative "./shared/packets/packet"
require_relative "./shared/network_manager"

module HugoCo
  SERVER = false
  WIDTH = 600
  HEIGHT = 400
  GROUND_HEIGHT = 50

  class RemoteServer
    attr_reader :host, :port

    def initialize(host, port)
      @host = host
      @port = port
    end

    def to_s
      "Server: #{@host}:#{@port}"
    end
  end

  class Client
    MAX_PACKET_SIZE = 1024

    def initialize(port: 9998, ping: 0, packet_loss: 0, sync: false, lerp: false, network: false)
      @network = network

      if @network
        @host = "127.0.0.1"
        @port = port
        @server = RemoteServer.new("127.0.0.1", 9999)
        @network_manager = NetworkManager.new(UDPSocket.new, ping: ping, packet_loss: packet_loss)
        renderer = GosuRenderer.new(window: NetworkedGameWindow.new(nil, @network_manager, @server, WIDTH, HEIGHT, "Client #{@port} / PL: #{packet_loss} / PING: #{ping}"))
      else
        renderer = GosuRenderer.new(window: InteractiveGameWindow.new(nil, WIDTH, HEIGHT, "Local client"))
      end

      @engine = Engine.new(renderer: renderer, sync: sync, lerp: lerp)
    end

    def run
      opts = {}

      if @network
        HugoCo::Engine.logger.info "Starting UDP server at #{@host}:#{@port}"
        @network_manager.bind(@host, @port)

        Thread.new do
          loop do
            data, cli = @network_manager.socket.recvfrom(MAX_PACKET_SIZE)
            Thread.new(cli) do |addr|
              HugoCo::Engine.logger.info "Received message from unknown entity" && return if addr[2] != @server.host && addr[1] != @server.port

              packet = @network_manager.read(data)

              if packet.is_a?(Packets::WelcomePacket)
                packet.from_server
                @id = packet.new_client_id
                # TODO: Don't
                $id = @id
                @engine.renderer.window.id = @id
                @engine.spawn_player_by_id(@id, x: packet.x, y: packet.y)
                HugoCo::Engine.logger.info "Setting id as #{@id} and spawning player at #{packet.x} - #{packet.y}"
              elsif packet.is_a?(Packets::PlayerSpawnPacket)
                packet.process
                @engine.spawn_player_by_id(packet.client_id, x: packet.x, y: packet.y)
              elsif packet.is_a?(Packets::MovePacket)
                packet.process
                @engine.move_player(packet.client_id, packet.direction.to_sym)
              elsif packet.is_a?(Packets::SyncStatePacket)
                packet.process
                @engine.sync_state(packet.state)
              elsif packet.is_a?(Packets::ActionPacket)
                @engine.change_player_color($id, Gosu::Color::YELLOW)
              elsif packet.is_a?(Packets::ReActionResultPacket)
                packet.process
                @engine.change_player_color($id, packet.result ? Gosu::Color::GREEN : Gosu::Color::RED, 0)
              else
                HugoCo::Engine.logger.warn "Unhandled packet #{packet.id}"
              end
            end
          end
        end

        @network_manager.send(@server, Packets::WelcomePacket.new(0, "").to_server(@port))
      else
        $id = 1
        opts[:with_player] = true
      end

      @engine.run(**opts)
    end
  end
end

params = {}
OptionParser.new do |opts|
  opts.on("-p PORT", "--port PORT", "Port to bind", Integer)
  opts.on("-f PACKET_LOSS_PERCENTAGE", "--packet_loss PACKET_LOSS_PERCENTAGE", "Simulated packet loss percentage (%)", Integer)
  opts.on("-l PING", "--ping PING", "Simulated latency (ms)", Integer)
  opts.on("-s", "--sync", "Should syncronize state")
  opts.on("-i", "--lerp", "Should syncronize state with linear interpolation, do nothing without sync (-s) option")
  opts.on("-n", "--network", "Run in networked mode")
  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end.parse!(into: params)

HugoCo::Client.new(**params).run
