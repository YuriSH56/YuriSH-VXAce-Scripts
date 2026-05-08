# =============================================================================
# ** Custom Use Message
# * By YuriSH
# -----------------------------------------------------------------------------
# * UPDATES HISTORY
# -----------------------------------------------------------------------------
# * Version 1.0 (04.22.2026)
#     Initial release.
#
# * Version 1.1 (08.05.2026)
#     Added "\[target]" and "\[item]" control characters.
#     Added pronouns feature.
# -----------------------------------------------------------------------------
# * SCRIPT DESCRIPTION
# -----------------------------------------------------------------------------
# This script adds more options for skill use messages.
# This script also adds a way to change item use message.
# -----------------------------------------------------------------------------
# * USAGE
# -----------------------------------------------------------------------------
# Skill's "Using Message" now allows for several control characters to be used.
# Those are:
# * \[name]   - Skill user's name.
# * \[nick]   - Skill user's nickname (only for actors).
# * \[class]  - Skill user's class (only for actors).
# * \[target] - Skill target's name. Shows only first target's name if multiple.
# * \[item]   - Used item or skill name.
# * \[v: x]   - x'th variable.
#
# To give an Item a unique use message, use the following note tag:
# <use message>
# MESSAGE
# </use message>
# Where MESSAGE - any text string. 2 lines max. The rest will be ignored.
# Same control characters are allowed as for skill's use message.
#
# To specify a pronoun for a character, use following tag:
# <pronoun: PRONOUN>
# Where PRONOUN - any text string.
#
# You can change if skill user's name should be prepended
# to the message or not.
# To do that, use the following note tag:
# * <prepend user name: x>
# Where x - true of false.
# By default, it is set to true.
# To change default behaviour, edit ADD_USER_NAME value to either true or false.
#
# If item has no use message defined, it will use default use message
# without any changes, even if ADD_USER_NAME is set to false.
# =============================================================================

$imported = {} if $imported.nil?
$imported["YuriSH_CustomUseMsg"] = true

# =============================================================================
# CONFIGURATION BEGIN
# =============================================================================

module YuriSH
  module UseMsg
    # ============\/\/ DO NOT CHANGE THIS \/\/============ #
    # Regex for whether should use message have user name at beginning or not
    USE_MSG_DEF = /<prepend user name: ?(true|false)>/i
    
    # Regex for item use message
    ITEM_USE_MSG = /<use message>(.*?)<\/use message>/im
    
    # Regex for pronouns
    PRONOUN = /<pronoun: ?(.+)>/i
    
    # Regex for name control character
    CHAR_NAME = /\e\[name\]/i
    
    # Regex for nickname control character
    CHAR_NICK = /\e\[nick\]/i
    
    # Regex for class control character
    CHAR_CLASS = /\e\[class\]/i
    
    # Regex for target name
    CHAR_TRGT = /\e\[target\]/i
    
    # Regex for item name
    CHAR_ITEM = /\e\[item\]/i
    
    # Regex for variable control character
    CHAR_VAR = /\e\[v: ?(\d+)\]/i
    # ============/\/\ DO NOT CHANGE THIS /\/\============ #
    
    # If true - item's user name will be added to the beginning of use message.
    # (DEFAULT: true)
    ADD_USER_NAME = true
    
    # If true - when user and target is the same, [target] will be replaced
    # with a pronoun instead.
    # (DEFAULT: true)
    USE_PRONOUNS = true
    
    # Default pronoun to use if unspecified.
    # (DEFAULT: "himself")
    DEFAULT_PRONOUN = "himself"
  end
end

# =============================================================================
# CONFIGURATION END
# =============================================================================

#==============================================================================
# ** RPG::BaseItem
#==============================================================================

class RPG::BaseItem
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_reader :pronoun
  #--------------------------------------------------------------------------
  # * Get Pronoun
  #--------------------------------------------------------------------------
  def pronoun
    if @pronoun.nil?
      @pronoun = (@note =~ YuriSH::UseMsg::PRONOUN ? $1 : YuriSH::UseMsg::DEFAULT_PRONOUN)
    end
    @pronoun
  end
end

#==============================================================================
# ** RPG::UsableItem
#==============================================================================

class RPG::UsableItem < RPG::BaseItem
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_reader :add_user_name
  #--------------------------------------------------------------------------
  # * Get If Usable Item Should Prepend User Name
  #--------------------------------------------------------------------------
  def add_user_name
    if @add_user_name.nil?
      @add_user_name = (@note =~ YuriSH::UseMsg::USE_MSG_DEF ? ($1.downcase == "true" ? true : false) : YuriSH::UseMsg::ADD_USER_NAME)
    end
    @add_user_name
  end
end

#==============================================================================
# ** RPG::Item
#==============================================================================

class RPG::Item < RPG::UsableItem
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_reader :message1
  attr_reader :message2
  #--------------------------------------------------------------------------
  # * Sets Up Message Variables For Item
  #--------------------------------------------------------------------------
  def message_setup
    if @note =~ YuriSH::UseMsg::ITEM_USE_MSG
      str_bits = $1.split("\r\n").delete_if {|x| x.empty?}
      @message1 = str_bits.at(0).nil? ? "" : str_bits[0]
      @message2 = str_bits.at(1).nil? ? "" : str_bits[1]
    else
      @message1 = ""
      @message2 = ""
    end
  end
  #--------------------------------------------------------------------------
  # * Get First Message
  #--------------------------------------------------------------------------
  def message1
    if @message1.nil?
      message_setup
    end
    @message1
  end
  #--------------------------------------------------------------------------
  # * Get Second Message
  #--------------------------------------------------------------------------
  def message2
    if @message2.nil?
      message_setup
    end
    @message2
  end
end

#==============================================================================
# ** Game_Actor
#==============================================================================

class Game_Actor < Game_Battler
  #--------------------------------------------------------------------------
  # * Get Pronoun
  #-------------------------------------------------------------------------- 
  def pronoun
    actor.pronoun
  end
end

#==============================================================================
# ** Game_Enemy
#==============================================================================

class Game_Enemy < Game_Battler
  #--------------------------------------------------------------------------
  # * Get Pronoun
  #--------------------------------------------------------------------------
  def pronoun
    enemy.pronoun
  end
end

#==============================================================================
# ** Scene_Battle
#==============================================================================

class Scene_Battle < Scene_Base
  #--------------------------------------------------------------------------
  # * Use Skill/Item
  #--------------------------------------------------------------------------
  alias use_item_yurish_cstmum use_item
  def use_item
    targets = @subject.current_action.make_targets.compact rescue []
    @log_window.target = targets.at(0)
    use_item_yurish_cstmum
  end
end

#==============================================================================
# ** Window_BattleLog
#==============================================================================

class Window_BattleLog < Window_Selectable
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_writer :target   # Item use target
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  alias initialize_yurish_cstmum initialize
  def initialize
    @target = nil
    initialize_yurish_cstmum
  end
  #--------------------------------------------------------------------------
  # * Replaces Control Characters In A String
  #   The character "\" is replaced with the escape character (\e).
  #--------------------------------------------------------------------------
  def prep_message(subject, value, item, prep = false)
    v = value.clone
    v.gsub!(/\\/)                         { "\e" }
    v.gsub!(YuriSH::UseMsg::CHAR_NAME)    { subject.name }
    v.gsub!(YuriSH::UseMsg::CHAR_ITEM)    { item.name }
    if @target
      if YuriSH::UseMsg::USE_PRONOUNS && @target == subject
        v.gsub!(YuriSH::UseMsg::CHAR_TRGT)  { subject.pronoun }
      else
        v.gsub!(YuriSH::UseMsg::CHAR_TRGT)  { @target.name }
      end
    else
      v.gsub!(YuriSH::UseMsg::CHAR_TRGT)  { "" }
    end
    if subject.is_a?(Game_Actor)
      v.gsub!(YuriSH::UseMsg::CHAR_NICK)  { subject.nickname }
      v.gsub!(YuriSH::UseMsg::CHAR_CLASS) { $data_classes[subject.class_id].name }
    else
      v.gsub!(YuriSH::UseMsg::CHAR_NICK)  { "" }
      v.gsub!(YuriSH::UseMsg::CHAR_CLASS) { "" }
    end
    v.gsub!(YuriSH::UseMsg::CHAR_VAR)     { $game_variables[$1.to_i].to_s }
    v = subject.name + v if prep
    v
  end
  #--------------------------------------------------------------------------
  # * Display Skill/Item Use
  #--------------------------------------------------------------------------
  def display_use_item(subject, item)
    # YEA Battle Engine compatibility
    if $imported["YEA-BattleEngine"]
      return unless YEA::BATTLE::MSG_CURRENT_ACTION
    end
    if item.is_a?(RPG::Item) and item.message1.empty?
      add_text(sprintf(Vocab::UseItem, subject.name, item.name))
    else
      return if item.message1.empty?
      add_text(prep_message(subject, item.message1, item, item.add_user_name))
      unless item.message2.empty?
        wait
        add_text(prep_message(subject, item.message2, item, false))
      end
    end
  end
end