module HugoCo
  module AABBCollision
    def self.collide?(main_body, other_body, side_by_side: false)
      p1x = [main_body.x, other_body.x].max
      p1y = [main_body.y, other_body.y].max
      p2x = [main_body.x + main_body.width, other_body.x + other_body.width].min
      p2y = [main_body.y + main_body.height, other_body.y + other_body.height].min

      if side_by_side && p2x - p1x >= 0 && p2y - p1y >= 0
        true
      elsif !side_by_side && (p2x - p1x).positive? && (p2y - p1y).positive?
        true
      else
        false
      end
    end

    def self.collision_direction(main_body, other_body)
      left = (main_body.x + main_body.width) - other_body.x
      right = (other_body.x + other_body.width) - main_body.x
      bottom = (main_body.y + main_body.height) - other_body.y
      top = (other_body.y + other_body.height) - main_body.y

      if right < left && right < top && right < bottom
        return :right
      elsif left < top && left < bottom
        return :left
      elsif top < bottom
        return :top
      else
        return :bottom
      end
    end
  end
end
