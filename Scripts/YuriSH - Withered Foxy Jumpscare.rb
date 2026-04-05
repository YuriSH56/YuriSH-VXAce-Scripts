#==============================================================================
# ** Withered Foxy Jumpscare
# * By YuriSH
# -----------------------------------------------------------------------------
# * UPDATES HISTORY
# -----------------------------------------------------------------------------
# * Version 1.0 (01.28.2026)
#     Initial release.
#
# * Version 1.1 (04.05.2026)
#     Bug fixes.
#     Can now be toggled.
#
#------------------------------------------------------------------------------
# Withered Foxy jumpscare right in your RPGMaker game!
# Put "foxy.png" into "Pictures" folder.
# Put "Foxy Jumpscare.ogg" into "Audio/SE" folder.
#
# Technically, this script allows you to create ANY animated jumpscare.
# Check config section for details.
#
# To temporary disable/enable the jumpscare use the script call:
# * toggle_jumpscare(TrueOrFalse)
#==============================================================================

$imported = {} if $imported.nil?
$imported["YuriSH_FoxyJumpscare"] = true

# =============================================================================
# CONFIGURATION BEGIN
# =============================================================================

module YuriSH
  module Const
    module Foxy
      # Z-Index of jumpscare image
      # Adjust if other scripts use this value and you want jumpscare
      # to appear above everything else
      Z_INDEX = 1000
      # Chance of jumpscare to appear each frame
      # 1.0 is 100% chance
      # Default is 0.000001 (Like 1/1000000 chance)
      CHANCE = 0.000001
      # Delay between jumpscares (in frames)
      # Default is 1200 frames (20 seconds)
      DELAY = 1200
      # Sound that will play when jumpscare occurs
      # Keep as "" if you don't want any sound
      # Sound must be placed in "Audio/SE" folder
      SOUND_NAME = "Foxy Jumpscare"
      # Sound volume (0 - 100)
      SOUND_VOLUME = 60
      # Sound pitch (50 - 150)
      SOUND_PITCH = 100
      # Screen flash color (R, G, B, A)
      # Each value is 0 - 255
      # Alpha of 255 - fully opaque
      # Alpha of 0 - fully transparent
      FLASH_COLOR = Color.new(255,0,0,255)
      # Screen flash duration (in frames)
      # Default is 120 frames (2 seconds)
      FLASH_DURATION = 60
      
      # Technical constants, DO NOT CHANGE
      
      # Jumpscare Name
      # Must be placed in "Pictures" folder
      IMAGE = "foxy"
      # Image Cell Size (x, y)
      CELL_SIZE = {:x => 1024, :y => 768}
      # Image Cells (x, y)
      CELLS = {:x => 2, :y => 7}
      # Time Between Cells (In Frames)
      SPEED = 2
      # Image Scale
      SCALE = 0.65
      
      # If true - jumpscare will process.
      # Set to false to temporary disable the jumpscare.
      @enabled = true
      
      #----------------------------------------------------------------------
      # * Toggles Jumpscare Processing
      #----------------------------------------------------------------------
      def self.toggle(value)
        @enabled = value
      end
      #----------------------------------------------------------------------
      # * Is Jumpscare Enabled?
      #----------------------------------------------------------------------
      def self.enabled?
        return @enabled
      end
      #----------------------------------------------------------------------
      # * Returns Hash Of Values
      #----------------------------------------------------------------------
      def self.get_hash
        return {
          :z_index        => YuriSH::Const::Foxy::Z_INDEX,
          :chance         => YuriSH::Const::Foxy::CHANCE,
          :delay          => YuriSH::Const::Foxy::DELAY,
          :sound_name     => YuriSH::Const::Foxy::SOUND_NAME,
          :sound_volume   => YuriSH::Const::Foxy::SOUND_VOLUME,
          :sound_pitch    => YuriSH::Const::Foxy::SOUND_PITCH,
          :flash_color    => YuriSH::Const::Foxy::FLASH_COLOR,
          :flash_duration => YuriSH::Const::Foxy::FLASH_DURATION,
          :image          => YuriSH::Const::Foxy::IMAGE,
          :cell_size      => YuriSH::Const::Foxy::CELL_SIZE,
          :cells          => YuriSH::Const::Foxy::CELLS,
          :speed          => YuriSH::Const::Foxy::SPEED,
          :scale          => YuriSH::Const::Foxy::SCALE,
        }
      end
    end
  end
end

# =============================================================================
# CONFIGURATION END
# =============================================================================

#==============================================================================
# ** Sprite_FoxyJumpscare
#==============================================================================

class Sprite_FoxyJumpscare < Sprite
  #--------------------------------------------------------------------------
  # * Object Initialization
  #     picture : Game_Picture
  #--------------------------------------------------------------------------
  def initialize(viewport)
    super(viewport)
    @counter = 0
    @debounce_counter = SceneManager.scene.transition_speed
    @frame = -1
    @enabled = true
    get_hash_of_data
    cache_image
    update
  end
  #--------------------------------------------------------------------------
  # * Assigns Hash Of Data
  # (Because Constant Names Are So Damn Long)
  #--------------------------------------------------------------------------
  def get_hash_of_data
    @data = YuriSH::Const::Foxy.get_hash
  end
  #--------------------------------------------------------------------------
  # * Cache Image To Prevent Lag
  #--------------------------------------------------------------------------
  def cache_image
    Cache.picture(@data[:image])
  end
  #--------------------------------------------------------------------------
  # * Free
  #--------------------------------------------------------------------------
  def dispose
    bitmap.dispose if bitmap
    super
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  def update
    super
    update_enabled
    return unless @enabled
    roll_chance
    update_bitmap
    update_other
    update_jumpscare
  end
  #--------------------------------------------------------------------------
  # * Checks If Enabled State Changes
  #--------------------------------------------------------------------------
  def update_enabled
    new_val = YuriSH::Const::Foxy.enabled?
    if new_val != @enabled
      toggle(new_val)
    end
  end
  #--------------------------------------------------------------------------
  # * Update Transfer Origin Bitmap
  #--------------------------------------------------------------------------
  def update_bitmap
    if @frame < 0
      self.bitmap = nil
    else
      self.bitmap = cache_image
    end
  end
  #--------------------------------------------------------------------------
  # * Update Jumpscare Process
  #--------------------------------------------------------------------------
  def update_jumpscare
    @counter -= 1
    if @counter == 0
      if @frame == @data[:cells][:x] * @data[:cells][:y] - 1
        @frame = -1
        $game_map.screen.start_flash(@data[:flash_color], @data[:flash_duration])
        return
      end
      @frame += 1
      @counter = @data[:speed]
    end
  end
  #--------------------------------------------------------------------------
  # * Update Other Stuff
  #--------------------------------------------------------------------------
  def update_other
    s_x = @frame / @data[:cells][:y]
    s_y = @frame % @data[:cells][:y]
    self.z = @data[:z_index]
    self.ox = @data[:cell_size][:x] / 2
    self.oy = @data[:cell_size][:y] / 2
    self.x = Graphics.width / 2
    self.y = Graphics.height / 2
    self.src_rect.set(
      s_x * @data[:cell_size][:x],
      s_y * @data[:cell_size][:y],
      @data[:cell_size][:x],
      @data[:cell_size][:y])
    self.zoom_x = @data[:scale]
    self.zoom_y = @data[:scale]
  end
  #--------------------------------------------------------------------------
  # * Roll Jumpscare Chance
  #--------------------------------------------------------------------------
  def roll_chance
    return if @frame >= 0
    if @debounce_counter > 0
      @debounce_counter -= 1
      return
    end
    if rand < @data[:chance]
      init_jumpscare
    end
  end
  #--------------------------------------------------------------------------
  # * Jumpscare Initialization
  #--------------------------------------------------------------------------
  def init_jumpscare
    @frame = 0
    @debounce_counter = @data[:delay]
    @counter = @data[:speed]
    return if @data[:sound_name].empty?
    Audio.se_play("Audio/SE/" + @data[:sound_name], @data[:sound_volume], @data[:sound_pitch])
  end
  #--------------------------------------------------------------------------
  # * Resets Jumpscare
  #--------------------------------------------------------------------------
  def reset_jumpscare
    @counter = 0
    @debounce_counter = 0
    @frame = -1
    update_bitmap
    update_other
  end
  #--------------------------------------------------------------------------
  # * Toggle Jumpscare
  #--------------------------------------------------------------------------
  def toggle(value)
    @enabled = value
    if not value
      reset_jumpscare
    end
  end
end

#==============================================================================
# ** Spriteset_Map
#==============================================================================

class Spriteset_Map
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  alias initialize_yurish_foxy initialize
  def initialize
    create_foxy
    initialize_yurish_foxy
  end
  #--------------------------------------------------------------------------
  # * Creates Foxy Jumpscare
  #--------------------------------------------------------------------------
  def create_foxy
    @foxy_picture = Sprite_FoxyJumpscare.new(@viewport2)
    puts "Foxy Created"
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  alias update_yurish_foxy update
  def update
    update_foxy
    update_yurish_foxy
  end
  #--------------------------------------------------------------------------
  # * Update Foxy Jumpscare
  #--------------------------------------------------------------------------
  def update_foxy
    @foxy_picture.update
  end
  #--------------------------------------------------------------------------
  # * Dispose
  #--------------------------------------------------------------------------
  alias dispose_yurish_foxy dispose
  def dispose
    dispose_foxy
    dispose_yurish_foxy
  end
  #--------------------------------------------------------------------------
  # * Dispose Foxy Jumpscare
  #--------------------------------------------------------------------------
  def dispose_foxy
    @foxy_picture.dispose
  end
end

#==============================================================================
# ** Game_Interpreter
#==============================================================================

class Game_Interpreter
  #--------------------------------------------------------------------------
  # * Toggle Foxy Jumpscare
  #--------------------------------------------------------------------------
  def toggle_jumpscare(value)
    YuriSH::Const::Foxy.toggle(value)
  end
end