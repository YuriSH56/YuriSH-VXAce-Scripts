# =============================================================================
# ** Multi-Use Items
# * By YuriSH
# -----------------------------------------------------------------------------
# This script lets you set up number of uses for an item before it is removed.
# 
# To specify number of uses for an item, put this in the item's notes:
#   <uses: n>
# Where "n" is number of uses. By default, item has 1 use, like in original.
#
# Put \USES in item description to show how many uses this item has.
# =============================================================================

$imported = {} if $imported.nil?
$imported["YuriSH_MultiUseItems"] = true

module YuriSH
  module ItemMultUse
    REGEX = /<uses: (\d+)>/i
    TEXT_REGEX = /\\USES/i
  end
end

#==============================================================================
# ** RPG::Item
#==============================================================================

class RPG::Item
  @_uses = 1 # Stores how many uses item has by default. SHOULD NOT BE EDITED.
  # ---------------------------------------------------------------------------
  # * Get Use Count
  # ---------------------------------------------------------------------------
  def uses
    if @uses.nil?
      @_uses = (@note =~ YuriSH::ItemMultUse::REGEX ? $1.to_i : 1)
      @uses = @_uses
    end
    return @uses
  end
  # ---------------------------------------------------------------------------
  # * Set Use Count
  # ---------------------------------------------------------------------------
  def uses=(value)
    @uses = value
  end
  # ---------------------------------------------------------------------------
  # * Restores Use Count To Its Default Value
  # ---------------------------------------------------------------------------
  def restore_uses
    @uses = @_uses
  end
end

#==============================================================================
# ** Game_Party
#==============================================================================

class Game_Party < Game_Unit
  #--------------------------------------------------------------------------
  # * Consume Items
  #    If the specified object is a consumable item, the number in investory
  #    will be reduced by 1.
  #--------------------------------------------------------------------------
  alias consume_item_yurish_aj9z2 consume_item
  def consume_item(item)
    if item.is_a?(RPG::Item)
      item.uses -= 1
      if item.uses <= 0
        consume_item_yurish_aj9z2(item)
        item.restore_uses
      end
    end
  end
end

#==============================================================================
# ** Window_Help
#==============================================================================

class Window_Help < Window_Base
  #--------------------------------------------------------------------------
  # * Set Item
  #     item : Skills and items etc.
  #--------------------------------------------------------------------------
  alias set_item_yurish_1zb08 set_item
  def set_item(item)
    if item.is_a?(RPG::Item)
      p item.description
      set_text(item.description.gsub(YuriSH::ItemMultUse::TEXT_REGEX, item.uses.to_s))
      return
    end
    set_item_yurish_1zb08(item)
  end
end