# =============================================================================
# ** Game_Interpreter Commands
# * By YuriSH
# -----------------------------------------------------------------------------
# * UPDATES HISTORY
# -----------------------------------------------------------------------------
# * Version 1.0 (05.09.2026)
#     Initial release.
#
# * Version 1.0.1 (05.09.2026)
#     Added "switch_motor", "on_bike?" and "on_motor?" functions.
#     Added "switch_to" and "has_suffix?" fuctions.
#
# * Version 1.1 (10.03.2026)
#     Added "remove_all_items", "remove_all_armor" and "remove_all_weapons"
#     functions.
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
#     (LCM REQUIRED) Switches player's outfit between normal and bicycle one.
#     Uses "switch_to" internally.
#
# * switch_motor
#     (LCM REQUIRED) Switches player's outfit between normal and motorcycle one.
#     Uses "switch_to" internally.
#
# * on_bike?
#     (LCM REQUIRED) Returns true if player's outfit is bicycle one.
#     Uses "has_suffix?" internally.
#
# * on_motor?
#     (LCM REQUIRED) Returns true if player's outfit is motorcycle one.
#     Uses "has_suffix?" internally.
#
# * switch_to(suffix)
#     (LCM REQUIRED) Switches player's outfit between normal and the one
#     with the specified suffix.
#
# * has_suffix?(suffix)
#     (LCM REQUIRED) Returns true if player's outfit has specified suffix.
#
# * remove_all_items(trueOrFalse)
#     Removes all items from player.
#     If false is passed as an argument or argument is omitted - key items
#     will NOT be removed.
#     If true is passed - key items will also be removed.
#
# * remove_all_armor(trueOrFalse)
#     Removes all armor items from player.
#     If false is passed as an argument or argument is omitted - equipped
#     items will NOT be removed.
#     If true is passed - equipped items will also be removed.
#
# * remove_all_weapons(trueOrFalse)
#     Removes all weapon items from player.
#     If false is passed as an argument or argument is omitted - equipped
#     items will NOT be removed.
#     If true is passed - equipped items will also be removed.
#
# =============================================================================

$imported = {} if $imported.nil?
$imported["YuriSH_GIntCommands"] = 1.1

module YuriSH
  module GInt
    # Suffix for bicycle outfits
    BIKE_SUFFIX = "_bike"
    # Suffix for motorcycle outfits
    MOTOR_SUFFIX = "_motor"
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
    switch_to(YuriSH::GInt::BIKE_SUFFIX)
  end
  #--------------------------------------------------------------------------
  # * True If On Bicycle
  #--------------------------------------------------------------------------
  def on_bike?
    has_suffix?(YuriSH::GInt::BIKE_SUFFIX)
  end
  #--------------------------------------------------------------------------
  # * Switches Between Normal And Motorcycle Graphics
  #   Requires "Lisa Core Movement" Script
  #--------------------------------------------------------------------------
  def switch_motor
    switch_to(YuriSH::GInt::MOTOR_SUFFIX)
  end
  #--------------------------------------------------------------------------
  # * True If On Motorcycle
  #--------------------------------------------------------------------------
  def on_motor?
    has_suffix?(YuriSH::GInt::MOTOR_SUFFIX)
  end
  #--------------------------------------------------------------------------
  # * Switches Between Normal And Suffixed Outfits
  #--------------------------------------------------------------------------
  def switch_to(suffix)
    return unless $imported["Liam-LisaCoreMove"]
    plr = $game_player.actor
    outfit = plr.getActorlcmOutfit
    new_outfit = ""
    if outfit.include?(suffix)
      outfit.gsub!(suffix, "")
    else
      outfit += suffix
    end
    plr.changeActorlcmOutfit(outfit)
    $game_player.restoreOutfitGraphicAndSpeed
  end
  #--------------------------------------------------------------------------
  # * True If Outfit Has Suffix
  #--------------------------------------------------------------------------
  def has_suffix?(suffix)
    return false unless $imported["Liam-LisaCoreMove"]
    plr = $game_player.actor
    outfit = plr.getActorlcmOutfit
    return outfit.include?(suffix)
  end
  #----------------------------------------------------------------------------
  # * Removes All Items From Player
  #----------------------------------------------------------------------------
  def remove_all_items(key_included = false)
    $data_items.each do |i|
      next if i.nil?
      if !i.key_item? or key_included
        $game_party.lose_item(i, 999)
      end
    end
  end
  #----------------------------------------------------------------------------
  # * Removes All Armors From Player
  #----------------------------------------------------------------------------
  def remove_all_armor(equip_included = false)
    $data_armors.each do |i|
      next if i.nil?
      $game_party.lose_item(i, 999, equip_included)
    end
  end
  #----------------------------------------------------------------------------
  # * Removes All Weapons From Player
  #----------------------------------------------------------------------------
  def remove_all_weapons(equip_included = false)
    $data_weapons.each do |i|
      next if i.nil?
      $game_party.lose_item(i, 999, equip_included)
    end
  end
end