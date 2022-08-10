module HugoCo
  module Packets

    # From client: "id_packet(1);id_client;current_frame;direction"
    class MovePacket < BasicPacket
      attr_reader :direction

      def self.id
        1
      end

      def initialize(_id, content, client_id: nil)
        super(self.id, content, client_id: client_id)
      end

      def process
        @direction = @data[3].to_sym
      end

      def to_msg(current_frame, direction)
        [base_msg(current_frame), direction || @direction].join(";")
      end
    end
  end
end
