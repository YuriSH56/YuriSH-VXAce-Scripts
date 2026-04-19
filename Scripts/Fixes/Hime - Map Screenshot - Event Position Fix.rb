# =============================================================================
# ** Hime - Map Screenshot - Event Position Fix
# * By YuriSH
# -----------------------------------------------------------------------------
# * UPDATES HISTORY
# -----------------------------------------------------------------------------
# * Version 1.0 (04.19.2026)
#     Initial release.
#     Events are now properly positioned.
#     Events render in proper order.
#     Events use most fitting page instead of first page.
# -----------------------------------------------------------------------------
# This scriptlet fixes several issues presented in the original script.
#
# New functionality:
# * Adds a toggle for parallax drawing.
# * Adds a toggle for event page selection.
#
# NOTE: It is not mentioned in the script itself, so I'll put it here.
# if you change "Draw_Events" to false in original script, it will stop
# ANY events from being drawn, including events that use tilemaps for graphics.
# To draw tile events anyways, add a comment to the first event page with
# the following note tag:
# <screenshot: tile>
# =============================================================================

if $imported["TH_MapSaver"]

module TH
  module Map_Saver
    # Draw parallax?
    Draw_Parallax = false
	# If true - events will use the most fitting page to display.
	# If false - first page will be used.
	Events_Use_Most_Fitting_Page = true
  end
end

class Map_Saver
  #--------------------------------------------------------------------------
  # * Collects All Sprites, Sorts Them In Draw Order And Returns Them
  #--------------------------------------------------------------------------
  def collect_sprites_to_draw
    sprites_to_draw = []
    # Events
    @game_map.events.keys.each do |idx|
      game_event = @game_map.events[idx]
      event = @map.events[idx]
      page = TH::Map_Saver::Events_Use_Most_Fitting_Page ? game_event.find_proper_page : event.pages[0]
      next if page.nil?
      canDraw = event.pages[0].list.any? do |cmd|
        cmd.code == 108 && cmd.parameters[0] =~ /<screenshot:\s*tile\s*>/i
      end
      next unless @draw_events || canDraw
      id = page.graphic.tile_id
      char_name = page.graphic.character_name
      if id > 0
        normal_tile(id)
        sprites_to_draw.push(game_event)
      elsif char_name != ""
        sprites_to_draw.push(game_event)
      end
    end
    
    # Vehicles
    if @draw_vehicles
      $game_map.vehicles.each do |vehicle|
        next unless @map_id == vehicle.map_id
        sprites_to_draw.push(vehicle)
      end
    end
    
    # Followers
    if @draw_followers and @map_id == $game_map.map_id
      $game_player.followers.each do |follower|
        sprites_to_draw.push(follower)
      end
    end
    
    # Player
    if @draw_player and @map_id == $game_map.map_id
      sprites_to_draw.push($game_player)
    end
    
    list = {}
    sprites_to_draw.length.times do |x|
      list[sprites_to_draw[x]] = x
    end
    
    sorted_values = list.keys.sort { |a,b| custom_sort(a,b,list[a],list[b])  }
    
    return sorted_values
  end
  
  #--------------------------------------------------------------------------
  # * Function Used For Sorting
  #--------------------------------------------------------------------------
  def custom_sort(a,b,a_order,b_order)
    return -1 if a.screen_z > b.screen_z
    return 1 if a.screen_z < b.screen_z
    return -1 if a.y > b.y
    return 1 if a.y < b.y
    return -1 if a_order > b_order
    return 1 if a_order < b_order
    return 0
  end
  #--------------------------------------------------------------------------
  # * Draw map sprites
  #--------------------------------------------------------------------------
  def draw_sprites
    sprites_to_draw = collect_sprites_to_draw
    sprites_to_draw.reverse.each do |obj|
      if obj.is_a?(Game_Event)
        page = obj.find_proper_page
        id = page.graphic.tile_id
        char_name = page.graphic.character_name
        if id > 0
          normal_tile(id)
          draw_tile(obj.x, obj.y, @tilemap, @src_rect)
        else
          set_character_bitmap(page.graphic, obj.x, obj.y)
        end
      else
        set_character_bitmap(obj, obj.x, obj.y)
      end
    end
  end
  #--------------------------------------------------------------------------
  # * Draw parallax
  #--------------------------------------------------------------------------
  alias draw_parallax_yurish_fix draw_parallax
  def draw_parallax
    return unless TH::Map_Saver::Draw_Parallax
    draw_parallax_yurish_fix
  end
  #--------------------------------------------------------------------------
  # * Draw character
  #--------------------------------------------------------------------------
  def draw_character(x, y, width, height, bmp, rect)
    x2 = x * tilesize + tilesize / 2 - width / 2
    y2 = y * tilesize + tilesize - height
    @map_image.blt(x2, y2, bmp, rect)
  end
end

end