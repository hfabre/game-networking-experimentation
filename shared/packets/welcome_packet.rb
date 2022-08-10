module HugoCo
  module Packets

    # From client: "id_packet(0);;client_port"
    class WelcomePacket < Packet
      attr_reader :client_port, :new_client_id, :x, :y

      def self.id
        0
      end

      def initialize(_id, content)
        super(self.id, content)
      end

      def self.from_packet(content)
        self.new(self.id, content)
      end

      def from_client
        @client_port = @data[2].to_i
      end

      def from_server
        @new_client_id = @data[1].to_i
        @x = @data[2].to_i
        @y = @data[3].to_i
      end

      def to_server(port)
        "0;;#{port}"
      end

      def to_client(client, x, y)
        "0;#{client.id};#{x};#{y}"
      end
    end
  end
end
