# =============================================================================
# ** Slopes
# * By YuriSH
# -----------------------------------------------------------------------------
# Script reserves two terrain tags to be used for slopes.
#
# Whenever player moves past tiles with those tags they will automatically
# go up the slope. If the tag is BELOW the player character,
# they will move down.
#
# Script can be toggled by calling:
# $game_player.slopes_enabled = true (to enable)
# or
# $game_player.slopes_enabled = false (to disable)
# =============================================================================

$imported = {} if $imported.nil?
$imported["YuriSH_Slopes"] = true

# =============================================================================
# CONFIGURATION BEGIN
# =============================================================================

module YuriSH
  module Const
    module Slopes
      RIGHT_SLOPE = 5   # Terrain Tag of right-facing slopes
      LEFT_SLOPE  = 6   # Terrain Tag of left-facing slopes
    end
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
  attr_accessor   :slopes_enabled     # Slopes Enabled
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  alias initialize_yurish_0qz4I initialize
  def initialize
    initialize_yurish_0qz4I
    @slopes_enabled = true
  end
  #--------------------------------------------------------------------------
  # * Move By Input
  #--------------------------------------------------------------------------
  def move_by_input
    return if !movable? || $game_map.interpreter.running?
    if @slopes_enabled
      p_x = $game_player.x
      p_y = $game_player.y
      t_tag = $game_map.terrain_tag(player_x, player_y)
      t_tag_below = $game_map.terrain_tag(player_x, player_y + 1)
      p_dir = Input.dir4
      
      if p_dir == 4
        if t_tag_below == YuriSH::Const::Slopes::RIGHT_SLOPE
          @y += 1
        elsif t_tag == YuriSH::Const::Slopes::LEFT_SLOPE
          @y -= 1
        end
      elsif p_dir == 6
        if t_tag_below == YuriSH::Const::Slopes::LEFT_SLOPE
          @y += 1
        elsif t_tag == YuriSH::Const::Slopes::RIGHT_SLOPE
          @y -= 1
        end
      end
    end
    move_straight(Input.dir4) if Input.dir4 > 0
  end
end