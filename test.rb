require 'gosu'

class GameWindow < Gosu::Window
  def initialize
    super(640, 480)

    @font = Gosu::Font.new(self, Gosu::default_font_name, 15)
    @frame = 0
  end

  def run
    while running?
      tick
    end

    close
  end

  def update
    raise "Should raise, stop and show backtrace, but no"
    @frame += 1
  end

  def draw
    @font.draw_text("Frame number #{@frame}", 10, 30, 1, 1, 1)
  end

  private

  def running?
    @frame < 1000
  end
end

GameWindow.new.run
