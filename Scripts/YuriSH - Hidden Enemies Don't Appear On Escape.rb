# =============================================================================
# ** Hidden Enemies Don't Appear On Escape
# * By YuriSH
# -----------------------------------------------------------------------------
# This small scriptlet makes it so hidden enemies do not appear when you
# escape from battle.
#
# Can be toggled by calling:
# * BattleManager.appear_on_abort = x
#   Where x - either true or false.
# =============================================================================

$imported = {} if $imported.nil?
$imported["YuriSH_NoAppearOnEscape"] = true

module DataManager
  #--------------------------------------------------------------------------
  # * Module Aliases
  #--------------------------------------------------------------------------
  class << self
    alias init_yurish_qk1xl init
  end
  #--------------------------------------------------------------------------
  # * Initialize Module
  #--------------------------------------------------------------------------
  def self.init
    @appear_on_abort = true
    init_yurish_qk1xl
  end
  #--------------------------------------------------------------------------
  # * Should Hidden Enemies Appear on Battle Abort?
  #--------------------------------------------------------------------------
  def self.appear_on_abort?
    @appear_on_abort
  end
  #--------------------------------------------------------------------------
  # * Set if Hidden Enemies Should Appear on Battle Abort or Not
  #--------------------------------------------------------------------------
  def self.appear_on_abort=(value)
    @appear_on_abort = value
  end
end

# =============================================================================
# ** Game_BattlerBase
# =============================================================================

class Game_BattlerBase
  alias appear_yurish_qk1xl appear
  #--------------------------------------------------------------------------
  # * Appear
  #--------------------------------------------------------------------------
  def appear
    return if BattleManager.aborting? and !BattleManager.appear_on_abort?
    appear_yurish_qk1xl
  end
end