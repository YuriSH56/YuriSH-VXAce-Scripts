# =============================================================================
# ** Doless Music Player
# * By YuriSH
# -----------------------------------------------------------------------------
# * UPDATES HISTORY
# -----------------------------------------------------------------------------
# * Version 1.0 (05.02.2026)
#     Initial release.
# -----------------------------------------------------------------------------
# This script adds music player similar to one in Lisa: The Doless.
# 
# Can be called with a script call:
# SceneManager.call(Scene_DMP)
# =============================================================================

$imported = {} if $imported.nil?
$imported["YuriSH_DMP"] = true

# =============================================================================
# CONFIGURATION BEGIN
# =============================================================================

module YuriSH
  module DMP
    # Allowed audio formats.
    FORMATS = ["mp3", "wav", "ogg", "mid"]
    
    # Mode this script works in
    # :all     - Will show ALL tracks from BGM folder.
    # :include - Will show only tracks from LIST.
    # :exclude - Will show tracks from BGM folder that are not in LIST.
    MODE = :all
    
    # If true - option will be added to title screen.
    ADD_TO_TITLE = true
    
    # Name of the option on title screen.
    TITLE_NAME = "Sound Test"
    
    # Background image to show
    BACKGROUND = "Dark sky"
    
    # Character settings
    # ["character_image", character_index, character_face, animation_rate]
    # "character_image" - Image name from "Characters" folder.
    #                     Extension may be omitted.
    # character_index   - Index of character spriteset (1-8).
    #                     "$" characters should we left at 1.
    # character_face    - Facing direction that will be used.
    #                     Allowed values are 2, 4, 6, 8.
    # animation_rate    - Rate of the animation in frames.
    CHAR = ["$misc4", 1, 2, 15]
    
    # List of music. Extensions may be omitted.
    LIST = [
      "Air Raid"
    ]
    
    # Cache of all BGM names.
    @cache = []
    
    # -------------------------------------------------------------------------
    # * Returns @cache
    # -------------------------------------------------------------------------
    def self.cache
      @cache
    end
    
    # -------------------------------------------------------------------------
    # * Builds Cache
    # -------------------------------------------------------------------------
    def self.build_cache
      Dir.foreach("Audio/BGM") do |music|
        next if music == "."
        next if music == ".."
        spl = music.split(".")
        next if spl.size < 2 or !FORMATS.include?(spl[1].downcase)
        @cache.push(spl[0])
      end
    end
  end
end

# =============================================================================
# CONFIGURATION END
# =============================================================================

#==============================================================================
# ** Window_DMP_Info  
#==============================================================================

class Window_DMP_Info < Window_Base
  # ---------------------------------------------------------------------------
  # * Object Initialization
  # ---------------------------------------------------------------------------
  def initialize
    super(0, 0, Graphics.width, fitting_height(1))
    refresh
  end
  # ---------------------------------------------------------------------------
  # * Refresh Contents
  # ---------------------------------------------------------------------------
  def refresh
    contents.clear
    draw_text(contents.rect, "Select a song to play")
  end
end

#==============================================================================
# ** Window_DMP_Counter  
#==============================================================================

class Window_DMP_Counter < Window_Base
  # ---------------------------------------------------------------------------
  # * Object Initialization
  # --------------------------------------------------------------------------- 
  def initialize
    @idx = 0
    @max = YuriSH::DMP.cache.size
    super(0, 0, fitting_height(1), fitting_height(1))
    create_contents
    refresh
  end
  # ---------------------------------------------------------------------------
  # * Standard Padding
  # ---------------------------------------------------------------------------
  def standard_padding
    0
  end
  # ---------------------------------------------------------------------------
  # * Original Padding
  # ---------------------------------------------------------------------------
  def og_padding
    12
  end
  #--------------------------------------------------------------------------
  # * Calculate Height of Window Suited to Specified Number of Lines
  #--------------------------------------------------------------------------
  def fitting_height(line_number)
    line_number * line_height + og_padding * 2
  end
  # ---------------------------------------------------------------------------
  # * Set Index
  # ---------------------------------------------------------------------------
  def index=(value)
    @idx = value
    refresh
  end
  # ---------------------------------------------------------------------------
  # * Refresh Contents
  # ---------------------------------------------------------------------------
  def refresh
    contents.clear
    r = contents.rect
    r.x += 4
    draw_text(r, "#{@idx+1}.", 1)
  end
end

#==============================================================================
# ** Window_DMP  
#==============================================================================

class Window_DMP < Window_Selectable
  # ---------------------------------------------------------------------------
  # * Object Initialization
  # ---------------------------------------------------------------------------
  def initialize
    @playing = false
    @playing_idx = -1
    @items = get_items
    super(0, 0, 320, fitting_height(1))
    activate
    select(0)
  end
  # ---------------------------------------------------------------------------
  # * Is Currently Playing?
  # ---------------------------------------------------------------------------
  def playing?
    @playing
  end
  # ---------------------------------------------------------------------------
  # * Play/Stop Music
  # ---------------------------------------------------------------------------
  def play
    activate
    if @playing_idx == index and @playing
      RPG::BGM.stop
      @playing = false
      return
    end
    @playing_idx = index
    @playing = true
    RPG::BGM.new(@items[@playing_idx], 50, 100).play
  end
  # ---------------------------------------------------------------------------
  # * Set Counter Window
  # ---------------------------------------------------------------------------
  def counter_window=(value)
    @counter_window = value
  end
  # ---------------------------------------------------------------------------
  # * Get Items List
  # ---------------------------------------------------------------------------
  def get_items
    case YuriSH::DMP::MODE
    when :all
      YuriSH::DMP.cache
    when :include
      YuriSH::DMP::LIST
    when :exclude
      @cache.reject { |x| YuriSH::DMP::LIST.include?(x) }
    end
  end
  # ---------------------------------------------------------------------------
  # * Max Items
  # ---------------------------------------------------------------------------
  def item_max
    1
  end
  # ---------------------------------------------------------------------------
  # * Select Item
  # ---------------------------------------------------------------------------
  def select(index)
    super(index)
    refresh
  end
  #--------------------------------------------------------------------------
  # * Calculate Height of Window Contents
  #--------------------------------------------------------------------------
  def contents_height
    height - standard_padding * 2
  end
  #--------------------------------------------------------------------------
  # * Get Rectangle for Drawing Items
  #--------------------------------------------------------------------------
  def item_rect(index)
    index = 0
    super(index)
  end
  #--------------------------------------------------------------------------
  # * Get Rectangle for Drawing Items (for Text)
  #--------------------------------------------------------------------------
  def item_rect_for_text(index)
    index = 0
    super(index)
  end
  # ---------------------------------------------------------------------------
  # * Process Cursor Movement
  # ---------------------------------------------------------------------------
  def process_cursor_move
    return unless cursor_movable?
    last_index = @index
    cursor_right(Input.trigger?(:RIGHT)) if Input.repeat?(:RIGHT)
    cursor_left (Input.trigger?(:LEFT))  if Input.repeat?(:LEFT)
    Sound.play_cursor if @index != last_index
  end
  #--------------------------------------------------------------------------
  # * Move Cursor Right
  #--------------------------------------------------------------------------
  def cursor_right(wrap = false)
    select((index + 1) % @items.size)
  end
  #--------------------------------------------------------------------------
  # * Move Cursor Left
  #--------------------------------------------------------------------------
  def cursor_left(wrap = false)
    select((index - 1 + @items.size) % @items.size)
  end
  # ---------------------------------------------------------------------------
  # * Draw Item
  # ---------------------------------------------------------------------------
  def draw_item(index)
    draw_text(item_rect(0), @items[index], 1)
  end
  # ---------------------------------------------------------------------------
  # * Refresh Contents
  # ---------------------------------------------------------------------------
  def refresh
    contents.clear
    draw_item(index)
    @counter_window.index = index if @counter_window
  end
end

#==============================================================================
# ** Scene_DMP  
#==============================================================================

class Scene_DMP < Scene_Base
  #--------------------------------------------------------------------------
  # * Start Processing
  #--------------------------------------------------------------------------
  def start
    @timer = 0
    super
    create_background
    create_character
    create_all_windows
    fix_character_position
  end
  #--------------------------------------------------------------------------
  # * Termination Processing
  #--------------------------------------------------------------------------
  def terminate
    super
    dispose_character
    dispose_background
  end
  #--------------------------------------------------------------------------
  # * Create Background
  #--------------------------------------------------------------------------
  def create_background
    img = YuriSH::DMP::BACKGROUND
    return if img.empty?
    @background = Sprite.new
    @background.bitmap = Cache.picture(img)
    center_sprite(@background)
  end
  #--------------------------------------------------------------------------
  # * Create Character
  #--------------------------------------------------------------------------
  def create_character
    n = YuriSH::DMP::CHAR[0]
    return if n.empty?
    @character = Sprite.new
    @character.bitmap = Cache.character(n)
    @character_width = 0
    @character_height = 0
    sign = n[/^[\!\$]./]
    if sign && sign.include?('$')
      @character_width = @character.bitmap.width / 3
      @character_height = @character.bitmap.height / 4
    else
      @character_width = @character.bitmap.width / 12
      @character_height = @character.bitmap.height / 8
    end
    @character.ox = @character_width / 2
    @character.oy = @character_height
    reset_character_bitmap
  end
  #--------------------------------------------------------------------------
  # * Fix Character Position
  #--------------------------------------------------------------------------
  def fix_character_position
    @character.z = 1
    @character.x = @player_window.x + @player_window.width - @player_window.width / 4
    @character.y = @player_window.y
  end
  #--------------------------------------------------------------------------
  # * Reset Character Frame
  #--------------------------------------------------------------------------
  def reset_character_bitmap
    return unless @character
    idx_f = YuriSH::DMP::CHAR[1] - 1
    cidx_x = idx_f % 4
    cidx_y = idx_f / 4
    cx = 1
    cy = YuriSH::DMP::CHAR[2] / 2 - 1
    @character.src_rect = Rect.new(
      @character_width * cx + @character_width * cidx_x,
      @character_height * cy + @character_height * cidx_y,
      @character_width,
      @character_height)
  end
  #--------------------------------------------------------------------------
  # * Update Character Animation
  #--------------------------------------------------------------------------
  def update_character_bitmap
    return unless @character
    return if @timer <= 0
    idx_f = YuriSH::DMP::CHAR[1] - 1
    cidx_x = idx_f % 4
    cidx_y = idx_f / 4
    cx = @timer / YuriSH::DMP::CHAR[3] % 4
    cx = 1 if cx == 3
    cy = YuriSH::DMP::CHAR[2] / 2 - 1
    @character.src_rect = Rect.new(
      @character_width * cx + @character_width * cidx_x,
      @character_height * cy + @character_height * cidx_y,
      @character_width,
      @character_height)
  end
  #--------------------------------------------------------------------------
  # * Dispose Background
  #--------------------------------------------------------------------------
  def dispose_background
    return unless @background
    @background.bitmap.dispose
    @background.dispose
  end
  #--------------------------------------------------------------------------
  # * Dispose Character
  #--------------------------------------------------------------------------
  def dispose_character
    return unless @character
    @character.bitmap.dispose
    @character.dispose
  end
  #--------------------------------------------------------------------------
  # * Center Sprite
  #--------------------------------------------------------------------------
  def center_sprite(sprite)
    sprite.ox = sprite.bitmap.width / 2
    sprite.oy = sprite.bitmap.height / 2
    sprite.x = Graphics.width / 2
    sprite.y = Graphics.height / 2
  end
  #--------------------------------------------------------------------------
  # * Create All Windows
  #-------------------------------------------------------------------------- 
  def create_all_windows
    create_player_window
    create_info_window
    create_counter_window
  end
  #--------------------------------------------------------------------------
  # * Create DMP Info Window
  #--------------------------------------------------------------------------
  def create_info_window
    @info_window = Window_DMP_Info.new
  end
  #--------------------------------------------------------------------------
  # * Create DMP Counter Window
  #--------------------------------------------------------------------------
  def create_counter_window
    @counter_window = Window_DMP_Counter.new
    @counter_window.x = @player_window.x - @counter_window.width / 2
    @counter_window.y = @player_window.y - @player_window.height + 6
    @player_window.counter_window = @counter_window
  end
  #--------------------------------------------------------------------------
  # * Create DMP Player Window
  #--------------------------------------------------------------------------
  def create_player_window
    @player_window = Window_DMP.new
    @player_window.x = Graphics.width / 2 - @player_window.width / 2
    @player_window.y = Graphics.height / 2 - @player_window.height / 2
    @player_window.set_handler(:ok, method(:on_ok))
    @player_window.set_handler(:cancel, method(:on_cancel))
  end
  #--------------------------------------------------------------------------
  # * [OK] Process
  #--------------------------------------------------------------------------
  def on_ok
    Sound.play_ok
    @player_window.play
    reset_character_bitmap unless @player_window.playing?
  end
  #--------------------------------------------------------------------------
  # * [Cancel] Process
  #--------------------------------------------------------------------------
  def on_cancel
    Sound.play_cancel
    return_scene
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  def update
    super
    @player_window.playing? ? @timer += 1 : @timer = 0
    update_character_bitmap
  end
end

if YuriSH::DMP::ADD_TO_TITLE

#==============================================================================
# ** Window_TitleCommand  
#==============================================================================
  
class Window_TitleCommand < Window_Command
  alias make_command_list_yurish_dmp make_command_list
  #--------------------------------------------------------------------------
  # * Create Command List
  #--------------------------------------------------------------------------
  def make_command_list
    make_command_list_yurish_dmp
    cmd = {
      :name=>YuriSH::DMP::TITLE_NAME,
      :symbol=>:sound_test,
      :enabled=>true,
      :ext=>nil}
    @list.insert(@list.length-1, cmd)
  end
end

#==============================================================================
# ** Scene_Title  
#==============================================================================

class Scene_Title < Scene_Base
  alias create_command_window_yurish_dmp create_command_window
  #--------------------------------------------------------------------------
  # * Create Command Window
  #--------------------------------------------------------------------------
  def create_command_window
    create_command_window_yurish_dmp
    @command_window.set_handler(:sound_test, method(:command_sound_test))
  end
  #--------------------------------------------------------------------------
  # * [Sound Test] Command
  #--------------------------------------------------------------------------
  def command_sound_test
    SceneManager.call(Scene_DMP)
  end
end
  
end #if YuriSH::DMP::ADD_TO_TITLE

#==============================================================================
# ** DataManager  
#==============================================================================

module DataManager
  #--------------------------------------------------------------------------
  # * Aliases
  #--------------------------------------------------------------------------
  class << self
    alias init_yurish_dmp init
  end
  #--------------------------------------------------------------------------
  # * Initialization
  #--------------------------------------------------------------------------
  def self.init
    YuriSH::DMP.build_cache
    init_yurish_dmp
  end
end