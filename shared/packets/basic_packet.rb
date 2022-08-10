module HugoCo
  module Packets
    class BasicPacket < Packet

      def self.from_packet(content)
        self.new(self.id, content)
      end

      def self.to_packet(client_id)
        self.new(self.id, "", client_id: client_id)
      end

      def base_msg(current_frame)
        "#{self.class.id};#{@client_id};#{current_frame}"
      end
    end
  end
end
