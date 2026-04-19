# =============================================================================
# ** Item Tags
# * By YuriSH
# -----------------------------------------------------------------------------
# This script implements tag system for items. It also includes a selection
# window that shows all items with specified tag you currently have.
#
# To add tags to item, add following string to its notes:
# * <tags: x1, x2, x3, ...>, where:
#     x1, x2, x3, ... - A tag. Can be any text string.
#                       Any amount of tags allowed.
#                       TAGS MUST BE SEPARATED WITH A COMMA
#                       TO BE PROPERLY RECOGNIZED.
#
# To summon the window, use script call:
# * show_tag_item_window(var_id, type_var_id, tag1, tag2, ...), where:
#     var_id          - ID of a variable that will store selected item's ID.
#                       If no item is selected, it will be 0.
#     type_var_id     - ID of a variable that will store selected item's type.
#                       can be any of the following symbols:
#                           :item   - common item.
#                           :armor  - armor piece.
#                           :weapon - weapon piece.
#                           :none   - none type (when no item is selected).
#     tag1, tag2, ... - List of tags. Can be any amount of tags.
#                       Each item must have ALL of the specified tags to
#                       show up in the window.
#
# This script call will ONLY work on maps.
# =============================================================================

$imported = {} if $imported.nil?
$imported["YuriSH_ItemTags"] = true

# =============================================================================
# CONFIGURATION BEGIN
# =============================================================================

module YuriSH
  module ItemTags
    # =============== DO NOT CHANGE THIS =============== #
    REGEX       = /<tags: ?(.+)>/i
    TYPE_ITEM   = :item
    TYPE_ARMOR  = :armor
    TYPE_WEAPON = :weapon
    TYPE_NONE   = :none
    # =============== DO NOT CHANGE THIS =============== #
    NULL_ITEM_TEXT = "Nothing..."   # Text to show if no items in list
    NULL_ITEM_ICON = 17             # Icon for text above
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
  # * Get Tags
  # ---------------------------------------------------------------------------
  def tags
    if @tags.nil?
      @tags = (@note =~ YuriSH::ItemTags::REGEX ? split_tags($1) : [])
    end
    return @tags
  end
  # ---------------------------------------------------------------------------
  # * Set Tags
  # ---------------------------------------------------------------------------
  def tags=(*args)
    args.flatten!
    args.collect! { |x| x.downcase }
    @tags = args
    @tags.uniq!
  end
  # ---------------------------------------------------------------------------
  # * Split String Of Tags To Array
  # ---------------------------------------------------------------------------
  def split_tags(tags_string)
    res = []
    tags_string.split(",").each do |x|
      res.push(x.strip.downcase)
    end
    return res.uniq
  end
  # ---------------------------------------------------------------------------
  # * Returns True IF Item Has Specified Tags
  # ---------------------------------------------------------------------------
  def tag?(*args)
    args.flatten!
    args.collect! { |x| x.downcase }
    args.each do |x|
      return false unless tags.include?(x)
    end
    return true
  end
end

#==============================================================================
# ** Window_TagItemList
#------------------------------------------------------------------------------
#  This window displays a list of party items of specific tags.
#==============================================================================

class Window_TagItemList < Window_ItemList
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_reader   :tags   # list of tags
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize(x, y, width, height, tags = [], cols = 1)
    tags.collect! { |x| x.downcase }
    @tags = tags
    @columns_to_show = cols
    super(x, y, width, height)
    self.openness = 0
  end
  #--------------------------------------------------------------------------
  # * Set Tags
  #--------------------------------------------------------------------------
  def tags=(tag_array = [])
    tag_array.collect! { |x| x.downcase }
    @tags = tag_array
    @tags.uniq!
    refresh
  end
  #--------------------------------------------------------------------------
  # * Get Digit Count
  #--------------------------------------------------------------------------
  def col_max
    return @columns_to_show
  end
  #--------------------------------------------------------------------------
  # * Include in Item List?
  #--------------------------------------------------------------------------
  def include?(item)
    return ((item.is_a?(RPG::Item) or item.is_a?(RPG::EquipItem)) and item.tag?(tags))
  end
  #--------------------------------------------------------------------------
  # * Display in Enabled State?
  #--------------------------------------------------------------------------
  def enable?(item)
    return !item.nil?
  end
  #--------------------------------------------------------------------------
  # * Draw Null Item
  #-------------------------------------------------------------------------- 
  def draw_null_item(x, y, enabled = true, width = 172)
    draw_icon(YuriSH::ItemTags::NULL_ITEM_ICON, x, y, enabled)
    change_color(normal_color, enabled)
    draw_text(x + 24, y, width, line_height, YuriSH::ItemTags::NULL_ITEM_TEXT)
  end
  #--------------------------------------------------------------------------
  # * Refresh
  #--------------------------------------------------------------------------
  def refresh
    super
    if @data.empty?
      rect = item_rect(0)
      rect.width -= 4
      draw_null_item(rect.x, rect.y, false)
    end
  end
end

#==============================================================================
# ** Scene_Map
#==============================================================================

class Scene_Map < Scene_Base
  #--------------------------------------------------------------------------
  # * Start Processing
  #--------------------------------------------------------------------------
  alias start_yurish_5z2aq start
  def start
    start_yurish_5z2aq
    @tag_item_selecting = false
    @tag_var_id = 0
    @tag_var_type_id = 0
  end
  #--------------------------------------------------------------------------
  # * Create All Windows
  #--------------------------------------------------------------------------
  alias create_all_windows_yurish_5z2aq create_all_windows
  def create_all_windows
    create_all_windows_yurish_5z2aq
    create_help_window
    create_tag_item_list_window
  end
  #--------------------------------------------------------------------------
  # * Create Help Window
  #--------------------------------------------------------------------------
  def create_help_window
    @help_window = Window_Help.new
    @help_window.openness = 0
    @help_window.viewport = @viewport
  end
  #--------------------------------------------------------------------------
  # * Create Tag Item List Window
  #--------------------------------------------------------------------------
  def create_tag_item_list_window
    ww = Graphics.width - 100
    wh = Graphics.height - @help_window.fitting_height(2)
    wx = 50
    wy = @help_window.y + @help_window.height
    @tag_item_list_window = Window_TagItemList.new(wx, wy, ww, wh)
    @tag_item_list_window.viewport = @viewport
    @tag_item_list_window.help_window = @help_window
    @tag_item_list_window.set_handler(:ok,     method(:on_tag_item_ok))
    @tag_item_list_window.set_handler(:cancel, method(:on_tag_item_cancel))
  end
  #--------------------------------------------------------------------------
  # * Call Tag Item List Window
  #--------------------------------------------------------------------------
  def call_tag_item_list_window(var_id, var_type, tags = [])
    @tag_var_id = var_id
    @tag_var_type_id = var_type

    @tag_item_list_window.tags = tags
    @tag_item_list_window.open
    @tag_item_list_window.activate
    @tag_item_list_window.select_last
    @help_window.open
    @tag_item_selecting = true
  end
  #--------------------------------------------------------------------------
  # * On [OK] In Tag Item List Window
  #--------------------------------------------------------------------------
  def on_tag_item_ok
    get_data_from_item(@tag_item_list_window.item)
    close_tag_windows
  end
  #--------------------------------------------------------------------------
  # * Gets Data From Item Into Designated Variables
  #--------------------------------------------------------------------------
  def get_data_from_item(item)
    return if (@tag_var_type_id <= 0 or @tag_var_id <= 0)
    if item
      if item.is_a?(RPG::Item)
        $game_variables[@tag_var_type_id] = YuriSH::ItemTags::TYPE_ITEM
      elsif item.is_a?(RPG::Armor)
        $game_variables[@tag_var_type_id] = YuriSH::ItemTags::TYPE_ARMOR
      elsif item.is_a?(RPG::Weapon)
        $game_variables[@tag_var_type_id] = YuriSH::ItemTags::TYPE_WEAPON
      else
        $game_variables[@tag_var_type_id] = YuriSH::ItemTags::TYPE_NONE
        $game_variables[@tag_var_id] = 0
        return
      end
      $game_variables[@tag_var_id] = item.id
    else
      $game_variables[@tag_var_type_id] = YuriSH::ItemTags::TYPE_NONE
      $game_variables[@tag_var_id] = 0
    end
  end
  #--------------------------------------------------------------------------
  # * On [Cancel] In Tag Item List Window
  #--------------------------------------------------------------------------
  def on_tag_item_cancel
    get_data_from_item(nil)
    close_tag_windows
  end
  #--------------------------------------------------------------------------
  # * Tag Item Window Active?
  #--------------------------------------------------------------------------
  def tag_item_window_active?
    return (@tag_item_selecting or !@tag_item_list_window.close?)
  end
  #--------------------------------------------------------------------------
  # * Close Tag Windows
  #--------------------------------------------------------------------------
  def close_tag_windows
    @tag_item_list_window.close
    @help_window.close
    @tag_item_selecting = false
  end
end

#==============================================================================
# ** Game_Interpreter
#==============================================================================

class Game_Interpreter
  #--------------------------------------------------------------------------
  # * Show Tag Item Window
  #--------------------------------------------------------------------------
  def show_tag_item_window(var_id, var_type, *args)
    s_scene = SceneManager.scene
    if s_scene.is_a?(Scene_Map)
      s_scene.call_tag_item_list_window(var_id, var_type, args)
      Fiber.yield while s_scene.tag_item_window_active?
    end
  end
  #--------------------------------------------------------------------------
  # * Get Item Object From Its ID And Type
  #--------------------------------------------------------------------------
  def get_item_object(var_id, var_type)
    return nil if (var_id <= 0 or var_type <= 0)
    t_type = $game_variables[var_type]
    t_var = $game_variables[var_id]
    case t_type
    when YuriSH::ItemTags::TYPE_ITEM
      return $data_items[t_var]
    when YuriSH::ItemTags::TYPE_ARMOR
      return $data_armors[t_var]
    when YuriSH::ItemTags::TYPE_WEAPON
      return $data_weapons[t_var]
    else
      return nil
    end
  end
end