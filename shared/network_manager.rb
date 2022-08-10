require_relative "./packets/packet"
require_relative "./packets"

module HugoCo
  class NetworkManager
    attr_accessor :socket

    def initialize(socket, ping: 0, packet_loss: 0, packet_reader: PacketReader.new)
      @socket = socket
      @ping = ping
      @packet_loss = packet_loss
      @packet_reader = packet_reader
      @packets_to_not_skip = [0, 2]
    end

    def bind(host, port)
      @host = host
      @port = port
      @socket.bind(host, port)
    end

    def read(data)
      HugoCo::Engine.logger.info "Reading #{data}" unless data.split(";")[0].to_i == 3
      packet = @packet_reader.identify(data)
    end

    def send(client, data)
      HugoCo::Engine.logger.info "Sending #{data} to #{client}" unless data.split(";")[0].to_i == 3

      Thread.new do

        # Since at the moment we don't handle packet acknowledgement, avoid to skip important packets (welcome, player_spawn)
        if @packets_to_not_skip.include?(data.split(";")[0].to_i) || rand > (@packet_loss / 100.0)
          sleep(@ping / 1000) if @ping > 0
          @socket.send(data, 0, client.host, client.port)
        end
      end
    end
  end

  class PacketReader
    def initialize
      @packets = {
        0 => HugoCo::Packets::WelcomePacket,
        1 => HugoCo::Packets::MovePacket,
        2 => HugoCo::Packets::PlayerSpawnPacket,
        3 => HugoCo::Packets::SyncStatePacket,
        4 => HugoCo::Packets::ActionPacket,
        5 => HugoCo::Packets::ReActionPacket,
        6 => HugoCo::Packets::ReActionResultPacket
      }
    end

    def identify(packet)
      p_id = packet.split(";").first.to_i
      @packets.fetch(p_id, HugoCo::Packets::UnknownPacket).from_packet(packet)
    end
  end
end
