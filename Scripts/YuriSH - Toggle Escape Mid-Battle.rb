# =============================================================================
# ** Toggle Battle Escape
# * By YuriSH
# -----------------------------------------------------------------------------
# Lets you toggle "Escape" option during battles.
#
# Use a script call: BattleManager.can_escape(TrueOrFalse)
# =============================================================================

$imported = {} if $imported.nil?
$imported["YuriSH_ToggleBattleEscape"] = true

#==============================================================================
# ** BattleManager
#==============================================================================

module BattleManager
  def self.can_escape(value)
    @can_escape = value
  end
end