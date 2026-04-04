#==============================================================================
# Sprite Replacement Hack by YuriSH
#------------------------------------------------------------------------------
# Lets you load a different character graphic so you don't have to
# edit every single event.
#==============================================================================

$imported = {} if $imported.nil?
$imported["YuriSH_SpriteReplaceHack"] = true

module YuriSH
  
  # Add new entries to this list.
  # Left is file to replace, right is what it will be replaced with.
  # Both file names must be without file extensions. (no .png)
  # Comma at the end is NECESSARY.
  REPLACEMENT_MAP = {
    "Brad" => "$$John Skate",
  }

  #--------------------------------------------------------------------------
  # * Replace
  #     Helper function that takes original parameters and returns
  #     replacements if required.
  #--------------------------------------------------------------------------
  def self.replace(character_name, character_index)
    if REPLACEMENT_MAP.include?(character_name)
      sign_og = character_name[/^\$?/]
      sign_replace = REPLACEMENT_MAP[character_name][/^\$?/]
      if sign_og != sign_replace
        return REPLACEMENT_MAP[character_name], 0
      else
        return REPLACEMENT_MAP[character_name], character_index
      end
    else
      return character_name, character_index
    end
  end
end

class Game_CharacterBase
  #--------------------------------------------------------------------------
  # * Change Graphics
  #     character_name  : new character graphic filename
  #     character_index : new character graphic index
  #--------------------------------------------------------------------------
  def set_graphic(character_name, character_index)
    @tile_id = 0
    @character_name, @character_index = YuriSH::replace(character_name, character_index)
    @original_pattern = 1
  end
end

class Game_Actor < Game_Battler
  #--------------------------------------------------------------------------
  # * Change Graphics
  #--------------------------------------------------------------------------
  def set_graphic(character_name, character_index, face_name, face_index)
    @character_name, @character_index = YuriSH::replace(character_name, character_index)
    @face_name = face_name
    @face_index = face_index
  end
end