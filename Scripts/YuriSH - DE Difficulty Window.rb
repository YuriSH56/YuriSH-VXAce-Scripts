# =============================================================================
# ** Definitive Edition Difficulty Window
# * By YuriSH
# -----------------------------------------------------------------------------
# Adds difficulty window to party's menu.
# Also allows to add more difficulties to the game.
# To get current difficulty, use "$game_player.difficulty" script call.
# To set difficulty, use "$game_player.difficulty = :normal" script call.
# Replace ":normal" with desired difficulty defined in MODES.
# =============================================================================

$imported = {} if $imported.nil?
$imported["YuriSH_DEDifficultyWindow"] = true

# =============================================================================
# CONFIGURATION BEGIN
# =============================================================================

module YuriSH
  module DE_DiffWin
    # -----------------------------------------------------------------------
    # Here is where you add new modes.
    # Format is as follows:
    # -----------------------------------------------------------------------
    # :name   =>    [text_color, "display_name", icon_id]
    # -----------------------------------------------------------------------
    # :name           - A UNIQUE identifier of the difficulty.
    #                   There should be no duplicate names otherwise newer
    #                   entires with overwrite older ones.
    # text_color      - Text color ID. See "text_color" in Window_Base.
    #                 - Put 0 for default color.
    # "display_name"  - Name that will be visible.
    # icon_id         - Icon ID to display. Put -1 for no icon.
    # -----------------------------------------------------------------------
    MODES = {
      :normal   => [0,    "Normal Mode",    68],
      :pain     => [18,   "Pain Mode",      71]
    }
    
    # Initial Difficulty.
    INIT_DIFFICULTY = :normal
  end
end

# =============================================================================
# CONFIGURATION END
# =============================================================================

#==============================================================================
# ** Game_Player
#==============================================================================

class Game_Player < Game_Character
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_accessor :difficulty
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  alias initialize_yurish_sa71z initialize
  def initialize
    initialize_yurish_sa71z
    @difficulty = YuriSH::DE_DiffWin::INIT_DIFFICULTY
  end
  #--------------------------------------------------------------------------
  # * Get Difficulty
  #--------------------------------------------------------------------------
  def difficulty
    @difficulty
  end
  #--------------------------------------------------------------------------
  # * Set Difficulty
  #--------------------------------------------------------------------------
  def difficulty=(symb)
    @difficulty = symb.to_sym
  end
end

#==============================================================================
# ** Window_Difficulty
#==============================================================================

class Window_Difficulty < Window_Base
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize
    super(0,0, window_width, fitting_height(1))
    refresh
  end
  #--------------------------------------------------------------------------
  # * Get Window Width
  #--------------------------------------------------------------------------
  def window_width
    return 160
  end
  #--------------------------------------------------------------------------
  # * Refresh
  #--------------------------------------------------------------------------
  def refresh
    contents.clear
    diff = YuriSH::DE_DiffWin::MODES[$game_player.difficulty]
    col = diff[0] <= 0 ? normal_color : text_color(diff[0])
    
    change_color(col)
    draw_text(-24, 0, contents_width, line_height, diff[1], 2)
    if diff[2] >= 0
      draw_icon(diff[2], contents_width - 24, 0)
    end
    change_color(normal_color)
  end
  #--------------------------------------------------------------------------
  # * Open Window
  #--------------------------------------------------------------------------
  def open
    refresh
    super
  end
end

#==============================================================================
# ** Scene_Menu
#==============================================================================
class Scene_Menu < Scene_MenuBase
  #--------------------------------------------------------------------------
  # * Start Processing (Alias)
  #--------------------------------------------------------------------------
  alias start_yurish_qa5c0 start
  def start
    start_yurish_qa5c0
    create_difficulty_window
  end
  #--------------------------------------------------------------------------
  # * Create Difficulty Window
  #--------------------------------------------------------------------------
  def create_difficulty_window
    @difficulty_window = Window_Difficulty.new
    @difficulty_window.x = 0
    @difficulty_window.y = Graphics.height - @difficulty_window.height - 48
  end
end