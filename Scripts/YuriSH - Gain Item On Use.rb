# =============================================================================
# ** Gain Item On Use
# * By YuriSH
# -----------------------------------------------------------------------------
# This script allows for items and skills to give/take items when used.
#
# Add one or more of following tags to item or skill notes:
# <gain item: x, y>
# <gain weapon: x, y>
# <gain armor: x, y>
# where "x" is respective item's ID, and "y" is item count.
# Negative item counts are allowed.
# =============================================================================

$imported = {} if $imported.nil?
$imported["YuriSH_GainItemOnUse"] = true

module YuriSH
  module Const
    module GainItem
      REGEX = /<gain(?: |_)?(item|weapon|armor): ?+(\d+), ?+(-?\d+)>/i
    end
  end
end

#==============================================================================
# ** RPG::UsableItem
#==============================================================================

class RPG::UsableItem
  # ---------------------------------------------------------------------------
  # * List Of Items To Gain
  # ---------------------------------------------------------------------------
  def gain_item_list
    if @gain_item_list.nil?
      @gain_item_list = []
      @note.scan(YuriSH::Const::GainItem::REGEX) do |arr|
        @gain_item_list.append([arr[0].downcase, arr[1].to_i, arr[2].to_i])
      end
    end
    return @gain_item_list
  end
end

#==============================================================================
# ** Game_Battler
#==============================================================================

class Game_Battler < Game_BattlerBase
  #--------------------------------------------------------------------------
  # * Apply Item
  #--------------------------------------------------------------------------
  alias item_apply_yurish_7uv2a item_apply
  def item_apply(user, item)
    item_apply_yurish_7uv2a(user, item)
    item_check_party_gain_item(user, item)
  end
  #--------------------------------------------------------------------------
  # * Checks For <gain item: x,y> Tag And Gives Item
  #--------------------------------------------------------------------------
  def item_check_party_gain_item(user, item)
    return unless (user.is_a?(Game_Actor) && item.is_a?(RPG::UsableItem))
    item.gain_item_list.each do |gain_item|
      container = nil
      case gain_item[0]
      when "item"
        container = $data_items
      when "armor"
        container = $data_armors
      when "weapon"
        container = $data_weapons
      end
      next if container.nil?
      $game_party.gain_item(container[gain_item[1]], gain_item[2])
    end
  end
end