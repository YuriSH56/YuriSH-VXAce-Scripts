# =============================================================================
# ** Global Hit Bar
# * By YuriSH
# -----------------------------------------------------------------------------
# * UPDATES HISTORY
# -----------------------------------------------------------------------------
# * Version 1.0 (04.11.2026)
#     Initial release.
# -----------------------------------------------------------------------------
# * SCRIPT DESCRIPTION
# -----------------------------------------------------------------------------
# This script adds a global hit point bar (GB Bar) for player party and
# enemy troops.
# GB Bar is increased by either getting damaged by enemy or hitting an enemy.
# Only HP damage/recover counts for BG Bar increase.
#
# Enemy troop's GB Bar is set to 0 at the start of the fight.
# You can change their GB Bar value with one of the script calls
# listed in "SCRIPT CALLS" section.
# -----------------------------------------------------------------------------
# * NOTE TAGS
# -----------------------------------------------------------------------------
# There are several note tags that can be used to control how GB Bar works:
# * <gb rate: x>    - Sets up a multiplier for resulting GB Bar value you get
#                     from dealing damage.
#                     Can be specified for: Actors, Classes, Skills,
#                     Enemies, States, Items, Armors, Weapons.
#                     "x" should be a floating point number (e.g. 1.2, 0.85).
#                     If tag is not specified, rate is 1.0 by default.
#
# * <gb cost: x>    - Sets up a GB Bar cost for an item.
#                     Can be specified for: Skills.
#                     "x" can be either specific number of points (e.g. 50),
#                     or a percentage from max GB Bar value (e.g. 25%).
#
# * <gb formula: trg, x> - Sets up a formula used from USER_FORMULAS list.
#                     Can be specified for: Skills, Items.
#                     "x" should be a whole number (1, 2, 3, etc.)
#                     "trg" is either "user", "target" or "ally".
#                     That number MUST exist in USER_FORMULAS list.
#                     If tag is not specified, one of the default formulas
#                     will be used for skills (see config section).
#                     NOTE: Items have no formula by default.
# -----------------------------------------------------------------------------
# * FORMULA FORMAT
# -----------------------------------------------------------------------------
# Formulas use similar format to Skill and Item formulas.
# Those allow following symbols to be used:
# -----------------------------------------------------------------------------
# "x" is the resulting damage value.
# If x is greater than 0 - HP damage was recieved
# If x is less than 0 - HP recovery was recieved (healing or drain)
# If x is 0 - HP was not affected
# "a" is user (Game_Actor or Game_Enemy).
# "b" is target (Game_Actor or Game_Enemy).
# "v[n]" is a variable (n here is variable's number).
# HINT: You can use "a.get_unit" or "b.get_unit" to get unit object of a user
# or a target ($game_player or $game_troop).
# -----------------------------------------------------------------------------
# * NOTE TAG EXAMPLES
# -----------------------------------------------------------------------------
# <gb rate: 1.2>
# <gb rate: 0.85>
#
# <gb cost: 25>
# <gb cost: 100%>
#
# <gb formula: user, 1>
# <gb formula: target, 2>
# <gb formula: ally, 5>
# -----------------------------------------------------------------------------
# * SCRIPT CALLS
# -----------------------------------------------------------------------------
# GB Bar values are stored in $game_party and $game_troop objects.
# All following methods work for both of them.
#
# * $game_party.gb_value - returns current GB Bar value of your party.
# * $game_party.add_gb_value(value) - adds points to the GB Bar.
# * $game_party.set_gb_value(value) - sets specific value of GB Bar.
# (value must be a whole number, e.g. 50).
# =============================================================================

$imported = {} if $imported.nil?
$imported["YuriSH_GlobalHitBar"] = true

# =============================================================================
# CONFIGURATION BEGIN
# =============================================================================

module YuriSH
  module GlobalBar
    # ===============\/\/ DO NOT CHANGE THIS \/\/=============== #
    RATE_REGEX    = /<gb rate: ?(\d+\.\d+)>/i
    COST_REGEX    = /<gb cost: ?(\d+%?)>/i
    FORMULA_REGEX = /<gb formula: ?(user|target|ally), ?(\d+)>/i
    # ===============/\/\ DO NOT CHANGE THIS /\/\=============== #
    
    NAME          = "EP"    # Global bar name
    COLOR         = 11      # Global bar name color (also cost text color)
    GAUGE_COLORS  = [3, 11] # Colors for global bar (top to bottom gradient)
    GB_MAX        = 100     # Max value for global bar
    GB_MASK       = "%s%%"  # Mask used to show global bar value
    WINDOW_POS    = :right  # Position of the window. Can be :left or :right
    WINDOW_TIME   = 120     # Number of frames global bar window will
                            # appear for when it's value is changed
                            # (default is 120 - 2 seconds)
    ALLY_DAMAGE   = true    # If true - hitting allies (or self) will also
                            # increase global bar value
    # -----------------------------------------------------------------------
    # Default formula used to calculate how many points damage dealer gets.
    # (skill or item user)
    # -----------------------------------------------------------------------
    USER_FORMULA    = "[[(x / 100.0).ceil, 1].max, 10].min"
    # -----------------------------------------------------------------------
    # Default formula used to calculate how many points damage reciever gets.
    # (skill or item target)
    # -----------------------------------------------------------------------
    TARGET_FORMULA  = "[[((x / 100.0) ** 2.0).ceil, 1].max, 20].min"
    # -----------------------------------------------------------------------
    # Default formula used to calculate points for hitting allies or self.
    # Uses TARGET_FORMULA by default.
    # -----------------------------------------------------------------------
    ALLY_FORMULA  = TARGET_FORMULA
    # -----------------------------------------------------------------------
    # List of formulas you can use in skills.
    # Format: ID => "<formula>", where:
    #   ID - an integer (1, 2, 3, etc.)
    #   <formula> - formula.
    # HINT: Use ''' <formula> ''' for multi-line editing.
    # NOTE: commas at the end of each item are REQUIRED.
    # -----------------------------------------------------------------------
    USER_FORMULAS = {
      1 => '''
        if x > 0
          x / 100.0
        else
          0
        end
        ''', # multi-line example
      2 => "x / 100 + a.atk - b.def", # one line
      3 => "50", # constant expression
    }
  end
end

# =============================================================================
# CONFIGURATION END
# =============================================================================

#==============================================================================
# ** Window_GlobalBar
#==============================================================================

class Window_GlobalBar < Window_Base
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_accessor :counter
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize(x, y)
    @gb_rate = $game_party.gb_rate
    @counter = 0
    super(x, y, window_width, fitting_height(visible_line_number))
    self.openness = 0
    deactivate
  end
  #--------------------------------------------------------------------------
  # * Get Window Width
  #--------------------------------------------------------------------------
  def window_width
    return 64
  end
  #--------------------------------------------------------------------------
  # * Get Number of Lines to Show
  #--------------------------------------------------------------------------
  def visible_line_number
    return 4
  end
  #--------------------------------------------------------------------------
  # * Get Rate Value As Formatted String
  #--------------------------------------------------------------------------
  def format_rate_string
    return YuriSH::GlobalBar::GB_MASK % (@gb_rate * 100).round.to_s
  end
  #--------------------------------------------------------------------------
  # * Draw Vertical Gauge
  #     rate   : Rate (full at 1.0)
  #     color1 : Left side gradation
  #     color2 : Right side gradation
  #--------------------------------------------------------------------------
  def draw_gauge_vertical(x, y, width, height, rate, color1, color2)
    if $imported["YEA-CoreEngine"]
      if YEA::CORE::GAUGE_OUTLINE
        outline_colour = gauge_back_color
        outline_colour.alpha = translucent_alpha
        contents.fill_rect(x, y, width, height, outline_colour)
        x += 1
        y += 1
      end
      if YEA::CORE::GAUGE_OUTLINE
        height -= 2 
        width -= 2
      end
    end
    fill_h = [(height * rate).to_i, height].min
    contents.fill_rect(x, y, width, height, gauge_back_color)
    contents.gradient_fill_rect(x, y+(height-fill_h), width, fill_h, color1, color2, true)
  end
  #--------------------------------------------------------------------------
  # * Create Contents
  #--------------------------------------------------------------------------
  def create_contents
    super
    change_color(text_color(YuriSH::GlobalBar::COLOR))
    draw_text(4, 0, contents_width - 8, line_height,
      YuriSH::GlobalBar::NAME, 1)
    
    draw_gauge_vertical(contents_width / 2.0 - 16, line_height, 32, line_height * 3, @gb_rate,
      text_color(YuriSH::GlobalBar::GAUGE_COLORS[0]),
      text_color(YuriSH::GlobalBar::GAUGE_COLORS[1]))
      
    change_color(normal_color)
    draw_text(4, line_height * 2,
      contents_width - 8, line_height, format_rate_string, 1)
  end
  #--------------------------------------------------------------------------
  # * Check If Global Bar Rate Changed
  #--------------------------------------------------------------------------
  def check_gb_rate
    if $game_party.gb_rate != @gb_rate
      @gb_rate = $game_party.gb_rate
      @counter = YuriSH::GlobalBar::WINDOW_TIME
      refresh
    end
  end
  #--------------------------------------------------------------------------
  # * Processes Counter
  #--------------------------------------------------------------------------
  def process_counter
    return unless BattleManager.in_turn?
    return if @counter <= 0
    if @counter > 0
      show_window unless self.active
    end
    @counter -= 1
    if @counter == 0
      hide_window if self.active
    end
  end
  #--------------------------------------------------------------------------
  # * Refresh
  #--------------------------------------------------------------------------
  def refresh
    contents.clear
    create_contents
  end
  #--------------------------------------------------------------------------
  # * Show Window
  #--------------------------------------------------------------------------
  def show_window
    return if self.active
    refresh
    activate
    open
  end
  #--------------------------------------------------------------------------
  # * Hide Window
  #--------------------------------------------------------------------------
  def hide_window
    return unless self.active
    deactivate
    close
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  def update
    super
    check_gb_rate
    process_counter
  end
end

#==============================================================================
# ** RPG::BaseItem
#==============================================================================

class RPG::BaseItem
  # ---------------------------------------------------------------------------
  # * Get Global Bar Rate
  # ---------------------------------------------------------------------------
  def gb_rate
    if @gb_rate.nil?
      @gb_rate = (@note =~ YuriSH::GlobalBar::RATE_REGEX ? $1.to_f : 1.0)
    end
    @gb_rate
  end
  # ---------------------------------------------------------------------------
  # * Set Global Bar Rate
  # ---------------------------------------------------------------------------
  def gb_rate=(value)
    @gb_rate = value.to_f
  end
end

#==============================================================================
# ** RPG::UsableItem
#==============================================================================

class RPG::UsableItem < RPG::BaseItem
  # ---------------------------------------------------------------------------
  # * Get Formulas From Note Tags
  # ---------------------------------------------------------------------------
  def get_formulas_from_notetags
    res = @note.scan(YuriSH::GlobalBar::FORMULA_REGEX)
    res.each do |x|
      case x[0]
      when "user"
        @gb_user_formula = YuriSH::GlobalBar::USER_FORMULAS[x[1].to_i]
      when "target"
        @gb_target_formula = YuriSH::GlobalBar::USER_FORMULAS[x[1].to_i]
      when "ally"
        @gb_ally_formula = YuriSH::GlobalBar::USER_FORMULAS[x[1].to_i]
      end
    end
    if self.is_a?(RPG::Item)
      @gb_user_formula    = "" if @gb_user_formula.nil?
      @gb_target_formula  = "" if @gb_target_formula.nil?
      @gb_ally_formula    = "" if @gb_ally_formula.nil?
    else
      @gb_user_formula    = YuriSH::GlobalBar::USER_FORMULA if @gb_user_formula.nil?
      @gb_target_formula  = YuriSH::GlobalBar::TARGET_FORMULA if @gb_target_formula.nil?
      @gb_ally_formula    = YuriSH::GlobalBar::ALLY_FORMULA if @gb_ally_formula.nil?
    end
  end
  # ---------------------------------------------------------------------------
  # * Get Global Bar User Formula
  # ---------------------------------------------------------------------------
  def gb_user_formula
    get_formulas_from_notetags if @gb_user_formula.nil?
    @gb_user_formula
  end
  # ---------------------------------------------------------------------------
  # * Set Global Bar User Formula
  # ---------------------------------------------------------------------------
  def gb_user_formula=(value)
    @gb_user_formula = value
  end
  # ---------------------------------------------------------------------------
  # * Get Global Bar Target Formula
  # ---------------------------------------------------------------------------
  def gb_target_formula
    get_formulas_from_notetags if @gb_target_formula.nil?
    @gb_target_formula
  end
  # ---------------------------------------------------------------------------
  # * Set Global Bar Target Formula
  # ---------------------------------------------------------------------------
  def gb_target_formula=(value)
    @gb_target_formula = value
  end
  # ---------------------------------------------------------------------------
  # * Get Global Bar Ally Formula
  # ---------------------------------------------------------------------------
  def gb_ally_formula
    get_formulas_from_notetags if @gb_ally_formula.nil?
    @gb_ally_formula
  end
  # ---------------------------------------------------------------------------
  # * Set Global Bar Ally Formula
  # ---------------------------------------------------------------------------
  def gb_ally_formula=(value)
    @gb_ally_formula = value
  end
end

#==============================================================================
# ** RPG::Skill
#==============================================================================

class RPG::Skill < RPG::UsableItem
  # ---------------------------------------------------------------------------
  # * Extracts Global Bar Cost From String
  # ---------------------------------------------------------------------------
  def extract_gb_cost(str_value)
    if str_value.include?("%")
      @percent_value = str_value.to_i
      return ((str_value.to_f / 100.0) * YuriSH::GlobalBar::GB_MAX).to_i
    else
      @percent_value = 0
      return str_value.to_i
    end
  end
  # ---------------------------------------------------------------------------
  # * Get Global Bar Cost
  # ---------------------------------------------------------------------------
  def gb_cost
    if @gb_cost.nil?
      @gb_cost = (@note =~ YuriSH::GlobalBar::COST_REGEX ? extract_gb_cost($1) : 0)
    end
    @gb_cost
  end
  # ---------------------------------------------------------------------------
  # * Set Global Bar Cost
  # ---------------------------------------------------------------------------
  def gb_cost=(value)
    @gb_cost = value
  end
  # ---------------------------------------------------------------------------
  # * Returns Skill Cost In Percentages
  # ---------------------------------------------------------------------------
  def percent_value
    if @percent_value.nil?
      @percent_value = 0
    end
    @percent_value
  end
  # ---------------------------------------------------------------------------
  # * Set Skill Cost In Percentages
  # ---------------------------------------------------------------------------
  def percent_value=(value)
    @percent_value = value
  end
end

#==============================================================================
# ** Game_Unit
#==============================================================================

class Game_Unit
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_reader :gb_value                 # Global bar value
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  alias initialize_yurish_1y9lv initialize
  def initialize
    initialize_yurish_1y9lv
    @gb_value = 0
  end
  #--------------------------------------------------------------------------
  # * Set Global Bar Value
  #--------------------------------------------------------------------------
  def set_gb_value(value)
    @gb_value = [[value, YuriSH::GlobalBar::GB_MAX].min, 0].max
  end
  #--------------------------------------------------------------------------
  # * Add Global Bar Value
  #--------------------------------------------------------------------------
  def add_gb_value(value)
    set_gb_value(@gb_value + value)
  end
  #--------------------------------------------------------------------------
  # * Get Global Bar Fill Rate
  #--------------------------------------------------------------------------
  def gb_rate
    return (@gb_value.to_f / YuriSH::GlobalBar::GB_MAX.to_f)
  end
end

#==============================================================================
# ** Game_Troop
#==============================================================================

class Game_Troop < Game_Unit
  #--------------------------------------------------------------------------
  # * Clear
  #--------------------------------------------------------------------------
  alias clear_yurish_1y9lv clear
  def clear
    clear_yurish_1y9lv
    set_gb_value(0)
  end
end

#==============================================================================
# ** Game_BatterBase
#==============================================================================

class Game_BattlerBase
  #--------------------------------------------------------------------------
  # * Get Corrent Unit Object
  #--------------------------------------------------------------------------
  def get_unit(battler = self)
    if battler.is_a?(Game_Actor)
      return $game_party
    elsif battler.is_a?(Game_Enemy)
      return $game_troop
    else
      return nil
    end
  end
  #--------------------------------------------------------------------------
  # * Calculate Skill's Global Bar Cost
  #--------------------------------------------------------------------------
  def skill_gb_cost(skill)
    skill.gb_cost
  end
  #--------------------------------------------------------------------------
  # * Determine if Cost of Using Skill Can Be Paid
  #--------------------------------------------------------------------------
  alias skill_cost_payable_yurish_1y9lv? skill_cost_payable?
  def skill_cost_payable?(skill)
    skill_cost_payable_yurish_1y9lv?(skill) && get_unit.gb_value >= skill_gb_cost(skill)
  end
  #--------------------------------------------------------------------------
  # * Pay Cost of Using Skill
  #--------------------------------------------------------------------------
  alias pay_skill_cost_yurish_1y9lv pay_skill_cost
  def pay_skill_cost(skill)
    pay_skill_cost_yurish_1y9lv(skill)
    get_unit.add_gb_value(-skill_gb_cost(skill))
  end
end

#==============================================================================
# ** Game_Battler
#==============================================================================

class Game_Battler < Game_BattlerBase
  #--------------------------------------------------------------------------
  # * Calculate Damage
  #--------------------------------------------------------------------------
  alias make_damage_value_yurish_1y9lv make_damage_value
  def make_damage_value(user, item)
    make_damage_value_yurish_1y9lv(user, item)
    if self.class == user.class
      if YuriSH::GlobalBar::ALLY_DAMAGE
        calculate_gb_for_ally(@result.hp_damage, user, self, $game_variables, item)
      end
      return
    end
    calculate_gb_for_target(@result.hp_damage, user, self, $game_variables, item)
    calculate_gb_for_user(@result.hp_damage, user, self, $game_variables, item)
  end
  #--------------------------------------------------------------------------
  # * Returns Total Global Bar Rate
  #--------------------------------------------------------------------------
  def get_gb_rate
    feature_objects.inject(1.0) { |r, v| r *= v.gb_rate }
  end
  #--------------------------------------------------------------------------
  # * Calculate Global Bar Points For User
  #--------------------------------------------------------------------------
  def calculate_gb_for_user(x, a, b, v, item)
    res = [Kernel.eval(item.gb_user_formula), 0].max rescue 0
    test_print("user", a, b, get_gb_rate, x, res, item)
    res *= get_gb_rate * item.gb_rate
    get_unit(a).add_gb_value(res.to_i)
  end
  #--------------------------------------------------------------------------
  # * Calculate Global Bar Points For Target
  #--------------------------------------------------------------------------
  def calculate_gb_for_target(x, a, b, v, item)
    res = [Kernel.eval(item.gb_target_formula), 0].max rescue 0
    test_print("target", a, b, get_gb_rate, x, res, item)
    res *= get_gb_rate * item.gb_rate
    get_unit(b).add_gb_value(res.to_i)
  end
  #--------------------------------------------------------------------------
  # * Calculate Global Bar Points For Ally Damage
  #--------------------------------------------------------------------------
  def calculate_gb_for_ally(x, a, b, v, item)
    res = [Kernel.eval(item.gb_ally_formula), 0].max rescue 0
    test_print("ally", a, b, get_gb_rate, x, res, item)
    res *= get_gb_rate * item.gb_rate
    get_unit(b).add_gb_value(res.to_i)
  end
  #--------------------------------------------------------------------------
  # * Function Used To Print Debug Info
  #--------------------------------------------------------------------------
  def test_print(*args)
    p "============================="
    p "function: " + args[0]
    p "user:     " + (args[1].is_a?(Game_Actor) ? args[1].name : args[1].original_name)
    p "target:   " + (args[2].is_a?(Game_Actor) ? args[2].name : args[2].original_name)
    p "-----------------------------"
    p "total rate:   " + args[3].to_s
    p "rate (+item): " + (args[3] * args[6].gb_rate).to_s
    p "total damage: " + args[4].to_s 
    p "GB points:    " + args[5].to_s
    p "GB (+item):   " + (args[5]* args[6].gb_rate).to_s
    if args[6].is_a?(RPG::Skill)
      p "skill used:   " + args[6].name
    else
      p "item used:    " + args[6].name
    end
    p "-----------------------------"
    p "item parameters:"
    p "rate:           " + args[6].gb_rate.to_s
    p "user formula:   " + args[6].gb_user_formula
    p "target formula: " + args[6].gb_target_formula
    p "ally formula:   " + args[6].gb_ally_formula
    p "============================="
    p ""
    p ""
  end
end

#==============================================================================
# ** Window_SkillList
#==============================================================================

class Window_SkillList < Window_Selectable
  #--------------------------------------------------------------------------
  # * Draw Skill Use Cost
  #--------------------------------------------------------------------------
  alias draw_skill_cost_1y9lv draw_skill_cost
  def draw_skill_cost(rect, skill)
    if @actor.skill_gb_cost(skill) > 0
      change_color(text_color(YuriSH::GlobalBar::COLOR), enable?(skill))
      if skill.percent_value > 0
        draw_text(rect, skill.percent_value.to_s + "%", 2)
      else
        draw_text(rect, @actor.skill_gb_cost(skill), 2)
      end
    else
      draw_skill_cost_1y9lv(rect, skill)
    end
  end
end

#==============================================================================
# ** Scene_Battle
#==============================================================================

class Scene_Battle < Scene_Base
  #--------------------------------------------------------------------------
  # * Create All Windows
  #--------------------------------------------------------------------------
  alias create_all_windows_yurish_1y9lv create_all_windows
  def create_all_windows
    create_all_windows_yurish_1y9lv
    create_gb_window
  end
  #--------------------------------------------------------------------------
  # * Create Global Bar Window
  #--------------------------------------------------------------------------
  def create_gb_window
    wx = YuriSH::GlobalBar::WINDOW_POS == :left ? 0 : Graphics.width - 64
    @gb_window = Window_GlobalBar.new(wx, Graphics.height - 240)
  end
  #--------------------------------------------------------------------------
  # * Update Frame (Basic)
  #--------------------------------------------------------------------------
  alias update_basic_yurish_1y9lv update_basic
  def update_basic
    update_basic_yurish_1y9lv
    update_gb_window
  end
  #--------------------------------------------------------------------------
  # * Update Global Bar Window Position
  #--------------------------------------------------------------------------
  def update_gb_window
    return unless @gb_window.close?
    if BattleManager.in_turn?
      @gb_window.y = Graphics.height - 120
    else
      @gb_window.y = Graphics.height - 240
    end
  end
  #--------------------------------------------------------------------------
  # * Start Party Command Selection
  #--------------------------------------------------------------------------
  alias start_party_command_selection_yurish_1y9lv start_party_command_selection
  def start_party_command_selection
    unless scene_changing?
      @gb_window.counter = 0
      @gb_window.hide_window
    end
    start_party_command_selection_yurish_1y9lv
  end
  #--------------------------------------------------------------------------
  # * Start Actor Command Selection
  #--------------------------------------------------------------------------
  alias start_actor_command_selection_yurish_1y9lv start_actor_command_selection
  def start_actor_command_selection
    @gb_window.show_window
    start_actor_command_selection_yurish_1y9lv
  end
  #--------------------------------------------------------------------------
  # * Start Turn
  #--------------------------------------------------------------------------
  alias turn_start_yurish_1y9lv turn_start
  def turn_start
    @gb_window.counter = 0
    @gb_window.hide_window
    turn_start_yurish_1y9lv
  end
end