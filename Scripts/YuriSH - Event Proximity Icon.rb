# =============================================================================
# ** Event Proximity Icon
# * By YuriSH
# -----------------------------------------------------------------------------
# * UPDATES HISTORY
# -----------------------------------------------------------------------------
# * Version 1.0 (10.03.2026)
#     Initial release.
# -----------------------------------------------------------------------------
# * SCRIPT DESCRIPTION
# -----------------------------------------------------------------------------
# 
#                   !!!REQUIRES "HELPER FUNCTIONS" SCRIPT!!!
#                   !!!     OF VERSION 1.1 OR ABOVE      !!!
#
# This script allows you to show an icon above an event that will fade in and
# out depending in player's distance to the event.
# You can also give it a "bobbing" animation.
# -----------------------------------------------------------------------------
# * SCRIPT CALLS
# -----------------------------------------------------------------------------
# To assign an icon to an event, use the following script call:
#
# * set_icon(event_id, id, offset, dist_min, dist_max, freq, ampl)
#     event_id - ID of the event you want to assign the icon to.
#                If -1 is passed, will use current event's ID.
#           id - ID of the icon.
#       offset - Offset of the icon image (in pixels).
#                Positive numbers will move the icon downwards, negative
#                numbers will move it upwards.
#                (default: 0)
#     dist_min - distance from player to event (in pixels) at which the icon
#                will be fully visible.
#                (default: 32)
#     dist_max - distance from player to event (in pixels) at which the icon
#                will be fully transparent.
#                (default: 128)
#         freq - frequency of the "bobbing" animation (in seconds).
#                (default: 1.0)
#         ampl - amplitude of the "bobbing" animation.
#                (default: 1.0)
#            
# The icon will be disabled by default.
# To actually enable (or disable) the icon, use the following script call:
#
# * toggle_icon(event_id, enable)
#     event_id - ID of the event you want to toggle the icon for.
#       enable - true if you want to enable the icon, or false if you want
#                to disable it.
#
# Icon can be removed completely by assigning icon with negative ID
# (-1 for example).
# -----------------------------------------------------------------------------
# * EXAMPLES
# -----------------------------------------------------------------------------
# * set_icon(8, 16)
#     Will assign icon ID 16 to event ID 8, the rest of the parameter will be
#     left as default.
#
# * set_icon(8, -1)
#     Assigns icon ID -1 to event ID 8. This will remove the icon altogether.
#
# * set_icon(8, 16, 12, 64, 256, 3.0, 3.0)
#     Will assign icon ID 16 to event ID 8, with offset of 12 pixels,
#     minimal distance of 64 pixels, maximal distance of 256 pixels,
#     frequency of 3.0 seconds and amplitude of 3.0.
#
# * toggle_icon(8, true)
#     Will enable the icon for event ID 8.
#
# * toggle_icon(16, false)
#     Will disable the icon for event ID 16.
# =============================================================================

$imported = {} if $imported.nil?
$imported["YuriSH_EventIcon"] = true

if $imported.key?("YuriSH_HelperFunctions")
  ver = $imported["YuriSH_HelperFunctions"]
  unless ver >= 1.1
    msgbox('"Helper Functions" script must be of version 1.1 or above.')
    exit
  end
else
  msgbox('"Helper Functions" script missing.')
  exit
end

#==============================================================================
# ** Game_Interpreter
#==============================================================================

class Game_Interpreter
  #----------------------------------------------------------------------------
  # * Sets Icon For Event ID
  #----------------------------------------------------------------------------
  def set_icon(evt_id, icon_id, offset = 0, dist_min = 32, dist_max = 128, freq = 1.0, ampl = 1.0)
    evt_id = @event_id if evt_id < 0
    $game_map.events[evt_id].set_icon(icon_id, offset, dist_min, dist_max, freq, ampl)
  end
  #----------------------------------------------------------------------------
  # * Toggle Icon For Event ID
  #----------------------------------------------------------------------------
  def toggle_icon(evt_id, value = false)
    evt_id = @event_id if evt_id < 0
    $game_map.events[evt_id].toggle_icon(value)
  end
end

#==============================================================================
# ** Game_Character
#==============================================================================

class Game_Character < Game_CharacterBase
  #----------------------------------------------------------------------------
  # * Public Instance Variables
  #----------------------------------------------------------------------------
  attr_accessor :icon_enabled         # Icon Enabled
  attr_accessor :icon_id              # Icon ID
  attr_accessor :icon_offset          # Icon offset (in pixels)
  attr_accessor :icon_range           # Icon Range (in pixels)
  attr_accessor :icon_amplitude       # Icon Bounce Amplitude
  attr_accessor :icon_frequency       # Icon Bounce Frequency
  #--------------------------------------------------------------------------
  # * Initialize Public Member Variables
  #--------------------------------------------------------------------------
  alias init_public_members_yurish_evicon init_public_members
  def init_public_members
    init_public_members_yurish_evicon
    @icon_enabled = false
    @icon_id = -1
    @icon_offset = 0
    @icon_range = [128, 32]
    @icon_amplitude = 1.0
    @icon_frequency = 1.0
  end
  #--------------------------------------------------------------------------
  # * Set Icon Data
  #--------------------------------------------------------------------------
  def set_icon(icon_id, offset = 0, dist_min = 32, dist_max = 128, freq = 1.0, ampl = 1.0)
    @icon_id = icon_id
    @icon_offset = offset
    @icon_range = [ [dist_min, dist_max].max, [dist_min, dist_max].min ]
    @icon_frequency = freq
    @icon_amplitude = ampl
  end
  #--------------------------------------------------------------------------
  # * Toggles Icon
  #--------------------------------------------------------------------------
  def toggle_icon(value = false)
    @icon_enabled = value
  end
end

#==============================================================================
# ** Sprite_Character
#==============================================================================

class Sprite_Character < Sprite_Base
  #--------------------------------------------------------------------------
  # * Free
  #--------------------------------------------------------------------------
  alias dispose_yurish_evicon dispose
  def dispose
    dispose_icon
    dispose_yurish_evicon
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  alias update_yurish_evicon update
  def update
    update_yurish_evicon
    update_icon
  end
  #--------------------------------------------------------------------------
  # * Set New Effect
  #--------------------------------------------------------------------------
  alias setup_new_effect_yurish_evicon setup_new_effect
  def setup_new_effect
    setup_new_effect_yurish_evicon
    if !@icon_sprite && @character.icon_id >= 0
      start_icon
    end
  end
  #--------------------------------------------------------------------------
  # * Start Icon Display
  #--------------------------------------------------------------------------
  def start_icon
    dispose_icon
    @icon_sprite = ::Sprite.new(viewport)
    @icon_sprite.bitmap = Cache.system("Iconset")
    @icon_sprite.ox = 12
    @icon_sprite.oy = 24
    update_icon
  end
  #--------------------------------------------------------------------------
  # * Update Icon
  #--------------------------------------------------------------------------
  def update_icon
    if @character.icon_id >= 0
      if @character.icon_enabled
        @icon_sprite.visible = true
        @icon_sprite.x = x
        @icon_sprite.y = y - height + @character.icon_offset + YuriSH.wave(@character.icon_frequency, @character.icon_amplitude)
        @icon_sprite.z = z + 200
        sx = @character.icon_id % 16 * 24
        sy = @character.icon_id / 16 * 24
        @icon_sprite.src_rect.set(sx, sy, 24, 24)
        distance = dist
        if distance > @character.icon_range[0] or distance < 0
          @icon_sprite.opacity = 0
        elsif distance < @character.icon_range[1]
          @icon_sprite.opacity = 255
        else
          @icon_sprite.opacity = 255 - YuriSH.remap(distance, @character.icon_range[1], @character.icon_range[0], 0, 255)
        end
      else
        @icon_sprite.visible = false
      end
    else
      dispose_icon
    end
  end
  #--------------------------------------------------------------------------
  # * Distance Between Character And Player
  #--------------------------------------------------------------------------
  def dist
    if character.nil? or $game_player.nil?
      return -1
    else
      x1,y1 = character.screen_x, character.screen_y
      x2,y2 = $game_player.screen_x, $game_player.screen_y
      return YuriSH.distance(x1,y1,x2,y2)
    end
  end
  #--------------------------------------------------------------------------
  # * Free Icon
  #--------------------------------------------------------------------------
  def dispose_icon
    if @icon_sprite
      @icon_sprite.dispose
      @icon_sprite = nil
    end
  end
end