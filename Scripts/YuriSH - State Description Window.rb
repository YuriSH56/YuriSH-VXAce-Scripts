# =============================================================================
# ** State Description Window
# * By YuriSH
# -----------------------------------------------------------------------------
# * UPDATES HISTORY
# -----------------------------------------------------------------------------
# * Version 1.0 (04.19.2026)
#     Initial release.
#
# * Version 1.1 (04.19.2026)
#     Compatibility with AAA's DE Status Descriptions script.
#
# * Version 1.1.1 (04.23.2026)
#	  Added :on_apply to MODE.
# -----------------------------------------------------------------------------
# * SCRIPT DESCRIPTION
# -----------------------------------------------------------------------------
# This script adds a window that shows sa list of states and description for
# each listed state.
#
# IMPORTANT:
# If used with AAA's "LISA DE Status Descriptions" script, nota tag from that
# script will be used instead!!!!!!!!!!!!!!
# -----------------------------------------------------------------------------
# * NOTE TAG
# -----------------------------------------------------------------------------
# To specify a description for a state, use following note tag format:
#
# <desc>
# TEXT
# </desc>
#
# Where "TEXT" - ANY text. The only limit is that text must be 2 lines at most.
# Description text supports control characters for colors, icons, etc.
# Refer to "Show Text" event command for list of those control characters.
#
# If used with AAA's "LISA DE Status Descriptions", use
# following note tag instead:
# <Desc: TEXT>
# -----------------------------------------------------------------------------
# * SCRIPT CALLS
# -----------------------------------------------------------------------------
# To call the state window:
# * SceneManager.call(Scene_StateList)
#
# To unlock states:
# * $game_player.unlock_states(s1, s2, s3, ...)
# (s1, s2, s3 - IDs of states to unlock. Can be as many states as you like)
#
# To lock states:
# * $game_player.lock_states(s1, s2, s3, ...)
# (s1, s2, s3 - IDs of states to lock. Can be as many states as you like)
#
# To unlock ALL states:
# * $game_player.unlock_all_states
#
# To lock ALL states:
# * $game_player.lock_all_states
# =============================================================================

$imported = {} if $imported.nil?
$imported["YuriSH_StateDescWindow"] = true

# =============================================================================
# CONFIGURATION BEGIN
# =============================================================================

module YuriSH
  module StateDesc
    # ==========\/\/ DO NOT CHANGE THIS \/\/========== #
    # Regex for state description.
    REGEX = /<desc>(.*?)<\/desc>/im
    # ==========/\/\ DO NOT CHANGE THIS /\/\========== #
    
    # Decides which states will appear in the list.
    # :all        - ALL states will appear (if state has a non-empty name).
    # :desc       - all states with description set will appear.
    # :on_unlock  - only unlocked states will appear.
    # :on_apply   - only states that were applied at least once will appear.
    MODE = :all
    
    # Number of columns in the window.
    # (DEFAULT: 2)
    COLUMNS = 2
    
    # Number of rows in the window.
    # (DEFAULT: 8)
    ROWS = 8
    
    # Height of each item in the list.
    # (DEFAULT: 24)
    HEIGHT = 24
    
    # Left/right padding of the window.
    # (DEFAULT: 50)
    WIDTH_DECR = 50
    
    #------------------------------------------------------------------------
    # * Get Data Of States To Show
    #------------------------------------------------------------------------
    def self.all_states_data
      case MODE
      when :all
        @all_states = $data_states.select { |x| x && !x.name.empty? }
      when :desc
        @all_states = $data_states.select { |x| x && !x.description.empty? }
      when :on_unlock, :on_apply
        @all_states = $data_states.select { |x| x && $game_player.unlocked_states.include?(x.id) }
      else
        @all_states = []
      end
      @all_states
    end
    
    #------------------------------------------------------------------------
    # * Get IDs Of States To Show
    #------------------------------------------------------------------------
    def self.all_states_id
      all_states_data.collect { |x| x.id}
    end
  end
end

# =============================================================================
# CONFIGURATION END
# =============================================================================

#==============================================================================
# ** Scene_StateList
#==============================================================================

class Scene_StateList < Scene_Base
  #--------------------------------------------------------------------------
  # * Start Processing
  #--------------------------------------------------------------------------
  def start
    super
    create_background
    create_windows
  end
  #--------------------------------------------------------------------------
  # * Termination Processing
  #--------------------------------------------------------------------------
  def terminate
    super
    dispose_background
  end
  #--------------------------------------------------------------------------
  # * Create All Windows
  #--------------------------------------------------------------------------
  def create_windows
    create_help_window
    create_state_list_window
  end
  #--------------------------------------------------------------------------
  # * Create Help Window
  #--------------------------------------------------------------------------
  def create_help_window
    @help_window = Window_Help.new
    @help_window.viewport = @viewport
  end
  #--------------------------------------------------------------------------
  # * Create State List Window
  #--------------------------------------------------------------------------
  def create_state_list_window
    @state_list_window = Window_StateList.new(0, @help_window.height)
    @state_list_window.viewport = @viewport
    @state_list_window.help_window = @help_window
    @state_list_window.set_handler(:cancel, method(:on_cancel))
  end
  #--------------------------------------------------------------------------
  # * Create background
  #--------------------------------------------------------------------------
  def create_background
    @background_sprite = Sprite.new
    @background_sprite.bitmap = SceneManager.background_bitmap
    @background_sprite.color.set(0, 0, 0, 128)
  end
  #--------------------------------------------------------------------------
  # * Dispose background
  #--------------------------------------------------------------------------
  def dispose_background
    @background_sprite.bitmap.dispose
    @background_sprite.dispose
  end
  #--------------------------------------------------------------------------
  # * On Window Cancel
  #--------------------------------------------------------------------------
  def on_cancel
    return_scene
  end
end  

#==============================================================================
# ** Window_StateList
#==============================================================================

class Window_StateList < Window_Selectable
  #--------------------------------------------------------------------------
  # * Object Initialization
  #-------------------------------------------------------------------------
  def initialize(x, y)
    @items = YuriSH::StateDesc.all_states_data
    decr = YuriSH::StateDesc::WIDTH_DECR
    r = YuriSH::StateDesc::ROWS
    super(x + decr, y, Graphics.width-decr * 2, fitting_height(r))
    refresh
    activate
    select(0)
  end
  #--------------------------------------------------------------------------
  # * Get Line Height
  #--------------------------------------------------------------------------
  def line_height
    return YuriSH::StateDesc::HEIGHT #24
  end
  #--------------------------------------------------------------------------
  # * Get Digit Count
  #--------------------------------------------------------------------------
  def col_max
    return YuriSH::StateDesc::COLUMNS
  end
  #--------------------------------------------------------------------------
  # * Get Number of Items
  #--------------------------------------------------------------------------
  def item_max
    return @items.length
  end
  #--------------------------------------------------------------------------
  # * Current Item
  #--------------------------------------------------------------------------
  def item
    (@items.length > 0 && index >= 0) ? @items[index] : nil
  end
  #--------------------------------------------------------------------------
  # * Update Help Text
  #--------------------------------------------------------------------------
  def update_help
    @help_window.set_item(item)
  end
  #--------------------------------------------------------------------------
  # * Draw Item
  #--------------------------------------------------------------------------
  def draw_item(index)
    data = @items[index]
    rect = item_rect_for_text(index)
    draw_icon(data.icon_index, rect.x, rect.y + rect.height / 2 - 12)
    rect.x += 32
    rect.width -= 32
    draw_text(rect, data.name, 0)
  end
end

#==============================================================================
# ** RPG::State
#==============================================================================

class RPG::State < RPG::BaseItem
  #--------------------------------------------------------------------------
  # * Get Description
  #--------------------------------------------------------------------------
  def description
    if @_no_desc.nil?
      if defined?(status_note_description)
        desc = status_note_description
        @description = desc.nil? ? "" : desc
      else
        @description = (@note =~ YuriSH::StateDesc::REGEX ? $1.strip! : "" )
      end
      @_no_desc = @description.empty? ? true : false
    end
    @description
  end
end

#==============================================================================
# ** Game_Battler
#==============================================================================

class Game_Battler < Game_BattlerBase
  #--------------------------------------------------------------------------
  # * Add New State
  #--------------------------------------------------------------------------
  alias add_new_state_yurish_sttdsc add_new_state
  def add_new_state(state_id)
    $game_player.unlock_states(state_id) if YuriSH::StateDesc::MODE == :on_apply
    add_new_state_yurish_sttdsc(state_id)
  end
end

#==============================================================================
# ** Game_Player
#==============================================================================

class Game_Player < Game_Character
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_reader   :unlocked_states      # List of unlocked states
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  alias initialize_yurish_sttdsc initialize
  def initialize
    initialize_yurish_sttdsc
    @unlocked_states = []
  end
  #--------------------------------------------------------------------------
  # * Lock States
  #--------------------------------------------------------------------------
  def lock_states(*args)
    @unlocked_states.delete_if { |x| args.include?(x) }
  end
  #--------------------------------------------------------------------------
  # * Unlock States
  #--------------------------------------------------------------------------
  def unlock_states(*args)
    @unlocked_states.concat(args)
    @unlocked_states.uniq!
  end
  #--------------------------------------------------------------------------
  # * Unlock All States
  #--------------------------------------------------------------------------
  def unlock_all_states
    @unlocked_states = YuriSH::StateDesc.all_states_id
  end
  #--------------------------------------------------------------------------
  # * Lock All States
  #--------------------------------------------------------------------------
  def lock_all_states
    @unlocked_states = []
  end
end