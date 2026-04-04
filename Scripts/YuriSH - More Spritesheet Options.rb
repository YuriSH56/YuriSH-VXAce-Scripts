# =============================================================================
# ** More Spritesheet Options
# * By YuriSH
# -----------------------------------------------------------------------------
# This script changes how special symbols in sprite names are interpreted.
# Only first 2 characters are checked for symbols.
# List of symbols:
# MUTUALLY EXCLUSIVE:
#   "!" - CHANGED: this tag treats sprite as a single image now.
#   "$" - unchanged. Treats image as a 3x4 spritesheet.
#   If neither are present - image is treated
#   as a 4x2 set of "$" spritesheets (unchanged behavior).
# OTHER:
#   "@" - NEW: will shift sprite downwards by 2 pixels
# =============================================================================

$imported = {} if $imported.nil?
$imported["YuriSH_MoreSpritesheetOptions"] = true

#==============================================================================
# ** Game_CharacterBase
#==============================================================================

class Game_CharacterBase
  #--------------------------------------------------------------------------
  # * Determine Object Character
  #--------------------------------------------------------------------------
  def object_character?
    @tile_id > 0
  end
  #--------------------------------------------------------------------------
  # * Determine If Object Should Sink Into Ground
  #--------------------------------------------------------------------------
  def should_sink?
    @character_name[0, 2].include?('@')
  end
  #--------------------------------------------------------------------------
  # * Get Number of Pixels to Shift Up from Tile Position
  # * If it has "@" in its name, sprite is offset by -2
  # * Otherwise offset is set to 0
  #--------------------------------------------------------------------------
  def shift_y
    should_sink? ? -2 : 0
  end
end

#==============================================================================
# ** Sprite_Character
#==============================================================================

class Sprite_Character < Sprite_Base
  #--------------------------------------------------------------------------
  # * Set Character Bitmap
  #--------------------------------------------------------------------------
  def set_character_bitmap
    self.bitmap = Cache.character(@character_name)
    sign = @character_name[0, 2]
    if sign.include?('$')
      @cw = bitmap.width / 3
      @ch = bitmap.height / 4
    elsif sign.include?("!")
      @cw = bitmap.width
      @ch = bitmap.height
    else
      @cw = bitmap.width / 12
      @ch = bitmap.height / 8
    end
    self.ox = @cw / 2
    self.oy = @ch
  end
end

#==============================================================================
# ** Window_Base
#==============================================================================

class Window_Base < Window
  #--------------------------------------------------------------------------
  # * Draw Character Graphic
  #--------------------------------------------------------------------------
  def draw_character(character_name, character_index, x, y)
    return unless character_name
    bitmap = Cache.character(character_name)
    sign = @character_name[0, 2]
    if sign.include?('$')
      @cw = bitmap.width / 3
      @ch = bitmap.height / 4
    elsif sign.include?("!")
      @cw = bitmap.width
      @ch = bitmap.height
    else
      @cw = bitmap.width / 12
      @ch = bitmap.height / 8
    end
    n = character_index
    src_rect = Rect.new((n%4*3+1)*cw, (n/4*4)*ch, cw, ch)
    contents.blt(x - cw / 2, y - ch, bitmap, src_rect)
  end
end