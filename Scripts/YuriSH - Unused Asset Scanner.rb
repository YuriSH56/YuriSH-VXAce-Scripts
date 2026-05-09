# =============================================================================
# ** Unused Asset Scanner
# * By YuriSH
# -----------------------------------------------------------------------------
# * UPDATES HISTORY
# -----------------------------------------------------------------------------
# * Version 1.0 (05.09.2026)
#     Initial release.
# -----------------------------------------------------------------------------
# * SCRIPT DESCRIPTION
# -----------------------------------------------------------------------------
# This script scans your ENTIRE project for any unused assets.
# The result is written to "ScanResult.txt" and placed in project's root folder.
# The game will close itself after scanning process is done.
#
# NOTE: This script will do nothing if project isn't started in Playtest mode.
#
# NOTE: This script does NOT scan any assets used in scripts or script calls.
# You have to check for those manually.
# =============================================================================

$imported = {} if $imported.nil?
$imported["YuriSH_Scanner"] = true

module YuriSH
  module Scan
    
    # Set this to false to disable.
    ENABLE = true
    
    # ====================\/\/ DO NOT CHANGE ANYTING \/\/==================== #
    # ====================\/\/   BEYOND THAT POINT   \/\/==================== #
    
    # store used audio files
    @bgm  = []
    @bgs  = []
    @me   = []
    @se   = []
    # store found images
    @animations = []
    @battlers   = []
    @characters = []
    @tilesets   = []
    @faces      = []
    @parallaxes = []
    @pictures   = []
    @battleback1= []
    @battleback2= []
    @title1     = []
    @title2     = []
    
    # removes empty values and duplicates
    def self.remove_empty_or_dups
      d = [@bgm, @bgs, @me, @se, @animations, @battlers, @characters,
        @tilesets, @faces, @parallaxes, @pictures, @battleback1,
        @battleback2, @title1, @title2]
      d.each do |item|
        item = item.flatten
        item = item.uniq
        item = item.compact
        item = item.reject { |x| x.empty? }
      end
    end
    
    # goes through all assets and checks which ones are not used
    def self.check_unused
      d = [
        ["Graphics/Animations",    "ANIMATIONS",   @animations],
        ["Graphics/Battlebacks1",  "BATTLEBACKS1", @battleback1],
        ["Graphics/Battlebacks2",  "BATTLEBACKS2", @battleback2],
        ["Graphics/Battlers",      "BATTLERS",     @battlers],
        ["Graphics/Characters",    "CHARACTERS",   @characters],
        ["Graphics/Faces",         "FACES",        @faces],
        ["Graphics/Parallaxes",    "PARALLAXES",   @parallaxes],
        ["Graphics/Pictures",      "PICTURES",     @pictures],
        ["Graphics/Tilesets",      "TILESETS",     @tilesets],
        ["Graphics/Titles1",       "TITLES1",      @title1],
        ["Graphics/Titles2",       "TITLES2",      @title2],
        ["Audio/BGM",              "BGM",          @bgm],
        ["Audio/BGS",              "BGS",          @bgs],
        ["Audio/ME",               "ME",           @me],
        ["Audio/SE",               "SE",           @se],
      ]
      res = []
      f = File.open("ScanResult.txt", "w")
      f.write("SCAN RESULT:\n====================\n\n")
      f.flush
      d.each do |data|
        Dir.foreach(data[0]) do |entry|
          next if entry == "."
          next if entry == ".."
          res.push(entry) unless data[2].include?(entry.split(".")[0])
        end
        f.write("UNUSED " + data[1] + " (#{res.size})" +":\n")
        res.each do |item|
          f.write(item+"\n")
        end
        f.write("\n")
        f.flush
        res = []
      end
      f.write("SCAN END")
      f.flush
      f.close
    end
    
    # parses move route commands
    def self.move_route(route)
      route.list.each do |cmd|
        if cmd.code == 44
          @se.push(cmd.parameters[0].name) if cmd.parameters[0]
        end
        if cmd.code == 41
          @characters.push(cmd.parameters[0]) unless cmd.parameters[0].empty?
        end
      end
    end
    
    # parses all data files
    def self.parse_data_files
      $data_actors.each do |actor|
        next if actor.nil?
        @characters.push(actor.character_name) unless actor.character_name.empty?
        @faces.push(actor.face_name) unless actor.face_name.empty?
      end
      $data_enemies.each do |enemy|
        next if enemy.nil?
        @battlers.push(enemy.battler_name) unless enemy.battler_name.empty?
      end
      $data_animations.each do |anim|
        next if anim.nil?
        @animations.push(anim.animation1_name) unless anim.animation1_name.empty?
        @animations.push(anim.animation2_name) unless anim.animation2_name.empty?
        anim.timings.each do |timing|
          @se.push(timing.se.name) if timing.se
        end
      end
      $data_tilesets.each do |tileset|
        next if tileset.nil?
        tileset.tileset_names.each do |t_name|
          @tilesets.push(t_name) unless t_name.empty?
        end
      end
      $data_common_events.each do |c_ev|
        next if c_ev.nil?
        parse_event_list(c_ev.list)
      end
      $data_troops.each do |troop|
        next if troop.nil?
        troop.pages.each do |page|
          parse_event_list(page.list)
        end
      end
      @battlers.push($data_system.battler_name) unless $data_system.battler_name.empty?
      @battleback1.push($data_system.battleback1_name) unless $data_system.battleback1_name.empty?
      @battleback2.push($data_system.battleback2_name) unless $data_system.battleback2_name.empty?
      @title1.push($data_system.title1_name) unless $data_system.title1_name.empty?
      @title2.push($data_system.title2_name) unless $data_system.title2_name.empty?
      @characters.push($data_system.boat.character_name) unless $data_system.boat.character_name.empty?
      @characters.push($data_system.ship.character_name) unless $data_system.ship.character_name.empty?
      @characters.push($data_system.airship..character_name) unless $data_system.airship.character_name.empty?
      @bgm.push($data_system.title_bgm.name) if $data_system.title_bgm
      @bgm.push($data_system.battle_bgm.name) if $data_system.battle_bgm
      @me.push($data_system.battle_end_me.name) if $data_system.battle_end_me
      @me.push($data_system.gameover_me.name) if $data_system.gameover_me
      $data_system.sounds.each do |sound|
        @se.push(sound.name) if sound
      end
    end
    
    # parses event list
    def self.parse_event_list(list)
      list.each do |item|
        if item.code == 132
          @bgm.push(item.parameters[0].name) if item.parameters[0]
        end
        if item.code == 133
          @me.push(item.parameters[0].name) if item.parameters[0]
        end
        if item.code == 205
          move_route(item.parameters[1])
        end
        if item.code == 231
          @pictures.push(item.parameters[1]) unless item.parameters[1].empty?
        end
        if item.code == 241
          @bgm.push(item.parameters[0].name) if item.parameters[0]
        end
        if item.code == 245
          @bgs.push(item.parameters[0].name) if item.parameters[0]
        end
        if item.code == 249
          @me.push(item.parameters[0].name) if item.parameters[0]
        end
        if item.code == 250
          @se.push(item.parameters[0].name) if item.parameters[0]
        end
        if item.code == 283
          @battleback1.push(item.parameters[0])
          @battleback2.push(item.parameters[1])
        end
        if item.code == 284
          @parallaxes.push(item.parameters[0]) unless item.parameters[0].empty?
        end
        if item.code == 322
          @characters.push(item.parameters[1]) unless item.parameters[1].empty?
          @faces.push(item.parameters[3]) unless item.parameters[3].empty?
        end
        if item.code == 323
          @characters.push(item.parameters[1]) unless item.parameters[1].empty?
        end
      end
    end
    
    def self.start
      msgbox('Scanning project for unused assets...')
      # loads all database data
      DataManager.load_normal_database
      # parse database files
      parse_data_files
      #go through all maps
      999.times do |idx|
        map_path = sprintf("Data/Map%03d.rvdata2", idx+1)
        next unless FileTest.exist?(map_path)
        map_data = load_data(map_path)
        
        @parallaxes.push(map_data.parallax_name) unless map_data.parallax_name.empty?
        @bgm.push(map_data.bgm.name) if map_data.bgm
        @bgs.push(map_data.bgs.name) if map_data.bgs
        
        map_data.events.values.each do |event|
          event.pages.each do |page|
            unless page.graphic.character_name.empty?
              if page.graphic.tile_id > 0
                @tilesets.push(page.graphic.character_name)
              else
                @characters.push(page.graphic.character_name)
              end
            end
            parse_event_list(page.list)
          end
        end
      end
      remove_empty_or_dups
      check_unused
      temp_msg = "Scan complete.\n"
      temp_msg += 'Results saved to "ScanResult.txt".'
      msgbox(temp_msg)
      exit
    end
  end
end

if YuriSH::Scan::ENABLE && ($TEST || $BTEST)
  YuriSH::Scan.start
end