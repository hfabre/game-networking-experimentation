module HugoCo
  module Packets

    # From client: "id_packet(5);id_client;current_frame"
    class ReActionPacket < BasicPacket
      attr_reader :x, :y

      def self.id
        5
      end

      def initialize(_id, content, client_id: nil)
        super(self.id, content, client_id: client_id)
      end

      def process
      end

      def to_msg(current_frame)
        base_msg(current_frame)
      end
    end
  end
end
