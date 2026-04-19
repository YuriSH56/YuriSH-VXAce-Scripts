# =============================================================================
# ** Extra Description Window For Items
# * By YuriSH
# -----------------------------------------------------------------------------
# This script adds an additional window for items/skills which you can use
# to show some additional information.
#
# Add following text to notes area:
# <info>x</info>
# where "x" is any text. Text codes do work.
# =============================================================================

$imported = {} if $imported.nil?
$imported["YuriSH_ExtraDescWindow"] = true

module YuriSH
  module EX_DescWindow
    REGEX = /<info>(.*?)<\/info>/im
    MAX_WIDTH = 200
  end
end

#==============================================================================
# ** RPG::BaseItem
#==============================================================================

class RPG::BaseItem
  # ---------------------------------------------------------------------------
  # * Get Additional Info
  # ---------------------------------------------------------------------------
  def additional_info
    if @additional_info.nil?
      @additional_info = (@note =~ YuriSH::EX_DescWindow::REGEX ? $1.strip : "")
    end
    return @additional_info
  end
  # ---------------------------------------------------------------------------
  # * Set Additional Info
  # ---------------------------------------------------------------------------
  def additional_info=(value)
    @additional_info = value
  end
end

#==============================================================================
# ** Window_AdditionalInfo
#==============================================================================

class Window_AdditionalInfo < Window_Base
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize(line_number = 1)
    super(
      0,
      fitting_height(2),
      YuriSH::EX_DescWindow::MAX_WIDTH,
      fitting_height(line_number)
      )
  end
  #--------------------------------------------------------------------------
  # * Set Text
  #--------------------------------------------------------------------------
  def set_text(text)
    if @text != text
      @text = text
      refresh
    end
  end
  #--------------------------------------------------------------------------
  # * Text Empty?
  #--------------------------------------------------------------------------
  def text_empty?
    return @text.empty?
  end
  #--------------------------------------------------------------------------
  # * Clear
  #--------------------------------------------------------------------------
  def clear
    set_text("")
  end
  #--------------------------------------------------------------------------
  # * Set Item
  #     item : Skills and items etc.
  #--------------------------------------------------------------------------
  def set_item(item)
    set_text(item ? item.additional_info : "")
  end
  #--------------------------------------------------------------------------
  # * Refresh
  #--------------------------------------------------------------------------
  def refresh
    contents.clear
    draw_text_ex(4, 0, @text)
  end
end

#==============================================================================
# ** Window_BattleItem
#==============================================================================

class Window_BattleItem < Window_ItemList
  #--------------------------------------------------------------------------
  # * Set Additional Info Window
  #--------------------------------------------------------------------------
  def additional_info_window=(value)
    @additional_info_window = value
  end
  #--------------------------------------------------------------------------
  # * Show Window
  #--------------------------------------------------------------------------
  alias show_yurish_1z93W show
  def show
    @additional_info_window.show
    show_yurish_1z93W
  end
  #--------------------------------------------------------------------------
  # * Hide Window
  #--------------------------------------------------------------------------
  alias hide_yurish_1z93W hide
  def hide
    @additional_info_window.hide
    hide_yurish_1z93W
  end
  #--------------------------------------------------------------------------
  # * Update Help Text
  #--------------------------------------------------------------------------
  def update_help
    super
    @additional_info_window.set_item(item)
    if @additional_info_window.text_empty?
      @additional_info_window.hide
    else
      @additional_info_window.show
    end
  end
end

#==============================================================================
# ** Window_BattleSkill
#==============================================================================

class Window_BattleSkill < Window_SkillList
  #--------------------------------------------------------------------------
  # * Set Additional Info Window
  #--------------------------------------------------------------------------
  def additional_info_window=(value)
    @additional_info_window = value
  end
  #--------------------------------------------------------------------------
  # * Show Window
  #--------------------------------------------------------------------------
  alias show_yurish_1z93W show
  def show
    @additional_info_window.show
    show_yurish_1z93W
  end
  #--------------------------------------------------------------------------
  # * Hide Window
  #--------------------------------------------------------------------------
  alias hide_yurish_1z93W hide
  def hide
    @additional_info_window.hide
    hide_yurish_1z93W
  end
  #--------------------------------------------------------------------------
  # * Update Help Text
  #--------------------------------------------------------------------------
  def update_help
    super
    @additional_info_window.set_item(item)
    if @additional_info_window.text_empty?
      @additional_info_window.hide
    else
      @additional_info_window.show
    end
  end
end

class Scene_Battle < Scene_Base
  #--------------------------------------------------------------------------
  # * Create All Windows
  #--------------------------------------------------------------------------
  alias create_all_windows_yurish_a29zb create_all_windows
  def create_all_windows
    create_all_windows_yurish_a29zb
    create_additional_info_window
  end
  #--------------------------------------------------------------------------
  # * Create Additional Info Window
  #--------------------------------------------------------------------------
  def create_additional_info_window
    @additional_info_window = Window_AdditionalInfo.new
    @additional_info_window.visible = false
    @item_window.additional_info_window = @additional_info_window
    @skill_window.additional_info_window = @additional_info_window
  end
end