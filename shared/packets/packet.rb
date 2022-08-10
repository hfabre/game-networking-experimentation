module HugoCo
  module Packets
    class Packet
      attr_reader :id, :client_id, :current_frame

      def initialize(id, content, client_id: nil)
        @id = id
        @content = content
        @data = @content.split(";")
        @client_id = client_id || @data[1].to_i
        @current_frame = @data[2].to_i
      end
    end

    class UnknownPacket < Packet; end
  end
end
