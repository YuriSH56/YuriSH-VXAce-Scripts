# =============================================================================
# ** Random Debuff State
# * By YuriSH
# -----------------------------------------------------------------------------
# * UPDATES HISTORY
# -----------------------------------------------------------------------------
# * Version 1.0 (04.23.2026)
#     Initial release.
# -----------------------------------------------------------------------------
# * SCRIPT DESCRIPTION
# -----------------------------------------------------------------------------
# This script allows you to make a state apply random set of parameter changes.
# Ranges of each parameter change can be edited.
#
# You can make multiple randomized states. Each can be customized in terms of
# chance of parameter being included and to include/exclude specific
# parameter groups.
# =============================================================================

$imported = {} if $imported.nil?
$imported["YuriSH_RDS"] = true

# =============================================================================
# CONFIGURATION BEGIN
# =============================================================================

module YuriSH
  module RDS
    # ==========\/\/ DO NOT CHANGE THIS \/\/========== #
    # Random object.
    RANDOM = Random.new
    # ==========/\/\ DO NOT CHANGE THIS /\/\========== #
    
    # IDs of states that will have randomized debuffs and array of chances
    # for each debuff type.
    # Chance 1.0 will include ALL parameters from the group.
    # If you don't want a state to have a specific type of debuff,
    # put 0.0 or nil as its chance or omit it from the list if there are no
    # more values after it.
    ID = {
      54 => [
        # Normal Parameters
        0.55,
        # EX Parameters
        0.55,
        # SP Parameters
        0.55,
        # Debuff Rate
        0.3,
        # Element Rate
        0.35,
        # State Rate
        0.35,
        # Attack Rate
        0.2,
        # State Resist
        0.35
      ], # comma MUST be there.
      55 => [
        # All Normal Parameters and nothing else
        1.0
      ], # comma MUST be there.
    }
    
    # Chances for each Parameter.
    PARAMS = {
      0 => (35..95),  # Max HP
      1 => (40..95),  # Max MP
      2 => (35..95),  # Attack
      3 => (45..95),  # Defense
      4 => (35..95),  # Magic Attack
      5 => (35..95),  # Magic Defense
      6 => (15..85),  # Agility
      7 => (15..85),  # Luck
    }
    
    # Chances for each Ex Parameter.
    PARAMS_EX = {
      0 => (5..60),   # Hit Rate
      1 => (10..100), # Evasion Rate
      2 => (5..100),  # Critical Hit Rate
      3 => (20..100), # Critical Evasion Rate
      4 => (20..100), # Magic Evasion Rate
      5 => (20..100), # Magic Reflection Rate
      6 => (50..95), # Counterattack Rate
      7 => (1..10),   # HP Regeneration Rate
      8 => (1..20),   # MP Regeneration Rate
      9 => (1..10),   # TP Regeneration Rate
    }
    
    # Chances for each Sp Parameter.
    PARAMS_SP = {
      0 => (75..95),  # Target Rate
      1 => (75..95),  # Guard Effect Rate
      2 => (75..95),  # Recovery Effect Rate
      3 => (75..95),  # Pharmacology
      4 => (75..95),  # MP Cost Rate
      5 => (75..95),  # TP Charge Rate
      6 => (75..95),  # Physical Damage Rate
      7 => (75..95),  # Magical Damage Rate
      8 => (75..95), # Floor Damage Rate
      9 => (75..95), # Experience Rate
    }
    
    # Debuff rates.
    DEBUFF_RATE = {
      0 => (100..200),  # Max HP
      1 => (100..200),  # Max MP
      2 => (100..200),  # Attack
      3 => (100..200),  # Defense
      4 => (100..200),  # Magic Attack
      5 => (100..200),  # Magic Defense
      6 => (100..200),  # Agility
      7 => (100..200),  # Luck
    }
    
    # Chances for element rate debuffs.
    # Element_ID => (Min..Max)
    ELEMENT_RATE = {
      1 => (100..150), # Physical
      2 => (100..150), # Absorb
    }
    
    # State rate multipliers.
    # StateID => (Min..Max)
    STATE_RATE = {
      29 => (100..300), # Crying
      36 => (100..300), # Pissed
    }
    
    # Attack rate.
    # Will be inversed.
    ATTACK_RATE = (0..3)
    
    # State resists.
    STATE_RESIST = [42,43] # Cool, Super Cool
    
    #------------------------------------------------------------------------
    # * Rolls a Number From a Range
    #------------------------------------------------------------------------
    def self.rand(value)
      RANDOM.rand(value)
    end
    #------------------------------------------------------------------------
    # * Returns True if Random Rolls A Number Lesser Than Value
    #------------------------------------------------------------------------
    def self.rand?(value)
      RANDOM.rand < value
    end
    #------------------------------------------------------------------------
    # * Returns True State is Random State
    #------------------------------------------------------------------------
    def self.random_state?(state_id)
      ID.include?(state_id)
    end
    #------------------------------------------------------------------------
    # * Rolls For Each Item In Obj
    #------------------------------------------------------------------------
    def self.roll_obj(obj, param_id, chance, sign = 1.0)
      return [] if (chance.nil? or chance <= 0.0)
      res = []
      obj.keys.each do |key|
        next unless rand?(chance)
        rate = sign * (rand(obj[key]) / 100.0).round(2)
        res.push(RPG::BaseItem::Feature.new(param_id, key, rate))
      end
      return res
    end
    #------------------------------------------------------------------------
    # * Returns an Array of Random Features for Specified State ID
    #------------------------------------------------------------------------
    def self.return_features(state_id)
      data = ID[state_id]
      features = []
      # Normal Parameters
      features += roll_obj(PARAMS, Game_BattlerBase::FEATURE_PARAM, data.at(0))
      # EX Parameters
      features += roll_obj(PARAMS_EX, Game_BattlerBase::FEATURE_XPARAM, data.at(1), -1.0)
      # SP Parameters
      features += roll_obj(PARAMS_SP, Game_BattlerBase::FEATURE_SPARAM, data.at(2))
      # Debuff Rates
      features += roll_obj(DEBUFF_RATE, Game_BattlerBase::FEATURE_DEBUFF_RATE, data.at(3))
      # Element Rates
      features += roll_obj(ELEMENT_RATE, Game_BattlerBase::FEATURE_ELEMENT_RATE, data.at(4))
      # State Rates
      features += roll_obj(STATE_RATE, Game_BattlerBase::FEATURE_STATE_RATE, data.at(5))
      # Attack Rate
      chance = data.at(6)
      if !chance.nil? and chance > 0.0 and rand?(data[6])
        features.push(
          RPG::BaseItem::Feature.new(Game_BattlerBase::FEATURE_ATK_SPEED, rand(ATTACK_RATE), 0.0)
        )
      end
      # State Resists
      chance = data.at(7)
      if !chance.nil? and chance > 0.0
        STATE_RESIST.each do |state|
          next unless rand?(data[7])
          features.push(
            RPG::BaseItem::Feature.new(Game_BattlerBase::FEATURE_STATE_RESIST, state, 0.0)
          )
        end
      end
      return features
    end
  end
end

# =============================================================================
# CONFIGURATION END
# =============================================================================

#==============================================================================
# ** Game_Battler
#==============================================================================

class Game_Battler < Game_BattlerBase
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_reader   :random_features          # random state features
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  alias initialize_yurish_a1q21 initialize
  def initialize
    @random_features = {}
    initialize_yurish_a1q21
  end
  #--------------------------------------------------------------------------
  # * Get Array of All Feature Objects
  #--------------------------------------------------------------------------
  def all_features
    super + @random_features.values.flatten
  end
  #--------------------------------------------------------------------------
  # * Clear State Information
  #--------------------------------------------------------------------------
  alias clear_states_yurish_a1q21 clear_states
  def clear_states
    clear_all_random_features
    clear_states_yurish_a1q21
  end
  #--------------------------------------------------------------------------
  # * Add New State
  #--------------------------------------------------------------------------
  alias add_new_state_yurish_a1q21 add_new_state
  def add_new_state(state_id)
    roll_random_features(state_id) if YuriSH::RDS.random_state?(state_id)
    add_new_state_yurish_a1q21(state_id)
  end
  #--------------------------------------------------------------------------
  # * Erase States
  #--------------------------------------------------------------------------
  def erase_state(state_id)
    super(state_id)
    clear_random_features(state_id) if YuriSH::RDS.random_state?(state_id)
  end
  #--------------------------------------------------------------------------
  # * Roll Random Features for Specified State
  #--------------------------------------------------------------------------
  def roll_random_features(state_id)
    @random_features[state_id] = YuriSH::RDS.return_features(state_id)
  end
  #--------------------------------------------------------------------------
  # * Clear Random Features for Specified State
  #--------------------------------------------------------------------------
  def clear_random_features(state_id)
    @random_features.delete(state_id)
  end
  #--------------------------------------------------------------------------
  # * Clear All Random Features
  #--------------------------------------------------------------------------
  def clear_all_random_features
    @random_features.clear
  end
end