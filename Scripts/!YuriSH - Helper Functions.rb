# =============================================================================
# ** Helper Functions (Version 1.0)
# * By YuriSH
# -----------------------------------------------------------------------------
# * UPDATES HISTORY
# -----------------------------------------------------------------------------
# * Version 1.0 (05.09.2026)
#     Initial release.
#     Added framework for event tag scan.
#     Added commands for getting window contents rect position on screen.
#     Added commands for getting center coordinate for Window_Selectable item
#       on screen.
#     Added "last_pos" to Window_Base that keeps last position of processed
#       character.
#     Exposed Game_Interpreter parameters.
# -----------------------------------------------------------------------------
# * SCRIPT DESCRIPTION
# -----------------------------------------------------------------------------
# This script includes some code snippets shared among other scripts of mine.
# Some scripts REQUIRE this one to work.
#
# This script must be placed BEFORE any other scripts that require it.
# =============================================================================

$imported = {} if $imported.nil?
$imported["YuriSH_HelperFunctions"] = 1.0

module YuriSH
  # Limits amount of event commands to scan.
  # By default, scans first 5 commands.
  # Increasing this number may cause lag if you have a lot of events on a map
  # with many commands on its first page.
  # NOTE: EACH LINE INSIDE A COMMENT COUNTS AS A SEPARATE COMMAND!!!
  CMD_LIMIT = 5
end

#==============================================================================
# ** Game_Interpreter
#==============================================================================

class Game_Interpreter
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_accessor :params # Command parameters
end

#==============================================================================
# ** Game_Event
#==============================================================================

class Game_Event < Game_Character
  #--------------------------------------------------------------------------
  # * Object Initialization
  #     event:  RPG::Event
  #--------------------------------------------------------------------------
  alias initialize_yurish_helper initialize
  def initialize(map_id, event)
    @last_scanned_page = nil
    init_pre_scan
    initialize_yurish_helper(map_id, event)
    scan_for_tags(event.pages[0])
  end
  #--------------------------------------------------------------------------
  # * Refresh
  #--------------------------------------------------------------------------
  alias refresh_yurish_helper refresh
  def refresh
    refresh_yurish_helper
    scan_for_tags(@page) if @page
  end
  #--------------------------------------------------------------------------
  # * Called Before Tag Scan Runs
  #   Alias This Method if You Need To Initialize Something Before Tag Scan
  #--------------------------------------------------------------------------
  def init_pre_scan
  end
  #--------------------------------------------------------------------------
  # * Scans Provided List Of Event Comands for Comments With Possible Tags
  #     page: RPG::Event::Page
  #--------------------------------------------------------------------------
  def scan_for_tags(page)
    return unless page
    return if @last_scanned_page == page
    @last_scanned_page = page
    page.list.select { |c| c.code == 108 || c.code == 408 }[0..YuriSH::CMD_LIMIT-1].each do |c|
      parse_comment(c.parameters[0])
    end
  end
  #--------------------------------------------------------------------------
  # * Parses Comment String For Tags
  #   Alias This Method To Parse Your Own Tags
  #--------------------------------------------------------------------------
  def parse_comment(comment)
  end
end

#==============================================================================
# ** Window_Base
#==============================================================================

class Window_Base < Window
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_reader   :last_pos                # Last position of draw_text_ex
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  alias initialize_yurish_helper initialize
  def initialize(x, y, width, height)
    @last_pos = {:x => 0, :y => 0, :new_x => 0, :height => 0}
    initialize_yurish_helper(x, y, width, height)
  end
  #--------------------------------------------------------------------------
  # * Character Processing
  #     c    : Characters
  #     text : A character string buffer in drawing processing (destructive)
  #     pos  : Draw position {:x, :y, :new_x, :height}
  #--------------------------------------------------------------------------
  alias process_character_yurish_helper process_character 
  def process_character(c, text, pos)
    process_character_yurish_helper(c, text, pos)
    @last_pos = pos
  end
  #--------------------------------------------------------------------------
  # * Screen X Coordinate of Window's Contents
  #--------------------------------------------------------------------------
  def contents_x
    x + standard_padding
  end
  #--------------------------------------------------------------------------
  # * Screen Y Coordinate of Window's Contents
  #--------------------------------------------------------------------------
  def contents_y
    y + standard_padding
  end
end

#==============================================================================
# ** Window_Selectable
#==============================================================================

class Window_Selectable < Window_Base
  #--------------------------------------------------------------------------
  # * Screen X Coordinate of Item's Center
  #--------------------------------------------------------------------------
  def center_x(index)
    r = item_rect(index)
    res = r.x + r.width / 2 + contents_x - ox
    res
  end
  #--------------------------------------------------------------------------
  # * Screen Y Coordinate of Item's Center
  #--------------------------------------------------------------------------
  def center_y(index)
    r = item_rect(index)
    res = r.y + r.height / 2 + contents_y - oy
    res
  end
end