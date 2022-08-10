module HugoCo
  module Packets

    # From client: "id_packet(2);id_client;x;y"
    class PlayerSpawnPacket < BasicPacket
      attr_reader :x, :y

      def self.id
        2
      end

      def initialize(_id, content, client_id: nil)
        super(self.id, content, client_id: client_id)
      end

      def process
        @x = @data[3].to_i
        @y = @data[4].to_i
      end

      def to_msg(current_frame, x, y)
        [base_msg(current_frame), x, y].join(";")
      end
    end
  end
end
