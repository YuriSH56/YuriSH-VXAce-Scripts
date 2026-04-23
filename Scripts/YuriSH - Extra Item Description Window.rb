# =============================================================================
# ** Extra Description Window For Items
# * By YuriSH
# -----------------------------------------------------------------------------
# * UPDATES HISTORY
# -----------------------------------------------------------------------------
# * Version 1.0 (04.04.2026)
#     Initial release.
#
# * Version 1.1 (04.23.2026)
#     Description window now appears in overworld menu and shops.
#     Window can be toggled by pressing SHIFT.
#     Overflowing text now scrolls.
# -----------------------------------------------------------------------------
# 
#                   !!!REQUIRES "HELPER FUNCTIONS" SCRIPT!!!
#
# This script adds an additional window for items/skills which you can use
# to show some additional information.
#
# Add following text to notes area:
# <info>x</info>
# where "x" is any text. Text codes do work.
# =============================================================================

$imported = {} if $imported.nil?
$imported["YuriSH_ExtraDescWindow"] = true

unless $imported.key?("YuriSH_HelperFunctions")
  msgbox('"Helper Functions" script missing.')
  exit
end

# =============================================================================
# CONFIGURATION BEGIN
# =============================================================================

module YuriSH
  module EX_DescWindow
    # ============\/\/ DO NOT CHANGE THIS \/\/============ #
    REGEX = /<info>(.*?)<\/info>/im
    # ============/\/\ DO NOT CHANGE THIS /\/\============ #
    
    # Width of the description window.
    # (DEFAULT: 200)
    MAX_WIDTH = 200
    
    # Wait time (in frames) before window text starts scrolling.
    # (DEFAULT: 60 - 1 second)
    SCROLL_WAIT = 60
    
    # Speed at which text scrolls.
    # (DEFAULT: 1)
    SCROLL_SPEED = 1
  end
end

# =============================================================================
# CONFIGURATION END
# =============================================================================

#==============================================================================
# ** RPG::BaseItem
#==============================================================================

class RPG::BaseItem
  # ---------------------------------------------------------------------------
  # * Get Additional Info Text From Note Tag
  # ---------------------------------------------------------------------------
  def get_addit_info_text
    if @note =~ YuriSH::EX_DescWindow::REGEX
      str_bits = $1.strip.split("\n").delete_if {|x| x.empty?}
      @additional_info = str_bits.at(0).nil? ? "" : str_bits[0]
    else
      @additional_info = ""
    end
  end
  # ---------------------------------------------------------------------------
  # * Get Additional Info
  # ---------------------------------------------------------------------------
  def additional_info
    if @additional_info.nil?
      @additional_info = get_addit_info_text
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
    @wait_counter = YuriSH::EX_DescWindow::SCROLL_WAIT
    clear
  end
  #--------------------------------------------------------------------------
  # * Calculate Width of Window Contents
  #--------------------------------------------------------------------------
  def contents_width
    @last_pos[:x] + standard_padding
  end
  #--------------------------------------------------------------------------
  # * Calculate Width of Visible Window Contents
  #--------------------------------------------------------------------------
  def visible_contents_width
    width - standard_padding * 2
  end
  #--------------------------------------------------------------------------
  # * Set Text
  #--------------------------------------------------------------------------
  def set_text(text)
    @text = text
    @wait_counter = YuriSH::EX_DescWindow::SCROLL_WAIT
    self.ox = 0
    refresh
  end
  #--------------------------------------------------------------------------
  # * Text Empty?
  #--------------------------------------------------------------------------
  def text_empty?
    @text.empty?
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
    draw_text_ex(4, 0, @text)
    create_contents
    draw_text_ex(4, 0, @text)
    text_empty? ? hide : show
  end
  #--------------------------------------------------------------------------
  # * Toggle
  #--------------------------------------------------------------------------
  def toggle
    unless text_empty?
      self.visible ? hide : show
      @wait_counter = YuriSH::EX_DescWindow::SCROLL_WAIT
      self.ox = 0
      Sound.play_cursor
    end
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  def update
    super
    return unless self.visible
    update_wait_counter
    update_scroll
  end
  #--------------------------------------------------------------------------
  # * Update Wait Counter
  #--------------------------------------------------------------------------
  def update_wait_counter
    @wait_counter -= 1 unless @wait_counter == 0
  end
  #--------------------------------------------------------------------------
  # * Update Scroll
  #--------------------------------------------------------------------------
  def update_scroll
    return unless @wait_counter == 0
    return if contents_width - self.ox <= visible_contents_width
    self.ox += YuriSH::EX_DescWindow::SCROLL_SPEED
  end
end

#==============================================================================
# ** Window_Selectable
#==============================================================================

class Window_Selectable < Window_Base
  #--------------------------------------------------------------------------
  # * Set Additional Info Window
  #--------------------------------------------------------------------------
  def additional_info_window=(value)
    @additional_info_window = value
  end
  #--------------------------------------------------------------------------
  # * Call Help Window Update Method
  #--------------------------------------------------------------------------
  alias call_update_help_yurish_a29zb call_update_help
  def call_update_help
    call_update_help_yurish_a29zb
    update_additional_info if active && @additional_info_window
  end
  #--------------------------------------------------------------------------
  # * Update Additional Info Text
  #--------------------------------------------------------------------------
  def update_additional_info
    unless $game_party.in_battle
      c_x = center_x(index)
      c_y = center_y(index)
      @additional_info_window.x = c_x - @additional_info_window.width / 2
      @additional_info_window.y = c_y - @additional_info_window.height - 12
    end
  end
end

#==============================================================================
# ** Window_ItemList
#==============================================================================

class Window_ItemList < Window_Selectable
  #--------------------------------------------------------------------------
  # * Update Additional Info Text
  #--------------------------------------------------------------------------
  def update_additional_info
    @additional_info_window.set_item(item)
    super
  end
end

#==============================================================================
# ** Window_SkillList
#==============================================================================

class Window_SkillList < Window_Selectable
  #--------------------------------------------------------------------------
  # * Update Additional Info Text
  #--------------------------------------------------------------------------
  def update_additional_info
    @additional_info_window.set_item(item)
    super
  end
end

#==============================================================================
# ** Window_ShopBuy
#==============================================================================

class Window_ShopBuy < Window_Selectable
  #--------------------------------------------------------------------------
  # * Update Additional Info Text
  #--------------------------------------------------------------------------
  def update_additional_info
    @additional_info_window.set_item(item)
    super
  end
end

#==============================================================================
# ** Scene_Battle
#==============================================================================

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
  #--------------------------------------------------------------------------
  # * Skill [Cancel]
  #--------------------------------------------------------------------------
  alias on_skill_cancel_yurish_a29zb on_skill_cancel
  def on_skill_cancel
    @additional_info_window.clear
    on_skill_cancel_yurish_a29zb
  end
  #--------------------------------------------------------------------------
  # * Item [Cancel]
  #--------------------------------------------------------------------------
  alias on_item_cancel_yurish_a29zb on_item_cancel
  def on_item_cancel
    @additional_info_window.clear
    on_item_cancel_yurish_a29zb
  end
end

#==============================================================================
# ** Scene_MenuBase
#==============================================================================

class Scene_MenuBase < Scene_Base
  #--------------------------------------------------------------------------
  # * Create Additional Info Window
  #--------------------------------------------------------------------------
  def create_additional_info_window
    @additional_info_window = Window_AdditionalInfo.new
    @additional_info_window.viewport = @viewport
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  def update
    super
    @additional_info_window.toggle if Input.trigger?(:A)
  end
end

#==============================================================================
# ** Scene_Item
#==============================================================================

class Scene_Item < Scene_ItemBase
  #--------------------------------------------------------------------------
  # * Start Processing
  #--------------------------------------------------------------------------
  alias start_yurish_a29zb start
  def start
    start_yurish_a29zb
    create_additional_info_window
    @item_window.additional_info_window = @additional_info_window
  end
  #--------------------------------------------------------------------------
  # * Item [Cancel]
  #--------------------------------------------------------------------------
  alias on_item_cancel_yurish_a29zb on_item_cancel
  def on_item_cancel
    @additional_info_window.clear
    on_item_cancel_yurish_a29zb
  end
end

#==============================================================================
# ** Scene_Skill
#==============================================================================

class Scene_Skill < Scene_ItemBase
  #--------------------------------------------------------------------------
  # * Start Processing
  #--------------------------------------------------------------------------
  alias start_yurish_a29zb start
  def start
    start_yurish_a29zb
    create_additional_info_window
    @item_window.additional_info_window = @additional_info_window
  end
  #--------------------------------------------------------------------------
  # * Item [Cancel]
  #--------------------------------------------------------------------------
  alias on_item_cancel_yurish_a29zb on_item_cancel
  def on_item_cancel
    @additional_info_window.clear
    on_item_cancel_yurish_a29zb
  end
end

#==============================================================================
# ** Scene_Shop
#==============================================================================

class Scene_Shop < Scene_MenuBase
  #--------------------------------------------------------------------------
  # * Start Processing
  #--------------------------------------------------------------------------
  alias start_yurish_a29zb start
  def start
    start_yurish_a29zb
    create_additional_info_window
    @buy_window.additional_info_window = @additional_info_window
    @sell_window.additional_info_window = @additional_info_window
  end
  #--------------------------------------------------------------------------
  # * Buy [OK]
  #--------------------------------------------------------------------------
  alias on_buy_ok_yurish_a29zb on_buy_ok
  def on_buy_ok
    @additional_info_window.clear
    on_buy_ok_yurish_a29zb
  end
  #--------------------------------------------------------------------------
  # * Sell [OK]
  #--------------------------------------------------------------------------
  alias on_sell_ok_yurish_a29zb on_sell_ok
  def on_sell_ok
    @additional_info_window.clear
    on_sell_ok_yurish_a29zb
  end
  #--------------------------------------------------------------------------
  # * Buy [Cancel]
  #--------------------------------------------------------------------------
  alias on_buy_cancel_yurish_a29zb on_buy_cancel
  def on_buy_cancel
    @additional_info_window.clear
    on_buy_cancel_yurish_a29zb
  end
  #--------------------------------------------------------------------------
  # * Sell [Cancel]
  #--------------------------------------------------------------------------
  alias on_sell_cancel_yurish_a29zb on_sell_cancel
  def on_sell_cancel
    @additional_info_window.clear
    on_sell_cancel_yurish_a29zb
  end
end