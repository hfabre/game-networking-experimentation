require "logger"
require "gosu"
require_relative "./body"
require_relative "./entity"
require_relative "./player"
require_relative "./renderer"
require_relative "./moving_entity"

module HugoCo
  class Engine
    ACTION_FRAME = 120

    attr_reader :renderer, :frame

    def self.logger
      @logger ||= Logger.new(STDOUT)
    end

    def initialize(renderer: VoidRenderer.new, sync: false, lerp: false)
      @current_entity_id = 0
      @entities = []
      @blocks = [Body.new(0, HEIGHT - GROUND_HEIGHT, 1280, GROUND_HEIGHT, :block)]
      @renderer = renderer
      @sync = sync
      @lerp = lerp
      @frame = 0
      @frame_color_change_countdown = 0

      @renderer.window.engine = self if @renderer.window.respond_to?(:engine=) && @renderer.window.engine.nil?
    end

    def run(with_player: false)
      Engine.logger.info("Starting engine")
      spawn_player_by_id(1) if with_player
      dt = 0

      loop do
        tick(dt)
        @renderer.draw(state)

        @frame += 1
        if @frame_color_change_countdown > 0
          @frame_color_change_countdown -= 1
          if @frame_color_change_countdown <= 0
            find_player($id).color = Gosu::Color::BLUE
          end
        end
        # TODO: handle timestep
        sleep(1 / 60.0)
      end
    end

    def spawn_player(x: 10, y: 10)
      spawn_player_by_id(next_entity_id, x: x, y: y)
    end

    def spawn_player_by_id(id, x: 10, y: 10)
      Engine.logger.debug("Spawning player #{id} to #{x} - #{y}")
      player = Player.new(id, x, y)
      @entities << player
      player
    end

    def move_player(id, direction)
      Engine.logger.debug("Trying to move player #{id} (#{id.class}) to the #{direction}")
      player = find_player(id)
      if player
        Engine.logger.debug("Moving player #{id} to #{direction}")
        player.move(direction)
      else
        Engine.logger.debug("Invalid action move_player: Player #{id} not found")
      end
    end

    def find_player(id)
      @entities.find { |entity| entity.id == id && entity.type == :player }
    end

    def state
      { entities: @entities, blocks: @blocks }
    end

    def json_state
      { entities: @entities.map(&:to_json) }
    end

    def sync_state(remote_state)
      return unless @sync

      remote_state["entities"].each do |remote_entity|
        entity = @entities.find { |e| e.id == remote_entity["id"].to_i }

        if @lerp
          entity.lerp(remote_entity["x"].to_f, remote_entity["y"].to_f)
        else
          entity.set_pos(remote_entity["x"].to_f, remote_entity["y"].to_f)
        end
      end
    end

    def change_player_color(id, color, time = ACTION_FRAME)
      find_player(id).color = color
      @frame_color_change_countdown = time if time > 0
    end

    private

    def next_entity_id
      @current_entity_id += 1
    end

    def tick(dt)
      @entities.each do |entity|
        entity.update(state, dt)
      end
    end
  end
end
