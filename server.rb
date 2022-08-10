require "ruby_jard"
require "optparse"
require_relative "./shared/engine"
require_relative "./shared/packets/packet"
require_relative "./shared/network_manager"

module HugoCo
  SERVER = true
  WIDTH = 600
  HEIGHT = 400
  GROUND_HEIGHT = 50

  class RemoteClient
    attr_reader :host, :port
    attr_accessor :id, :joined_at, :remote_joined_at

    def initialize(host, port, id = nil)
      @id = id
      @host = host
      @port = port
    end

    def frame_diff
      joined_at - remote_joined_at
    end

    def to_s
      "Client: #{@id || "Not registered"} - #{@host}:#{@port}"
    end
  end

  class Server
    MAX_PACKET_SIZE = 1024
    MAX_CLIENTS = 4

    def initialize(host: "127.0.0.1", port: "9999", lag_comp: false)
      renderer = GosuRenderer.new(window: GameWindow.new(WIDTH, HEIGHT, "Server"))
      @lag_comp = lag_comp
      @engine = Engine.new(renderer: renderer)
      @host = host
      @port = port
      @clients = []
      @network_manager = NetworkManager.new(UDPSocket.new)
    end

    def run
      run_udp_server
      @engine.run
    end

    private

    def run_udp_server
      HugoCo::Engine.logger.info "Starting UDP server at #{@host}:#{@port}"
      @network_manager.bind(@host, @port)

      HugoCo::Engine.logger.info "Starting sync loop"
      # This loop is reponsible to send current state to all clients once every 3 frames (almost)
      # A frame is almost 1 / 60 (once again this is an over simplification)
      Thread.new do
        loop do
          sleep(3 / 60.0)
          state = @engine.json_state
          @clients.each do |c|
            packet = Packets::SyncStatePacket.to_packet(c.id).to_msg(@engine.frame, state)
            @network_manager.send(c, packet)
          end
        end
      end

      # This loop is reponsible to make the call for action
      # I use it to demonstrate lag compensation
      Thread.new do
        loop do
          sleep(10)
          @clients.each do |c|
            packet = Packets::ActionPacket.to_packet(c.id).to_msg(@engine.frame)
            @last_action_frame = @engine.frame
            @network_manager.send(c, packet)
          end
        end
      end

      # TODO: Use ractors ?
      Thread.new do
        loop do
          data, cli = @network_manager.socket.recvfrom(MAX_PACKET_SIZE)
          Thread.new(cli) do |addr|
            packet = @network_manager.read(data)

            if packet.is_a?(Packets::WelcomePacket)
              packet.from_client
              client = RemoteClient.new(addr[2], packet.client_port, packet.client_id)

              if @clients.size >= MAX_CLIENTS
                @network_manager.send(client, "Server full")
              else
                if !find_client(client)
                  player = @engine.spawn_player
                  client.id = player.id
                  client.joined_at = @engine.frame
                  client.remote_joined_at = packet.current_frame
                  @clients << client
                  @network_manager.send(client, packet.to_client(client, player.x, player.y))

                  other_clients(client).each do |c|
                    @network_manager.send(c, Packets::PlayerSpawnPacket.to_packet(client.id).to_msg(@engine.frame, player.x, player.y))
                    other_player = @engine.find_player(c.id)
                    @network_manager.send(client, Packets::PlayerSpawnPacket.to_packet(c.id).to_msg(@engine.frame, other_player.x, other_player.y))
                  end
                else
                  @network_manager.send(client, "Already connected")
                end
              end
            elsif packet.is_a?(Packets::MovePacket)
              packet.process
              sendin_client = find_client_by_id(packet.client_id)
              @engine.move_player(packet.client_id, packet.direction.to_sym)

              other_clients(sendin_client).each do |c|
                @network_manager.send(c, packet.to_msg(@engine.frame, nil))
              end
            elsif packet.is_a?(Packets::ReActionPacket)
              sendin_client = find_client_by_id(packet.client_id)
              action_frame = packet.current_frame

              if @lag_comp
                result = (packet.current_frame + sendin_client.frame_diff) - @last_action_frame <= HugoCo::Engine::ACTION_FRAME
              else
                result = @engine.frame - @last_action_frame <= HugoCo::Engine::ACTION_FRAME
              end

              Engine.logger.debug "Current frame: #{@engine.frame} | Last action frame: #{@last_action_frame} | Action frame: #{HugoCo::Engine::ACTION_FRAME}"
              @network_manager.send(sendin_client, Packets::ReActionResultPacket.to_packet(sendin_client.id).to_msg(@engine.frame, result))
            else
              HugoCo::Engine.logger.warn "Unhandled packet #{packet.id}"
            end
          end
        end
      end
    end

    def find_client(client)
      if client.id && client.id != 0
        @clients.find { |c| c.id == client.id }
      else
        @clients.find { |c| c.host == client.host && c.port == client.port }
      end
    end

    def find_client_by_id(id)
      @clients.find { |c| c.id == id }
    end

    def other_clients(client)
      @clients.select { |c| c.id != client.id }
    end
  end
end

params = {}
OptionParser.new do |opts|
  opts.on("-l", "--lag_comp", "Activate lag compensation")
  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end.parse!(into: params)

HugoCo::Server.new(**params).run
