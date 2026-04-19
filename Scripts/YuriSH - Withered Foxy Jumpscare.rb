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
# * Version 1.2 (04.06.2026)
#	  Can now be triggered manually.
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
    # Delay completely prevents jumpscares from appearing
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
    # Set Alpha to 0 to disable screen flash
    FLASH_COLOR = Color.new(255,0,0,255)
    # Screen flash duration (in frames)
    # Default is 120 frames (2 seconds)
    FLASH_DURATION = 60
    
    # Jumpscare spritesheet image name
    # Must be placed in "Pictures" folder
    IMAGE = "foxy"
    #Individual cell size (x, y)
    CELL_SIZE = {:x => 1024, :y => 768}
    # Number of cells in the spritesheet (x, y)
    CELLS = {:x => 2, :y => 7}
    # Time between cells (in frames)
    # Default is 2 frames (1/30 of a second)
    SPEED = 2
    # Image scale
    SCALE = 0.65
    
    # If true - jumpscare will process
    # If false - jumpscare will be disabled
    @enabled = true
    # Set to true to IMMEDIATELY summon a jumpscare
    # Will work even if jumpscare is disabled
    @trigger_immediately = false
  
    #----------------------------------------------------------------------
    # * Toggles Jumpscare Processing
    #----------------------------------------------------------------------
    def self.toggle(value)
      @enabled = value
    end
    #----------------------------------------------------------------------
    # * Immediately Triggers The Jumpscare
    #----------------------------------------------------------------------
    def self.trigger(value = true)
      @trigger_immediately = value
    end
    #----------------------------------------------------------------------
    # * Was Jumpscare Triggered?
    #----------------------------------------------------------------------
    def self.triggered?
      return @trigger_immediately
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
        :z_index        => YuriSH::Foxy::Z_INDEX,
        :chance         => YuriSH::Foxy::CHANCE,
        :delay          => YuriSH::Foxy::DELAY,
        :sound_name     => YuriSH::Foxy::SOUND_NAME,
        :sound_volume   => YuriSH::Foxy::SOUND_VOLUME,
        :sound_pitch    => YuriSH::Foxy::SOUND_PITCH,
        :flash_color    => YuriSH::Foxy::FLASH_COLOR,
        :flash_duration => YuriSH::Foxy::FLASH_DURATION,
        :image          => YuriSH::Foxy::IMAGE,
        :cell_size      => YuriSH::Foxy::CELL_SIZE,
        :cells          => YuriSH::Foxy::CELLS,
        :speed          => YuriSH::Foxy::SPEED,
        :scale          => YuriSH::Foxy::SCALE,
      }
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
    @enabled = YuriSH::Foxy.enabled?
	@immediate_processing = false
    get_hash_of_data
    cache_image
    update
  end
  #--------------------------------------------------------------------------
  # * Assigns Hash Of Data
  # (Because Constant Names Are So Damn Long)
  #--------------------------------------------------------------------------
  def get_hash_of_data
    @data = YuriSH::Foxy.get_hash
  end
  #--------------------------------------------------------------------------
  # * Cache Image To Prevent Lag
  #--------------------------------------------------------------------------
  def cache_image
    Cache.picture(@data[:image])
  end
  #--------------------------------------------------------------------------
  # * Checks If Jumpscare Was Triggered By Hand
  #--------------------------------------------------------------------------
  def check_for_immediate_trigger
	if YuriSH::Foxy.triggered?
	  YuriSH::Foxy.trigger(false)
	  @immediate_processing = true
	  init_jumpscare
	end
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
	check_for_immediate_trigger
    return unless (@enabled or @immediate_processing)
    roll_chance
    update_bitmap
    update_other
    update_jumpscare
  end
  #--------------------------------------------------------------------------
  # * Checks If Enabled State Changes
  #--------------------------------------------------------------------------
  def update_enabled
    new_val = YuriSH::Foxy.enabled?
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
		@immediate_processing = false
		if @data[:flash_color].alpha > 0
		  $game_map.screen.start_flash(@data[:flash_color], @data[:flash_duration])
		end
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
	@immediate_processing = false
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
    YuriSH::Foxy.toggle(value)
  end
  #--------------------------------------------------------------------------
  # * Immediately Trigger The Jumpscare
  #--------------------------------------------------------------------------
  def trigger_jumpscare
	YuriSH::Foxy.trigger
  end
end