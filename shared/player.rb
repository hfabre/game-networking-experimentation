require_relative "./entity"
require_relative "./aabb_collision"

module HugoCo
  class Player < Entity
    attr_reader :x, :y
    attr_accessor :color

    WIDTH = 30
    HEIGHT = 30
    SPEED = 3
    JUMP_SPEED = 30

    def initialize(id, x, y)
      super(id, x, y, WIDTH, HEIGHT, :player, friction: 0.90)
      @color = Gosu::Color::BLUE
    end

    def move(direction)
      super(direction, direction == :up ? JUMP_SPEED : SPEED)
    end

    def update(state, _dt)
      @velocity_y += @gravity
      @velocity_x *= @friction

      state[:blocks].each do |block|
        if AABBCollision.collide?(self.rect, block.rect, side_by_side: true)
          direction = AABBCollision.collision_direction(self.rect, block.rect)

          case direction
          when :bottom
            @velocity_y = 0 if @velocity_y > 0
            @y = block.y - @h
          when :top
            Engine.logger.debug("colliding up")
            @velocity_y if @velocity_y < 0
            @y = block.y
          when :right
            Engine.logger.debug("colliding right")
            @velocity_x if @velocity_x < 0
            @x = block.x
          when :left
            Engine.logger.debug("colliding left")
            @velocity_x if @velocity_x > 0
            @x = block.x + block.w
          end
        end
      end

      clamp_velocity
      @x += @velocity_x
      @y += @velocity_y
    end
  end
end
