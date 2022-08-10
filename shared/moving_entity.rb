module HugoCo
  class MovingEntity < Entity
    WIDTH = 30
    HEIGHT = 30
    SPEED = 3

    def initialize(id, x, y)
      super(id, x, y, WIDTH, HEIGHT, :moving_entity)
      @dir = 1
    end

    def update(state, _dt)
      update_dir
      @velocity_x = SPEED * @dir
      clamp_velocity
      @x += @velocity_x
      @y += @velocity_y
    end

    private

    def update_dir
      if @dir.positive? && @x > 1200
        @dir = -1
      elsif @dir.negative? && @x < 80
        @dir = 1
      end
    end
  end
end
