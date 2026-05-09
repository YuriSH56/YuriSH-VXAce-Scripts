# =============================================================================
# ** Dim Background For Add/Remove State Window
# * By YuriSH
# -----------------------------------------------------------------------------
# This script makes text window use "Dim Background" setting for
# its background when state is added or removed.
# That's all.
# =============================================================================

#==============================================================================
# ** Game_Actor  
#==============================================================================

class Game_Actor < Game_Battler
  #--------------------------------------------------------------------------
  # * Show Added State
  #--------------------------------------------------------------------------
  alias show_added_states_yurish_chstbg show_added_states
  def show_added_states
    $game_message.background = 1
    show_added_states_yurish_chstbg
  end
  #--------------------------------------------------------------------------
  # * Show Removed State
  #--------------------------------------------------------------------------
  alias show_removed_states_yurish_chstbg show_removed_states
  def show_removed_states
    $game_message.background = 1
    show_removed_states_yurish_chstbg
  end
end

#==============================================================================
# ** Window_Message  
#==============================================================================

class Window_Message < Window_Base
  #--------------------------------------------------------------------------
  # * Main Processing of Fiber
  #--------------------------------------------------------------------------
  alias fiber_main_yurish_chstbg fiber_main
  def fiber_main
    fiber_main_yurish_chstbg
    $game_message.background = 0
  end
end