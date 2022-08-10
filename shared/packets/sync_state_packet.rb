require "json"

module HugoCo
  module Packets

    # From client: "id_packet(3);id_client;current_frame;state"
    class SyncStatePacket < BasicPacket
      attr_reader :state

      def self.id
        3
      end

      def initialize(_id, content, client_id: nil)
        super(self.id, content, client_id: client_id)
      end

      def process
        @state = JSON.parse(@data[3])
      end

      def to_msg(current_frame, state_hash)
        [base_msg(current_frame), JSON.generate(state_hash || @state)].join(";")
      end
    end
  end
end
