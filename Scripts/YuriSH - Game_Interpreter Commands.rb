# =============================================================================
# ** Game_Interpreter Commands
# * By YuriSH
# -----------------------------------------------------------------------------
# * UPDATES HISTORY
# -----------------------------------------------------------------------------
# * Version 1.0 (05.09.2026)
#     Initial release.
# -----------------------------------------------------------------------------
# * SCRIPT DESCRIPTION
# -----------------------------------------------------------------------------
# This script adds a bunch of useful commands to Game_Interpreter that can be
# used anywhere where Interpreter runs (map events, common events,
# troop pages, etc).
#
# This script will be passively updated to include more stuff overtime.
# -----------------------------------------------------------------------------
# * COMMAND LIST
# -----------------------------------------------------------------------------
# * switch_bike
#   (LCM REQUIRED) Switches player's outfit between normal and bicycle one.
# =============================================================================

$imported = {} if $imported.nil?
$imported["YuriSH_GIntCommands"] = 1.0

module YuriSH
  module GInt
    # Suffix for bicycle outfits
    BIKE_SUFFIX = "_bike"
  end
end

#==============================================================================
# ** Game_Interpreter
#==============================================================================

class Game_Interpreter
  #--------------------------------------------------------------------------
  # * Switches Between Normal And Bicycle Graphics
  #   Requires "Lisa Core Movement" Script
  #--------------------------------------------------------------------------
  def switch_bike
    return unless $imported["Liam-LisaCoreMove"]
    plr = $game_player.actor
    outfit = plr.getActorlcmOutfit
    new_outfit = ""
    if outfit.include?(YuriSH::GInt::BIKE_SUFFIX)
      outfit.gsub!(YuriSH::GInt::BIKE_SUFFIX, "")
    else
      outfit += YuriSH::GInt::BIKE_SUFFIX
    end
    plr.changeActorlcmOutfit(outfit)
    $game_player.restoreOutfitGraphicAndSpeed
  end
end