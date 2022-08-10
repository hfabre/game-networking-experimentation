module HugoCo
  class GosuRenderer
    attr_reader :window

    def initialize(window: GameWindow.new(1280, 720, "GosuRenderer"))
      require "gosu"
      @window = window
    end

    def draw(state)
      @window.state = state
      @window.tick
    end
  end

  class VoidRenderer
    def draw(_state); end
  end

  class GameWindow < Gosu::Window
    attr_writer :state

    def initialize(width, height, title)
      super(width, height)
      self.caption = title
      @state = nil
      @font = Gosu::Font.new(15)
    end

    def update
      # Engine.logger.debug("Updating game window")
    end

    def draw
      if @state
        @state[:entities].each do |entity|
          Gosu.draw_rect(entity.x, entity.y, entity.w, entity.h, entity.color)
        end

        @state[:blocks].each do |block|
          Gosu.draw_rect(block.x, block.y, block.w, block.h, Gosu::Color::GRAY)
        end

        # Debug
        if SERVER
          @state[:entities].select { |e| e.type == :player }.each_with_index do |e, i|
            @font.draw_text("Player #{e.id} at #{e.x} - #{e.y}", 10, (i + 1) * 12, 1, 1, 1)
          end
        else
          @font.draw_text("Player information", 10, 10, 1, 1, 1)
          player = find_player($id)

          if player
            @font.draw_text("Id: #{$id}", 10, 30, 1, 1, 1)
            @font.draw_text("Position: #{player.x} - #{player.y}", 10, 50, 1, 1, 1)
            @font.draw_text("Velocity: #{player.velocity_x} - #{player.velocity_y}", 10, 70, 1, 1, 1)
          end
        end
      else
        HugoCo::Engine.logger.debug("No state to render")
      end
    end

    def find_player(id)
      @state[:entities].find { |entity| entity.id == id && entity.type == :player }
    end
  end

  # TODO: Find a non-coupling way to send back input to the engine
  class InteractiveGameWindow < GameWindow
    attr_accessor :engine

    def initialize(engine, width, height, title)
      super(width, height, title)
      @engine = engine
    end

    def button_down(button_id)
      case button_id
      when Gosu::KB_SPACE
        Engine.logger.debug("Jump")
        @engine.move_player(1, :up)
        Engine.logger.debug("End Jump")
      else
        super
      end
    end

    def update
      if self.button_down? Gosu::Button::KbD
        Engine.logger.debug("Right")
        @engine.move_player(1, :right)
        Engine.logger.debug("End Right")
      end

      if self.button_down? Gosu::Button::KbA
        Engine.logger.debug("Left")
        @engine.move_player(1, :left)
        Engine.logger.debug("End Left")
      end

      if self.button_down? Gosu::KB_ESCAPE
        raise StandardError.new("Closing")
      end
    end
  end

  class NetworkedGameWindow < InteractiveGameWindow
    attr_writer :id

    def initialize(engine, network_manager, server, width, height, title)
      super(engine, width, height, title)
      @network_manager = network_manager
      @server = server
    end

    def button_down(button_id)
      case button_id
      when Gosu::KB_SPACE
        Engine.logger.debug("Jump")
        @engine.move_player(@id, :up)
        @network_manager.send(@server, Packets::MovePacket.to_packet(@id).to_msg(@engine.frame, :up))
        Engine.logger.debug("End Jump")
      when Gosu::MS_LEFT
        Engine.logger.debug("React")
        @network_manager.send(@server, Packets::ReActionPacket.to_packet(@id).to_msg(@engine.frame))
      else
        super
      end
    end

    def update
      if self.button_down? Gosu::Button::KbD
        Engine.logger.debug("Right")
        @engine.move_player(@id, :right)
        @network_manager.send(@server, Packets::MovePacket.to_packet(@id).to_msg(@engine.frame, :right))
        Engine.logger.debug("End Right")
      end

      if self.button_down? Gosu::Button::KbA
        Engine.logger.debug("Left")
        @engine.move_player(@id, :left)
        @network_manager.send(@server, Packets::MovePacket.to_packet(@id).to_msg(@engine.frame, :left))
        Engine.logger.debug("End Left")
      end

      if self.button_down? Gosu::KB_ESCAPE
        raise StandardError.new("Closing")
      end
    end
  end
end
