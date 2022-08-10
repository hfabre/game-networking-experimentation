require_relative "./body"

module HugoCo
  class Entity < Body
    AVAILABLE_DIRECTIONS = %i[up down left right]
    LERP_STEP = 0.1

    attr_reader :id, :velocity_x, :velocity_y, :color

    def initialize(id, x, y, w, h, type, gravity: 2, friction: 0.98)
      super(x, y, w, h, type)

      @gravity = gravity
      @friction = friction
      @id = id
      @velocity_x = 0
      @velocity_y = 0
      @max_velocity_x = 10
      @max_velocity_y = 50
      @color = Gosu::Color::GREEN
    end

    def move(direction, force)
      if AVAILABLE_DIRECTIONS.include?(direction)
        send("move_#{direction}", force)
      else
        HugoCo::Engine.logger.debug "Invalid move direction #{direction}"
      end
    end

    def update(_state, _dt)
      @velocity_y *= @gravity
      @velocity_x *= @friction
      clamp_velocity
      @x += @velocity_x
      @y += @velocity_y
    end

    def to_json
      {
        id: @id,
        x: @x,
        y: @y
      }
    end

    def set_pos(x, y)
      @x = x
      @y = y
    end

    def lerp(x, y)
      @x = (x * LERP_STEP) + (@x * (1.0 - LERP_STEP))
      @y = (y * LERP_STEP) + (@y * (1.0 - LERP_STEP))
    end

    private

    def clamp_velocity
      @velocity_x = @max_velocity_x * direction_sign if @velocity_x.abs > @max_velocity_x
      @velocity_y = @max_velocity_y if @velocity_y.abs > @max_velocity_y
      @velocity_x = 0 if @velocity_x > 0 && @velocity_x < 0.1 || @velocity_x < 0 && @velocity_x > -0.1
    end

    def direction_sign
      @velocity_x > 0 ? 1 : -1
    end

    def move_up(force)
      @velocity_y -= force
    end

    def move_down(force)
      @velocity_y += force
    end

    def move_right(force)
      @velocity_x += force
    end

    def move_left(force)
      @velocity_x -= force
    end
  end
end
