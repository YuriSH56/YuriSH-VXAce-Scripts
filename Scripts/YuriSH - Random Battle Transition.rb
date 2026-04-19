#==============================================================================
# ** Random Battle Transitions
# * By YuriSH
#------------------------------------------------------------------------------
#  Allows for random battle transition images.
#  Credits to PieJamas for lots of custom transitions:
#  https://grandmadebslittlebits.wordpress.com/2014/11/18/xp-to-vxace-battlestarts/
#
#  To set a specific transition to appear use script call:
#  set_next_transition(name)
#==============================================================================

$imported = {} if $imported.nil?
$imported["YuriSH_RandomBattleTransition"] = true

# =============================================================================
# CONFIGURATION BEGIN
# =============================================================================

module YuriSH
  module RND_BattleTrans
    TRANSITIONS = [   # List of transition images
      # Original
      "_BattleStart",
      # By YuriSH
      "Y01_Bricks",
      "Y02_Spiral",
      "Y03_CrossCurtains",
      "Y04_Blocks",
      "Y05_Checkerboard",
      # By PieJamas
      "001-Blind01",
      "002-Blind02",
      "003-Blind03",
      "004-Blind04",
      "005-Stripe01",
      "006-Stripe02",
      "007-Line01",
      "008-Line02",
      "009-Random01",
      "010-Random02",
      "011-Random03",
      "012-Random04",
      "013-Square01",
      "014-Square02",
      "015-Diamond01",
      "016-Diamond02",
      "017-Brick01",
      "018-Brick02",
      "019-Whorl01",
      "020-Flat01",
    ]
  end
end

# =============================================================================
# CONFIGURATION END
# =============================================================================

#==============================================================================
# ** Scene_Map
#==============================================================================

class Scene_Map < Scene_Base
  #--------------------------------------------------------------------------
  # * Start
  #--------------------------------------------------------------------------
  alias start_yurish start
  def start
    start_yurish
    @next_transition = ""
  end
  #--------------------------------------------------------------------------
  # * Execute Pre-Battle Transition
  #--------------------------------------------------------------------------
  def perform_battle_transition
    image_path = ""
    if !@next_transition.empty?
      image_path = @next_transition
      @next_transition = ""
    else
      image_path = YuriSH::RND_BattleTrans::TRANSITIONS.sample
    end
    Graphics.transition(60, "Graphics/BattleTransitions/" + image_path, 255)
    Graphics.freeze
  end
  #--------------------------------------------------------------------------
  # * Set Next Transition
  #--------------------------------------------------------------------------
  def next_transition=(value)
    @next_transition = value
  end
end

#==============================================================================
# ** Game_Interpreter
#==============================================================================

class Game_Interpreter
  #--------------------------------------------------------------------------
  # * Set Next Transition
  #--------------------------------------------------------------------------
  def set_next_transition(value)
    current_scene = SceneManager.scene
    if current_scene and current_scene.is_a?(Scene_Map)
      if YuriSH::RND_BattleTrans::TRANSITIONS.include?(value)
        current_scene.next_transition = value
      end
    end
  end
end