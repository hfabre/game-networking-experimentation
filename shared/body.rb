require "ostruct"

module HugoCo
  class Body
    attr_reader :x, :y, :w, :h, :type

    def initialize(x, y, w, h, type)
      @x = x
      @y = y
      @w = w
      @h = h
      @type = type
    end

    def rect
      OpenStruct.new(x: x, y: y, width: w, height: h)
    end
  end
end
