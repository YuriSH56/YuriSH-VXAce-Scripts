# =============================================================================
# ** Battler Wave Effect
# * By YuriSH
# -----------------------------------------------------------------------------
# This script lets you apply RPG Maker's built-in "wave" effect to enemies.
# 
# Put the following tag to enemy's notes:
#   <wave: x, y, z, w>
# Where:
#     x - wave amplitude
#     y - wave length
#     z - wave speed
#     w - wave phase
# For more info, check "Sprite" class in F1 Manual.
# =============================================================================

module YuriSH
  module Const
    module BattlerWave
      REGEX = /<wave: ?(\d+), *(\d+), *(\d+), *(\d+)>/i
    end
  end
end

#==============================================================================
# ** RPG::Enemy
#==============================================================================

class RPG::Enemy
  # ---------------------------------------------------------------------------
  # * Get Wave Params
  # ---------------------------------------------------------------------------
  def wave_params
    if @wave_params.nil?
      @wave_params = (@note =~ YuriSH::Const::BattlerWave::REGEX ? [$1.to_i, $2.to_i, $3.to_i, $4.to_i] : nil)
    end
    @wave_params
  end
end

#==============================================================================
# ** Game_Enemy
#==============================================================================

class Game_Enemy < Game_Battler
  # ---------------------------------------------------------------------------
  # * Get Wave Params
  # ---------------------------------------------------------------------------
  def wave_params
    enemy = $data_enemies[@enemy_id]
    enemy.nil? ? nil : enemy.wave_params
  end
end

#==============================================================================
# ** Spriteset_Battle
#==============================================================================

class Spriteset_Battle
  #----------------------------------------------------------------------------
  # * Create Enemy Sprite
  #----------------------------------------------------------------------------
  def create_enemies
    @enemy_sprites = $game_troop.members.reverse.collect do |enemy|
      p_spr = Sprite_Battler.new(@viewport1, enemy)
      w_params = enemy.wave_params
      unless w_params.nil?
        p_spr.wave_amp = w_params[0]
        p_spr.wave_length = w_params[1]
        p_spr.wave_speed = w_params[2]
        p_spr.wave_phase = w_params[3]
      end
      p_spr
    end
  end
end