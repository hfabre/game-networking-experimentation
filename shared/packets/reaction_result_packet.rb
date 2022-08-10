module HugoCo
  module Packets

    # From client: "id_packet(6);id_client;current_frame;result(0|1)"
    class ReActionResultPacket < BasicPacket
      attr_reader :result

      def self.id
        6
      end

      def initialize(_id, content, client_id: nil)
        super(self.id, content, client_id: client_id)
      end

      def process
        @result = !@data[3].to_i.zero?
      end

      def to_msg(current_frame, result)
        [base_msg(current_frame), result ? 1 : 0].join(";")
      end
    end
  end
end
