# =============================================================================
# ** Yanfly Engine Ace - Ace Battle Engine - Lingering Popups Fix
# * By YuriSH
# -----------------------------------------------------------------------------
# You might have noticed that when party member is removed from your party
# during battle, all popups created for that party member will linger on your
# screen permanently until scene is changed.
#
# This scriptlet fixed that issue, ensuring that popups are updated even if
# battler is no longer in your party.
# =============================================================================

#==============================================================================
# ** Sprite_Battler
#==============================================================================

class Sprite_Battler < Sprite_Base
  # ---------------------------------------------------------------------------
  # * Frame Update
  # ---------------------------------------------------------------------------
  alias update_yurish_7zp2a update 
  def update
    update_yurish_7zp2a
    unless @battler
      update_popups
    end
  end
end