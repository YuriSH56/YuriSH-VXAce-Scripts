# =============================================================================
# ** More Weather Effects
# * By YuriSH
# -----------------------------------------------------------------------------
# This script lets you add more weather effects to your game.
#
# WARNING: This script overwrites how Spriteset_Weather works so it might not
# be compatible with other scripts that change Spriteset_Weather's behaviour.
# =============================================================================

$imported = {} if $imported.nil?
$imported["YuriSH_MoreWeatherEffects"] = true

# =============================================================================
# CONFIGURATION BEGIN
# =============================================================================

module YuriSH
  module Const
    module Weather
      # -----------------------------------------------------------------------
      # Here is where you add new weather effects.
      # Format is as follows:
      # -----------------------------------------------------------------------
      # :name   =>    ["texture_name", x_speed, y_speed, opacity_rate, dimness]
      # -----------------------------------------------------------------------
      # :name           - A UNIQUE identifier of the effect.
      #                   There should be no duplicate names otherwise newer
      #                   effects with overwrite older ones.
      # "texture_name"  - Name if the image in "Weather" folder.
      # x_speed         - Horizontal speed of the particle (pixels per second).
      #                   Positive number means moving to the right,
      #                   negative - moving to the left.
      #                   Must be an integer.
      # y_speed         - Same as "x_speed" but for vertical movement.
      #                   Positive number - moving upwards,
      #                   negative number - moving downwards.
      # opacity_rate    - Rate at which opacity is changed.
      #                   Should be a negative number.
      #                   Sprite gets removed when its opacity reaches
      #                   certain threshold (~64). Keep as -12 if unsure.
      # dimness         - Specifies how dark screen will get.
      # -----------------------------------------------------------------------
      EFFECTS = {
      # OG weather effects
      :rain     =>      ["rain",    -1,     6,    -12,    6],
      :storm    =>      ["storm",   -3,     6,    -12,    6],
      :snow     =>      ["snow",    -1,     3,    -12,    6]
      }
    end
  end
end

# =============================================================================
# CONFIGURATION END
# =============================================================================

#==============================================================================
# ** Game_Interpreter
#==============================================================================

class Game_Interpreter
  #--------------------------------------------------------------------------
  # * Set Weather Effect
  # Lets you use new weather effects.
  # For specifics, check original "Set Weather" command.
  #--------------------------------------------------------------------------
  def set_weather_effect(symb, power = 1, duration = 60, wait_for_end = false)
    @params[0] = symb
    @params[1] = power
    @params[2] = duration
    @params[3] = wait_for_end
    command_236 # Calls original "Set Weather"
  end
end

#==============================================================================
# ** Cache
#==============================================================================

module Cache
  #--------------------------------------------------------------------------
  # * Get Weather Graphic
  #--------------------------------------------------------------------------
  def self.weather(filename)
    load_bitmap("Graphics/Weather/", filename)
  end
end

#==============================================================================
# ** Spriteset_Weather
#==============================================================================

class Spriteset_Weather
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize(viewport = nil)
    @viewport = viewport
    init_members
    create_weather_bitmap
  end
  #--------------------------------------------------------------------------
  # * Set Type
  #--------------------------------------------------------------------------
  def type=(new_type)
    @type = new_type
    create_weather_bitmap
  end
  #--------------------------------------------------------------------------
  # * Free
  #--------------------------------------------------------------------------
  def dispose
    @sprites.each {|sprite| sprite.dispose }
    @weather_bitmap.dispose if @weather_bitmap
  end
  #--------------------------------------------------------------------------
  # * Create Weather Bitmap
  #--------------------------------------------------------------------------
  def create_weather_bitmap
    if type == :none
      @weather_bitmap = nil
    else
      @weather_bitmap = Cache.bitmap(YuriSH::Const::Weather::EFFECTS[type][0])
    end
  end
  #--------------------------------------------------------------------------
  # * Update Screen
  #--------------------------------------------------------------------------
  def update_screen
    dim = -dimness
    @viewport.tone.set(dim, dim, dim)
  end
  #--------------------------------------------------------------------------
  # * Get Dimness
  #--------------------------------------------------------------------------
  def dimness
    mult = YuriSH::Const::Weather::EFFECTS[type][4]
    (@power * mult).to_i
  end
  #--------------------------------------------------------------------------
  # * Update Sprite
  #--------------------------------------------------------------------------
  def update_sprite(sprite)
    sprite.ox = @ox
    sprite.oy = @oy
    if @type != :none
      update_sprite_weather(sprite)
    end
    create_new_particle(sprite) if sprite.opacity < 64
  end
  #--------------------------------------------------------------------------
  # * Update Sprite Weather
  #--------------------------------------------------------------------------
  def update_sprite_weather(sprite)
    weather_data = YuriSH::Const::Weather::EFFECTS[type]
    sprite.bitmap = @weather_bitmap
    sprite.x += weather_data[1]
    sprite.y += weather_data[2]
    sprite.opacity += weather_data[3]
  end
end