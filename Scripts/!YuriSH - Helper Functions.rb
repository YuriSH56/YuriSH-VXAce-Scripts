# =============================================================================
# ** Helper Functions
# * By YuriSH
# -----------------------------------------------------------------------------
# This script includes some code snippets shared among other scripts of mine.
# Some scripts REQUIRE this one to work.
#
# This script must be placed BEFORE any other scripts that require it.
# =============================================================================

$imported = {} if $imported.nil?
$imported["YuriSH_HelperFunctions"] = true

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