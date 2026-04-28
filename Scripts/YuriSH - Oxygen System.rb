# =============================================================================
# ** Oxygen System
# * By YuriSH
# -----------------------------------------------------------------------------
# * UPDATES HISTORY
# -----------------------------------------------------------------------------
# * Version 1.0 (04.13.2026)
#     Initial release.
#
# * Version 1.1 (04.21.2026)
#     Fixed oxygen meter not disposing properly between map transitions.
#     Fixed crash caused by disposing window skin bitmap.
#     Player followers now also jump slower underwater.
#     Added events that restore oxygen while you stand on them.
#     Added a way to stop oxygen depletion completely.
#
# * Version 1.1.1 (04.21.2026)
#     Added an option to stop oxygen depletion when player can't move.
#
# * Version 1.2 (04.28.2026)
#     Replaced Sprite_OxygenMeter with Window_OxygenMeter.
#     Now changes colors when oxygen count goes critical.
# -----------------------------------------------------------------------------
# * SCRIPT DESCRIPTION
# -----------------------------------------------------------------------------
# This script implements oxygen system into the game.
# Oxygen goes down when you go underwater and if oxygen runs out - you'll start
# getting damaged. Oxygen restores back when out of water.
# There is a window that appears when oxygen value is changed.
#
# Current maximum oxygen value is determined by party leader's parameters.
# It includes their equips, their states and any tags set for their class or
# actor themself.
#
# Multiplier note tags are applied first to MAX_OXYGEN, additional points
# get added second.
# -----------------------------------------------------------------------------
# * NOTE TAGS
# -----------------------------------------------------------------------------
# MAP'S NOTE TAGS:
# (Used in map's note tags area)
# * <water level: x>
#   Sets up Y-level of water for that map.
#   "x" can be any positive integer (0, 1, 2, etc.)
#   If not set - it defaults to -1 (no water for level).
#   NOTE: This value is used only if MODE is set to :y_level.
#
# * <underwater>
#   Directly sets player's underwater state to true.
#   Can be used if map is fully submerged and there is no surface.
#   If not set - nothing will happen.
#
# ALL ITEM TAGS:
# (Can be used in: Actors, Classes, Armors, Weapons, States)
# * <oxygen add: x>
#   Adds x amount of points to max oxygen value.
#   "x" should be an integer, positive or negative.
#
# * <oxygen mult: x>
#   Multiplies max oxygen by x.
#   "x" should be a positive float.
#
# EQUIP ITEM TAGS:
# (Can be used in: Armors, Weapons)
# * <breathe underwater>
#   Player will not lose oxygen underwater if this item is equipped.
#
# ITEM TAGS:
# (Can be used only in Items)
# * <oxygen restore: x>
#   Using the item will restore x points of oxygen.
#   "x" can be an integer or a percentage value, positive or negative.
#   NOTE: oxygen will be restored even if item is not used on party leader.
#
# EVENT TAGS:
# (Should be placed in a comment ON FIRST EVENT PAGE)
# * <event oxygen restore>
#   Event with this tag will restore oxygen while player stands on it.
# -----------------------------------------------------------------------------
# * NOTE TAG EXAMPLES
# -----------------------------------------------------------------------------
# * <water level: 14>       - Places water level at Y-level 14
# * <oxygen add: 15>        - Max oxygen will be increased by 15
# * <oxygen add: -15>       - Max oxygen will be decreased by 15
# * <oxygen mult: 1.2>      - Max oxygen will be multiplied by 1.2
# * <oxygen mult: 0.85>     - Max oxygen will be multiplied by 0.85
# * <oxygen restore: 20>    - Item will restore 20 oxygen points
# * <oxygen restore: -20>   - Item will remove 20 oxygen points
# * <oxygen restore: 20%>   - Item will restore 20% max oxygen points
# * <oxygen restore: -20%>  - Item will remove 20% max oxygen points
# -----------------------------------------------------------------------------
# * SCRIPT CALLS
# -----------------------------------------------------------------------------
# * $game_player.current_oxygen
#   Returns current amount of oxygen player has.
#
# * $game_player.underwater
#   Returns whether player is underwater or not.
#   If MODE is set to :none, this value can be changed manually.
# * $game_player.underwater = true/false
#
# * $game_player.water_level
#   Returns Y-level of water. Can be set manually at any time.
# * $game_player.water_level = x (same rules apply as for note tag)
#
# * $game_player.oxygen_enabled
#   Returns true if oxygen is enabled.
#   Can be set to false to disable oxygen mechanic.
# * $game_player.oxygen_enabled = true/false
#
# * $game_player.max_oxygen
#   Returns max oxygen with item adjustments.
#
# * $game_player.breathe_underwater
#   Returns true if player has any item equipped that gives underwater breath.
#
# * $game_player.in_bubble_column
#   Returns true if player stands in event that restores oxygen.
# =============================================================================

$imported = {} if $imported.nil?
$imported["YuriSH_OxygenSystem"] = true

# =============================================================================
# CONFIGURATION BEGIN
# =============================================================================

module YuriSH
  module Underwater
    # ====================\/\/ DO NOT CHANGE THIS \/\/==================== #
    # Map regex for water level.
    Y_REGEX = /<water level: ?(\d+)>/i
    
    # Map regex for starting the map in underwater state
    START_REGEX = /<underwater>/i
    
    # Item regex for changing max oxygen
    OXYGEN_REGEX = /<oxygen (add|mult): ?(-?\d(?:\.\d)?)>/i
    
    # Item regex for restoring oxygen upon item use
    OXYGEN_ITEM_REGEX = /<oxygen restore: ?(-?\d+%?)>/i
    
    # Item regex that stops drowning underwater.
    BREATHE_REGEX = /<breathe underwater>/i
    
    # Event regex for restoring oxygen.
    EVENT_REGEX = /<event oxygen restore>/i
    
    # Mask used to display oxygen count if SHOW_MODE is set to :percentage.
    SHOW_MASK = "%s%%"
    
    # Magic number used for slow jump effect
    JUMP_PEAK = 1.4
    
    # Magic number used for slow jump effect
    JUMP_HEIGHT = 2.8
    # ====================/\/\ DO NOT CHANGE THIS /\/\==================== #
    
    # Mode in which script works in.
    # Accepts values :y_level, :region or :none.
    #   :y_level - water will be determined by it's Y-level specified in
    #              the editor with a note tag.
    #   :region  - water will be determined by a list of region IDs.
    #   :none    - disables automatic changes, allowing you to
    #              control underwater changes manually.
    # (DEFAULT: :y_level)
    MODE = :y_level

    # Determines text format of oxygen points shown on the meter.
    # Accepts values :percentage, :number or :none.
    #   :percentage - oxygen points will be shown as a percentage.
    #   :number     - oxygen points will be shown as a raw number.
    #   :none       - oxygen points will not be shown.
    # (DEFAULT: :percentage)
    SHOW_MODE = :percentage
    
    # If set to true - underwater jumps will be slower.
    # Is not affected by REVERSE value.
    # (DEFAULT: true)
    SLOW_JUMP = true
    
    # If true - you will walk slower underwater.
    # (DEFAULT: true)
    SLOW_WALK = true
    
    # If true - air and water will be reversed (breathing underwater).
    # (DEFAULT: false)
    REVERSE = false
    
    # If true - you won't lose oxygen while player is unable to move.
    # (DEFAULT: true)
    STOP_IF_CANT_MOVE = true
    
    # Array of regions that count as water.
    REGIONS = [40,41,42,43]
    
    # Colors used for oxygen gauge, taken from "Window" texture.
    # Final gauge color will be a gradient from left color to right color.
    COLORS = [22, 23]
    
    # Text that shows up above oxygen meter.
    # (DEFAULT: "Oxygen")
    TEXT = "Oxygen"
    
    # Color used for text.
    # (DEFAULT: 0)
    TEXT_COLOR = 0
    
    # Gauge colors when oxygen meter reaches critical point.
    CRITICAL_COLORS = [24,20]
    
    # Rate at which oxygen count becomes critical.
    # (DEFAULT: 0.2 - 20%)
    CRITICAL_RATE = 0.2
    
    # Text color when oxygen count becomes critical.
    CRITICAL_TEXT_COLOR = 2
    
    # Visibility frames for oxygen meter.
    # The window will fade out after this many frames if oxygen value
    # didn't change.
    # (DEFAULT: 120 - 2 seconds)
    COUNTER = 120
    
    # Size of the oxygen meter (width, height) in pixels.
    # (DEFAULT: [78, 32])
    METER_SIZE = [78, 32]
    
    # Font size for meter text.
    # (DEFAULT: 16)
    FONT_SIZE = 16
    
    # Offset of oxygen meter in pixels.
    # Positive numbers mean offset upwards, negative - downwards.
    # (DEFAULT: 50)
    Y_OFFSET = 50
    
    # Max oxygen points used as a baseline.
    # This value can be affected in game using note tags.
    # (DEFAULT: 100)
    MAX_OXYGEN = 100
    
    # Frames window will take to appear or disappear.
    # (DEFAULT: 5)
    HIDE_TIME = 5
    
    # Rate (in frames) at which you lose one point of oxygen.
    # (DEFAULT: 10)
    LOSE_RATE = 10
    
    # Rate (in frames) at which you restore one point of oxygen.
    # (DEFAULT: 3)
    GAIN_RATE = 3
    
    # Rate (in frames) at which you take damage when suffocating.
    # (DEFAULT: 60 - 1 second)
    DAMAGE_RATE = 60
    
    # Amount of damage player gets when drowning.
    # Set to 0 to disable drowning.
    # (DEFAULT: 10)
    DAMAGE = 10
    
    # If true - drowning can KO your party members.
    # If false - party members will stay at 1 HP.
    # (DEFAULT: true)
    DROWN_KILL = true
    
    # ID of an animation that plays upon drowning damage.
    # Set to 0 to disable.
    ANIMATION = 644
  end
end

# =============================================================================
# CONFIGURATION END
# =============================================================================

#==============================================================================
# ** Window_OxygenHeader
#==============================================================================

class Window_OxygenHeader < Window_Base
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize
    m = YuriSH::Underwater::METER_SIZE # Window size
    super(0, 0, m[0], m[1])
    self.opacity = 0
    self.contents.font.size = YuriSH::Underwater::FONT_SIZE
    draw_text(0,0,contents_width,contents_height, YuriSH::Underwater::TEXT, 1)
    deactivate
  end
  #--------------------------------------------------------------------------
  # * Get Line Height
  #--------------------------------------------------------------------------
  def line_height
    return YuriSH::Underwater::FONT_SIZE
  end
  #--------------------------------------------------------------------------
  # * Get Standard Padding Size
  #--------------------------------------------------------------------------
  def standard_padding
    return 0
  end
end

#==============================================================================
# ** Window_OxygenMeter
#==============================================================================

class Window_OxygenMeter < Window_Base
  #--------------------------------------------------------------------------
  # * Class Variables
  #--------------------------------------------------------------------------
  @@_visible = false # Used to restore visibility on scene change
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize
    m = YuriSH::Underwater::METER_SIZE # Window size
    super(0, 0, m[0], m[1])
    deactivate
    @player = $game_player
    @current_oxygen = @player.current_oxygen
    @oxygen_enabled = @player.oxygen_enabled
    @visibility_counter = 0
    @window_openness = 0
    if @@_visible
      @visibility_counter = YuriSH::Underwater::COUNTER
      @window_openness = YuriSH::Underwater::HIDE_TIME
    end
    @header = Window_OxygenHeader.new
    refresh
    update
  end
  #--------------------------------------------------------------------------
  # * Dispose
  #--------------------------------------------------------------------------
  def dispose
    @header.dispose if @header
    super
  end
  #--------------------------------------------------------------------------
  # * Get Line Height
  #--------------------------------------------------------------------------
  def line_height
    return YuriSH::Underwater::FONT_SIZE
  end
  #--------------------------------------------------------------------------
  # * Get Standard Padding Size
  #--------------------------------------------------------------------------
  def standard_padding
    return 8
  end
  #--------------------------------------------------------------------------
  # * Set Visibility (Class Variable)
  #--------------------------------------------------------------------------
  def self.set_class_visible(value)
    @@_visible = value
  end
  #--------------------------------------------------------------------------
  # * Gets Oxygen Rate (0.0 - 1.0)
  #--------------------------------------------------------------------------
  def get_oxygen_rate
    @player.get_oxygen_rate
  end
  #--------------------------------------------------------------------------
  # * Gets Current Oxygen Rate As Text
  #--------------------------------------------------------------------------
  def get_oxygen_text
    case YuriSH::Underwater::SHOW_MODE
    when :percentage
      YuriSH::Underwater::SHOW_MASK % (get_oxygen_rate * 100.0).round.to_s
    when :number
      @player.current_oxygen.to_s
    else
      ""
    end
  end
  #--------------------------------------------------------------------------
  # * Return True If Oxygen Has Changed
  #--------------------------------------------------------------------------
  def oxygen_changed?
    @current_oxygen != @player.current_oxygen
  end
  #--------------------------------------------------------------------------
  # * Return True If Oxygen Enabled State Changed
  #--------------------------------------------------------------------------
  def enable_changed?
    @oxygen_enabled != @player.oxygen_enabled
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  def update
    super
    update_oxygen_enable if enable_changed?
    return unless @oxygen_enabled
    update_counter
    if oxygen_changed?
      refresh
    end
    update_position
    update_opacity
  end
  #--------------------------------------------------------------------------
  # * Refresh
  #--------------------------------------------------------------------------
  def refresh
    update_oxygen_change
    update_bitmap
  end
  #--------------------------------------------------------------------------
  # * Update Oxygen Enable State
  #--------------------------------------------------------------------------
  def update_oxygen_enable
    @oxygen_enabled = @player.oxygen_enabled
    @visibility_counter = 0
    @window_openness = 0
  end
  #--------------------------------------------------------------------------
  # * Update Oxygen Changes
  #--------------------------------------------------------------------------
  def update_oxygen_change
    @current_oxygen = @player.current_oxygen
  end
  #--------------------------------------------------------------------------
  # * Update Counter
  #--------------------------------------------------------------------------
  def update_counter
    # Show/Hide Window Counters
    if @visibility_counter == 0
      @window_openness -= 1 unless @window_openness == 0
    else
      @window_openness += 1 unless @window_openness == YuriSH::Underwater::HIDE_TIME
    end
    
    # Visibility Counter
    if oxygen_changed?
      @visibility_counter = YuriSH::Underwater::COUNTER
    else
      @visibility_counter -= 1 unless @visibility_counter == 0
    end
  end
  #--------------------------------------------------------------------------
  # * Update Transfer Origin Bitmap
  #--------------------------------------------------------------------------
  def update_bitmap
    contents.clear
    return unless @oxygen_enabled
    self.contents.font.size = YuriSH::Underwater::FONT_SIZE
    is_critical = get_oxygen_rate < YuriSH::Underwater::CRITICAL_RATE
    g_c = is_critical ? YuriSH::Underwater::CRITICAL_COLORS : YuriSH::Underwater::COLORS
    t_c = is_critical ? YuriSH::Underwater::CRITICAL_TEXT_COLOR : YuriSH::Underwater::TEXT_COLOR
    draw_gauge(0,0,contents_width, get_oxygen_rate, text_color(g_c[0]), text_color(g_c[1]))
    change_color(text_color(t_c))
    draw_text(0,0, contents_width, contents_height, get_oxygen_text, 1)
  end
  #--------------------------------------------------------------------------
  # * Update Position
  #--------------------------------------------------------------------------
  def update_position
    wfix = self.width / 2
    yfix = self.height
    self.x = @player.screen_x - wfix
    self.y = @player.screen_y - yfix - YuriSH::Underwater::Y_OFFSET
    @header.x = self.x
    @header.y = self.y - YuriSH::Underwater::FONT_SIZE - 2
  end
  #--------------------------------------------------------------------------
  # * Update Opacity
  #--------------------------------------------------------------------------
  def update_opacity
    new_op = 255.0 * (@window_openness.to_f / YuriSH::Underwater::HIDE_TIME.to_f)
    self.opacity = self.contents_opacity = new_op * (@player.opacity / 255.0)
    @header.contents_opacity = self.opacity
    @@_visible = self.opacity == 255
  end
end

#==============================================================================
# ** RPG::BaseItem
#==============================================================================

class RPG::BaseItem
  #--------------------------------------------------------------------------
  # * Gets Oxygen Params From Regex
  #--------------------------------------------------------------------------
  def get_oxygen_params
    res = @note.scan(YuriSH::Underwater::OXYGEN_REGEX)
    res.each do |x|
      case x[0]
      when "mult"
        @oxygen_mult = x[1].to_f.abs
      when "add"
        @oxygen_add = x[1].to_i
      end
    end
    @oxygen_mult = 1.0 if @oxygen_mult.nil?
    @oxygen_add = 0 if @oxygen_add.nil?
  end
  #--------------------------------------------------------------------------
  # * Get Oxygen Multiplier
  #--------------------------------------------------------------------------
  def oxygen_mult
    get_oxygen_params if @oxygen_mult.nil?
    @oxygen_mult
  end
  #--------------------------------------------------------------------------
  # * Get Oxygen Additional Points
  #--------------------------------------------------------------------------
  def oxygen_add
    get_oxygen_params if @oxygen_add.nil?
    @oxygen_add
  end
end

#==============================================================================
# ** RPG::Item
#==============================================================================

class RPG::Item < RPG::UsableItem
  #--------------------------------------------------------------------------
  # * Get Oxygen Points Restored By Item
  #--------------------------------------------------------------------------
  def oxygen_restore
    if @ox_restore.nil?
      @ox_restore = (note =~ YuriSH::Underwater::OXYGEN_ITEM_REGEX ? ox_calc($1) : 0)
    end
    @ox_restore
  end
  #--------------------------------------------------------------------------
  # * Set Oxygen Points Restored By Item
  #--------------------------------------------------------------------------
  def oxygen_restore=(value)
    @ox_restore = ox_calc(value)
  end
  #--------------------------------------------------------------------------
  # * Calculate Oxygen Value From String
  #--------------------------------------------------------------------------
  def ox_calc(value)
    if value.include?("%")
      value.to_f / 100.0
    else
      value.to_i
    end
  end
end

#==============================================================================
# ** RPG::EquipItem
#==============================================================================

class RPG::EquipItem < RPG::BaseItem
  #--------------------------------------------------------------------------
  # * Get If Item Gives Underwater Breath
  #--------------------------------------------------------------------------
  def breathe_underwater
    if @breathe_underwater.nil?
      @breathe_underwater = (note =~ YuriSH::Underwater::BREATHE_REGEX ? true : false)
    end
    @breathe_underwater
  end
  #--------------------------------------------------------------------------
  # * Set If Item Gives Underwater Breath
  #--------------------------------------------------------------------------
  def breathe_underwater=(value)
    @breathe_underwater = value
  end
end

#==============================================================================
# ** DataManager
#==============================================================================

module DataManager
  #--------------------------------------------------------------------------
  # * Aliases
  #--------------------------------------------------------------------------
  class << self
    alias setup_new_game_yurish_undwtr setup_new_game
  end
  #--------------------------------------------------------------------------
  # * Set Up New Game
  #--------------------------------------------------------------------------
  def self.setup_new_game
    Window_OxygenMeter::set_class_visible(false)
    setup_new_game_yurish_undwtr
  end
end

#==============================================================================
# ** Scene_Map
#==============================================================================

class Scene_Map < Scene_Base
  #--------------------------------------------------------------------------
  # * Start Processing
  #--------------------------------------------------------------------------
  alias start_yurish_undwtr start
  def start
    start_yurish_undwtr
    $game_player.refresh_max_oxygen
  end
  #--------------------------------------------------------------------------
  # * Create All Windows
  #--------------------------------------------------------------------------
  alias create_all_windows_yurish_undwtr create_all_windows
  def create_all_windows
    create_all_windows_yurish_undwtr
    create_oxygen_window
  end
  #--------------------------------------------------------------------------
  # * Create Oxygen Meter Window
  #--------------------------------------------------------------------------
  def create_oxygen_window
    @oxygen_window = Window_OxygenMeter.new
  end
end

#==============================================================================
# ** Scene_ItemBase
#==============================================================================

class Scene_ItemBase < Scene_MenuBase
  #--------------------------------------------------------------------------
  # * Use Item
  #--------------------------------------------------------------------------
  alias use_item_yurish_undwtr use_item
  def use_item
    use_item_yurish_undwtr
    check_for_oxygen
  end
  #--------------------------------------------------------------------------
  # * Check For Oxygen Tag In Item
  #--------------------------------------------------------------------------
  def check_for_oxygen
    unless SceneManager.scene_is?(Scene_Map)
      SceneManager.goto(Scene_Map) unless item.oxygen_restore == 0
    end
  end
end

#==============================================================================
# ** Game_Map
#==============================================================================

class Game_Map
  #--------------------------------------------------------------------------
  # * Setup
  #--------------------------------------------------------------------------
  alias setup_yurish_undwtr setup
  def setup(map_id)
    setup_yurish_undwtr(map_id)
    set_player_water_params
  end
  #--------------------------------------------------------------------------
  # * Set Water Parameters For Player
  #--------------------------------------------------------------------------
  def set_player_water_params
    wl = @map.note =~ YuriSH::Underwater::Y_REGEX ? $1.to_i : -1
    su = @map.note =~ YuriSH::Underwater::START_REGEX ? true : false
    $game_player.water_level = wl
    $game_player.underwater = su
    $game_player.followers.each { |x| x.underwater = su }
    p "Water Level: " + wl.to_s
    p "Start Underwater: " + su.to_s
  end
end

#==============================================================================
# ** Game_Actor
#==============================================================================

class Game_Actor < Game_Battler
  #--------------------------------------------------------------------------
  # * Is Party Leader?
  #--------------------------------------------------------------------------
  def is_leader?
    $game_party.leader == self
  end
  #--------------------------------------------------------------------------
  # * Refreshes Max Oxygen If Needed
  #--------------------------------------------------------------------------
  def refresh_oxygen
    $game_player.refresh_max_oxygen if SceneManager.scene_is?(Scene_Map) and is_leader?
  end
  #--------------------------------------------------------------------------
  # * Restores Oxygen Upon Item Use
  #--------------------------------------------------------------------------
  def item_restore_oxygen(item)
    ox_res = item.oxygen_restore
    if ox_res.is_a?(Float)
      $game_player.add_oxygen($game_player.max_oxygen * ox_res)
    else
      $game_player.add_oxygen(ox_res)
    end
  end
  #--------------------------------------------------------------------------
  # * Determine if Skill/Item Has Any Valid Effects
  #--------------------------------------------------------------------------
  def item_has_any_valid_effects?(user, item)
    super(user, item) || item.oxygen_restore != 0
  end
  #--------------------------------------------------------------------------
  # * Change Equipment
  #     slot_id:  Equipment slot ID
  #     item:    Weapon/armor (remove equipment if nil)
  #--------------------------------------------------------------------------
  alias change_equip_yurish_undwtr change_equip
  def change_equip(slot_id, item)
    change_equip_yurish_undwtr(slot_id, item)
    refresh_oxygen
  end
  #--------------------------------------------------------------------------
  # * Discard Equipment
  #     item:  Weapon/armor to discard
  #--------------------------------------------------------------------------
  alias discard_equip_yurish_undwtr discard_equip
  def discard_equip(item)
    discard_equip_yurish_undwtr(item)
    refresh_oxygen
  end
  #--------------------------------------------------------------------------
  # * Add State
  #--------------------------------------------------------------------------
  alias add_state_yurish_undwtr add_state
  def add_state(state_id)
    add_state_yurish_undwtr(state_id)
    if state_addable?(state_id)
      refresh_oxygen
    end
  end
  #--------------------------------------------------------------------------
  # * Remove State
  #--------------------------------------------------------------------------
  alias remove_state_yurish_undwtr remove_state
  def remove_state(state_id)
    remove_state_yurish_undwtr(state_id)
    if state?(state_id)
      refresh_oxygen
    end
  end
  #--------------------------------------------------------------------------
  # * Clear States
  #--------------------------------------------------------------------------
  alias clear_states_yurish_undwtr clear_states
  def clear_states
    clear_states_yurish_undwtr
    refresh_oxygen
  end
  #--------------------------------------------------------------------------
  # * Change Class
  #     keep_exp:  Keep EXP
  #--------------------------------------------------------------------------
  alias change_class_yurish_undwtr change_class
  def change_class(class_id, keep_exp = false)
    change_class_yurish_undwtr(class_id, keep_exp)
    refresh_oxygen
  end
  #--------------------------------------------------------------------------
  # * Consume Items
  #--------------------------------------------------------------------------
  alias consume_item_yurish_undwtr consume_item
  def consume_item(item)
    consume_item_yurish_undwtr(item)
    item_restore_oxygen(item)
  end
end

#==============================================================================
# ** Game_Event
#==============================================================================

class Game_Event < Game_Character
  #--------------------------------------------------------------------------
  # * Get RPG::Event
  #--------------------------------------------------------------------------
  def event
    @event
  end
end

#==============================================================================
# ** Game_Follower
#==============================================================================

class Game_Follower < Game_Character
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_reader :underwater       # Is follower underwater
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  alias initialize_yurish_undwtr initialize
  def initialize(member_index, preceding_character)
    initialize_yurish_undwtr(member_index, preceding_character)
    @underwater = false
    @_underwater = false # debounce value used in jump functions
    @_slowness = false # slows jump down even if REVERSED is true
  end
  #--------------------------------------------------------------------------
  # * Get Move Speed (Account for Dash)
  #--------------------------------------------------------------------------
  def real_move_speed
    return super unless YuriSH::Underwater::SLOW_WALK
    super + (@_slowness ? -1 : 0)
  end
  #--------------------------------------------------------------------------
  # * Sets Variables That Help Jumps Work Correctly
  #--------------------------------------------------------------------------
  def _set_underwater_debounce(value)
    @_slowness = value
    @_underwater = value
  end
  #--------------------------------------------------------------------------
  # * Sets Underwater State
  #--------------------------------------------------------------------------
  def underwater=(value)
    @underwater = value
    _set_underwater_debounce(value)
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  alias update_yurish_undwtr update
  def update
    update_yurish_undwtr
    if $game_player.oxygen_enabled
      update_underwater_state
    end
  end
  #--------------------------------------------------------------------------
  # * Checks If Player Went Underwater
  #--------------------------------------------------------------------------
  def update_underwater_state
    case YuriSH::Underwater::MODE
    when :y_level
      return if $game_player.water_level < 0
      @_slowness = ((@y - $game_player.water_level) >= 0)
      @underwater = YuriSH::Underwater::REVERSE ? !@_slowness : @_slowness
    when :region
      @_slowness = YuriSH::Underwater::REGIONS.include?(region_id)
      @underwater = YuriSH::Underwater::REVERSE ? !@_slowness : @_slowness
    else
      return
    end
  end
# Completely removes this if slow jump is off
# Slow jump block start
if YuriSH::Underwater::SLOW_JUMP
  #--------------------------------------------------------------------------
  # * Jump
  #     x_plus : x-coordinate plus value
  #     y_plus : y-coordinate plus value
  #--------------------------------------------------------------------------
  def jump(x_plus, y_plus)
    @_underwater = @_slowness
    super(x_plus, y_plus)
    if @_underwater
      @jump_peak = (@jump_peak * YuriSH::Underwater::JUMP_PEAK).round
      @jump_count = @jump_peak * 2
    end
  end
  #--------------------------------------------------------------------------
  # * Calculate Jump Height
  #--------------------------------------------------------------------------
  def jump_height
    if @_underwater
      return (super / YuriSH::Underwater::JUMP_HEIGHT).round
    end
    super
  end
end
# Slow jump block end

end

#==============================================================================
# ** Game_Player
#==============================================================================

class Game_Player < Game_Character
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_reader   :current_oxygen     # Current Oxygen
  attr_reader   :max_oxygen         # Max oxygen
  attr_reader   :breathe_underwater # Breathe underwater
  attr_reader   :in_bubble_column   # If player in oxygen-restoring event
  attr_reader   :underwater         # Is player underwater
  attr_accessor :water_level        # Water Y level
  attr_accessor :oxygen_enabled     # Is Oxygen Enabled 
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  alias initialize_yurish_undwtr initialize
  def initialize
    initialize_yurish_undwtr
    @underwater = false
    @_underwater = false # debounce value used in jump functions
    @_slowness = false # slows jump down even if REVERSED is true
    @water_level = -1
    @oxygen_enabled = true
    @breathe_underwater = false
    @in_bubble_column = false
    refresh_max_oxygen
    @current_oxygen = @max_oxygen
    @oxygen_lose_counter = YuriSH::Underwater::LOSE_RATE
    @oxygen_gain_counter = YuriSH::Underwater::GAIN_RATE
    @drown_damage_counter = YuriSH::Underwater::DAMAGE_RATE
  end
  #--------------------------------------------------------------------------
  # * Get Move Speed (Account for Dash)
  #--------------------------------------------------------------------------
  def real_move_speed
    return super unless YuriSH::Underwater::SLOW_WALK
    super + (@_slowness ? -1 : 0)
  end
  #--------------------------------------------------------------------------
  # * Sets Variables That Help Jumps Work Correctly
  #--------------------------------------------------------------------------
  def _set_underwater_debounce(value)
    @_slowness = value
    @_underwater = value
  end
  #--------------------------------------------------------------------------
  # * Sets Underwater State
  #--------------------------------------------------------------------------
  def underwater=(value)
    @underwater = value
    _set_underwater_debounce(value)
    $game_player.followers.each { |x| x.underwater = value }
  end
  #--------------------------------------------------------------------------
  # * Sets Oxygen
  #--------------------------------------------------------------------------
  def set_oxygen(value)
    @current_oxygen = [[value, @max_oxygen].min, 0].max
  end
  #--------------------------------------------------------------------------
  # * Adds Oxygen
  #--------------------------------------------------------------------------
  def add_oxygen(value)
    set_oxygen(@current_oxygen + value)
  end
  #--------------------------------------------------------------------------
  # * Gets Oxygen Rate (0.0 - 1.0)
  #--------------------------------------------------------------------------
  def get_oxygen_rate
    @current_oxygen / @max_oxygen.to_f
  end
  #--------------------------------------------------------------------------
  # * Returns True If Player Should Lose Oxygen
  #--------------------------------------------------------------------------
  def player_lose_oxygen?
    @underwater and !@breathe_underwater and !@in_bubble_column
  end
  #--------------------------------------------------------------------------
  # * Should Player Breathe Underwater?
  #--------------------------------------------------------------------------
  def breathe_underwater?
    return false if $game_party.members.empty?
    $game_party.leader.equips.any? { |x| x and x.breathe_underwater == true }
  end
  #--------------------------------------------------------------------------
  # * Returns True If Player Can Move
  #--------------------------------------------------------------------------
  def player_can_move?
    return ((moving? or movable?) and !$game_map.interpreter.running?)
  end
  #--------------------------------------------------------------------------
  # * Returns Array Of Objects That Have Oxygen Features
  #--------------------------------------------------------------------------
  def oxygen_features
    return [] if $game_party.members.empty?
    $game_party.leader.feature_objects
  end
  #--------------------------------------------------------------------------
  # * Returns Total Multiplier For Max Oxygen Count
  #--------------------------------------------------------------------------
  def max_oxygen_mult
    oxygen_features.inject(1.0) { |r, v| r *= v.oxygen_mult }
  end
  #--------------------------------------------------------------------------
  # * Returns Total Additional Points For Max Oxygen Count
  #--------------------------------------------------------------------------
  def max_oxygen_add
    oxygen_features.inject(0) { |r, v| r += v.oxygen_add }
  end
  #--------------------------------------------------------------------------
  # * Returns Max Oxygen (Adjusted)
  #--------------------------------------------------------------------------
  def calc_max_oxygen
    return (YuriSH::Underwater::MAX_OXYGEN.to_f * max_oxygen_mult + max_oxygen_add).round.to_i
  end
  #--------------------------------------------------------------------------
  # * Refresh Max Oxygen
  #--------------------------------------------------------------------------
  def refresh_max_oxygen
    @max_oxygen = calc_max_oxygen
    @breathe_underwater = breathe_underwater?
    p "BREATHE UNDERWATER? " + @breathe_underwater.to_s
    p "MAX OXYGEN REFRESH"
    p "NEW VALUE: " + @max_oxygen.to_s 
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  alias update_yurish_undwtr update
  def update
    update_yurish_undwtr
    if @oxygen_enabled
      if YuriSH::Underwater::STOP_IF_CANT_MOVE
        return unless player_can_move?
      end
      update_oxygen_counter
      update_underwater_state
      update_drowning_counter
      update_drowning
    end
  end
  #--------------------------------------------------------------------------
  # * Determine if Same Position Event is Triggered
  #--------------------------------------------------------------------------
  alias check_event_trigger_here_yurish_undwtr check_event_trigger_here
  def check_event_trigger_here(triggers)
    @in_bubble_column = check_for_oxygen_event_here
    check_event_trigger_here_yurish_undwtr(triggers)
  end
  #--------------------------------------------------------------------------
  # * Determine if Same Position Event Restores Oxygen
  #--------------------------------------------------------------------------
  def check_for_oxygen_event_here
    $game_map.events_xy(@x, @y).each do |event|
      event.event.pages[0].list.each do |command|
        if command.code == 108 and command.parameters[0] =~ YuriSH::Underwater::EVENT_REGEX
          return true
        end
      end
    end
    return false
  end
  #--------------------------------------------------------------------------
  # * Update Drowning Counter
  #--------------------------------------------------------------------------
  def update_drowning_counter
    if @current_oxygen == 0
      @drown_damage_counter -= 1 unless @drown_damage_counter == 0
    else
      @drown_damage_counter = YuriSH::Underwater::DAMAGE_RATE
    end
  end
  #--------------------------------------------------------------------------
  # * Update Drowning
  #--------------------------------------------------------------------------
  def update_drowning
    return unless player_lose_oxygen?
    return if @drown_damage_counter > 0
    @drown_damage_counter = YuriSH::Underwater::DAMAGE_RATE
    
    dmg_to_deal = YuriSH::Underwater::DAMAGE
    return if dmg_to_deal == 0
    
    drowning_kills = YuriSH::Underwater::DROWN_KILL
    
    unless drowning_kills
      all_at_one_hp = $game_party.members.inject(true) do |r, v|
        r = r && v.hp <= 1
      end
      return if all_at_one_hp
    end
    
    anm_to_play = YuriSH::Underwater::ANIMATION
    @animation_id = anm_to_play if anm_to_play > 0
    
    $game_party.members.each do |member|
      member.change_hp(-dmg_to_deal, drowning_kills)
    end
  end
  #--------------------------------------------------------------------------
  # * Update Oxygen Counter
  #--------------------------------------------------------------------------
  def update_oxygen_counter
    if player_lose_oxygen?
      @oxygen_lose_counter -= 1 unless @oxygen_lose_counter == 0
      return if @current_oxygen == 0
      if @oxygen_lose_counter == 0
        add_oxygen(-1)
        @oxygen_lose_counter = YuriSH::Underwater::LOSE_RATE
      end
    else
      @oxygen_gain_counter -= 1 unless @oxygen_gain_counter == 0
      return if @current_oxygen == @max_oxygen
      if @oxygen_gain_counter == 0
        add_oxygen(+1)
        @oxygen_gain_counter = YuriSH::Underwater::GAIN_RATE
      end
    end
  end
  #--------------------------------------------------------------------------
  # * Checks If Player Went Underwater
  #--------------------------------------------------------------------------
  def update_underwater_state
    case YuriSH::Underwater::MODE
    when :y_level
      return if @water_level < 0
      @_slowness = ((@y - @water_level) >= 0)
      @underwater = YuriSH::Underwater::REVERSE ? !@_slowness : @_slowness
    when :region
      @_slowness = YuriSH::Underwater::REGIONS.include?(region_id)
      @underwater = YuriSH::Underwater::REVERSE ? !@_slowness : @_slowness
    else
      return
    end
  end
  
# Completely removes this if slow jump is off
# Slow jump block start
if YuriSH::Underwater::SLOW_JUMP
  #--------------------------------------------------------------------------
  # * Jump
  #     x_plus : x-coordinate plus value
  #     y_plus : y-coordinate plus value
  #--------------------------------------------------------------------------
  def jump(x_plus, y_plus)
    @_underwater = @_slowness
    super(x_plus, y_plus)
    if @_underwater
      @jump_peak = (@jump_peak * YuriSH::Underwater::JUMP_PEAK).round
      @jump_count = @jump_peak * 2
    end
  end
  #--------------------------------------------------------------------------
  # * Calculate Jump Height
  #--------------------------------------------------------------------------
  def jump_height
    if @_underwater
      return (super / YuriSH::Underwater::JUMP_HEIGHT).round
    end
    super
  end
end
# Slow jump block end

end