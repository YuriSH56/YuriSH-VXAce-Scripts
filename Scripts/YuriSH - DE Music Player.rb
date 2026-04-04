# =============================================================================
# ** DE Music Player
# * By YuriSH
# -----------------------------------------------------------------------------
# * UPDATES HISTORY
# -----------------------------------------------------------------------------
# * Version 1.0 (03.23.2026)
#     Initial release.
#
# * Version 1.1 (03.25.2026)
#     Unlock mode and global saving added.
#
# * Version 1.1.1 (03.26.2026)
#     Cleaning up.
#     Added more customization options.
#
# -----------------------------------------------------------------------------
# * SCRIPT DESCRIPTION
# -----------------------------------------------------------------------------
# This script adds a music player like one in Definitive Edition.
# You can specify any track you would like from the project's BGM folder.
# 
#                  !!!ONLY OGG AND WAV FILES ARE SUPPORTED!!!
#            Other files will appear greyed out and will be disabled.
#
# -----------------------------------------------------------------------------
# * CONTROLS
# -----------------------------------------------------------------------------
# * To play a track, just select it from the list.
# * To pause currently playing track, select the same track again. Select it
#   again to resume playback.
# * Pressing LEFT/RIGHT arrow keys during playback will skip
#   5 seconds backward/forward respectively.
# * While holding SHIFT, pressing LEFT/RIGHT arrow keys with decrease/increase
#   volume by 5 points respectively.
# * While holding CTRL, pressing LEFT/RIGHT arrow keys with decrease/increase
#   pitch by 5 points respectively.
# -----------------------------------------------------------------------------
# * UNLOCK MODE
# -----------------------------------------------------------------------------
# If "UNLOCK_MODE" is set to "true" - you will be able to change music player
#   into some sort of a collectible system, but for music.
# There is a new global variable - "$game_music_player", that has methods
#   for locking and unlocking music. Those are:
#
# * $game_music_player.unlock(id1, id2, id3, ...), where:
#     id1, id2, id3, ... - Numbers that represent each that by its ID from the
#     list below. You can unlock as many tracks in one script call as you like.
# Example:
# $game_music_player.unlock(1,3,4) - Unlocks tracks with IDs 1,3 and 4.
#
# * $game_music_player.lock(id1, id2, id3, ...), where:
#     id1, id2, id3, ... - Same as in "unlock", but will lock tracks instead.
# Example:
# $game_music_player.lock(2,7) - Locks tracks with IDs 2 and 7.
#
# * $game_music_player.unlocked?(id) - Returns "true" if track is unlocked.
#
# * $game_music_player.save - Save current unlock progress to file. Don't call
#     this too often. By default, progress is saved each time
#     your game is saved.
#
# WARNING: "$game_music_player" IS NOT DEFINED IF "UNLOCK_MODE" IS FALSE.
# THE GAME WILL CRASH WHEN TRYING TO ACCESS THIS VARIABLE.
# =============================================================================

$imported = {} if $imported.nil?
$imported["YuriSH_DEMusicPlayer"] = true

# =============================================================================
# CONFIGURATION BEGIN
# =============================================================================

module YuriSH
  module Const
    module MusicPlayer
      # =============== DO NOT CHANGE THIS =============== #
      VXACE_HZ_RATE = 176400    # Sample Rate VXAce Uses
      DATA_PATH     = "MusicPlayer.rvdata2" # Data File Name
      # =============== DO NOT CHANGE THIS =============== #

      UNLOCK_MODE   = false     # Enables Track Unlocking
      LOCKED_NAME   = "???"     # Locked Track Name
      
      DEFAULT_RATE  = 44100     # Default Sample Rate
      
      PLAY_ICON     = 288       # Play Button Icon
      PAUSE_ICON    = 289       # Pause Button Icon
      MINUS_ICON    = 290       # Minus Volume Icon
      PLUS_ICON     = 291       # Plus Volume Icon
      
      ID_COLOR      = 9         # Track ID Color
      MAIN_GAUGE    = [9, 1]    # Main Gauge Colors (Left, Right)
      VOLUME_GAUGE  = [20, 21]  # Volume Gauge Colors (Left, Right)
      PITCH_GAUGE   = [20, 21]  # Pitch Gauge Colors (Left, Right)
      
      SEEK_STEP     = 5         # Number Of Seconds Skipped Per Step
      VOLUME_STEP   = 5         # Percentage Of Volume Changed Per Step
      PITCH_STEP    = 5         # Percentage Of Pitch Changed Per Step
      
      VOLUME_DEFAULT= 50        # Default Volume
      PITCH_DEFAULT = 100       # Default Pitch
      PITCH_RANGE   = [50, 150] # Pitch Range
      
      # ======================================================================
      # List Of Tracks. Entries Have Following Format:
      # ======================================================================
      # ID => {
      #   :name         => "Display Name",
      #   :file         => "File Name",
      #   :diration     => 1234,
      #   :sample_rate  => 44100,
      #   :unlocked     => true
      #   },
      # WHERE:
      #   :name          - Name that will show up in the list itself
      #   :file          - Audio File Name (Without Extension)
      #   :duration      - Audio Duration IN SAMPLES. You can check this value
      #                    in many audio programs (e.g. Audacity).
      #   :sample_rate   - Sample Rate of The Audio File. Can be seen in file
      #                    properties or in an audio program (e.g. Audacity).
      #   :unlocked      - If set to "true" - track will be unlocked by default.
      #                    Used only if UNLOCK_MODE is true.
      # ======================================================================
      # If ":file" is omitted - ":name" will be used instead.
      # If ":sample_rate" is omitted - DEFAULT_RATE will be used instead.
      #
      # If file doesn't exist in BGM folder - item will be disabled
      #   in the list and you won't be able to choose it.
      # ======================================================================
      TRACKS = {
      1   => {
        :name => "War Season",
        :file => "War Season",
        :duration => 4960484,
        :sample_rate => 44100,
        :unlocked => true
        },
      2   => {
        :name => "Men's Hair Club",
        :file => "Hair Club",
        :duration => 7304832,
        :sample_rate => 44100,
        :unlocked => true
        },
      3   => {
        :name => "Beehive",
        :file => "Beehive",
        :duration => 5204106,
        :sample_rate => 44100,
        :unlocked => true
        },
      4   => {
        :name => "All Hail the Fishmen",
        :file => "All Hail the Fishmen",
        :duration => 5645952,
        :sample_rate => 44100,
        :unlocked => true
        },
      5   => {
        :name => "Bloodmoon Rising",
        :file => "Bloodmoon Rising",
        :duration => 5587200,
        :sample_rate => 44100,
        :unlocked => true
        },
      6   => {
        :name => "Air Raid",
        :file => "Air Raid",
        :duration => 10257270,
        :sample_rate => 44100
        },
      7   => {
        :name => "Forever Turbo Heat Dance",
        :file => "xxx2 danceman",
        :duration => 5878656,
        :sample_rate => 44100
        },
      8   => {
        :name => "Summer Love",
        :file => "Summer Love",
        :duration => 2964007,
        :sample_rate => 44100
        },
      9   => {
        :name => "Beam Brain",
        :file => "Beam Brain",
        :duration => 3718656,
        :sample_rate => 44100
        },
      10  => {
        :name => "Big Boy's Call",
        :file => "Big Boys Call",
        :duration => 1291068,
        :sample_rate => 44100
        },
      11  => {
        :name => "Blood For Sex",
        :file => "Blood for Sex",
        :duration => 6086396,
        :sample_rate => 44100
        },
      12  => {
        :name => "Blood Simmer",
        :file => "Blood Simmer",
        :duration => 2577453,
        :sample_rate => 44100
        },
      13  => {
        :name => "Salvation!",
        :file => "Brad Armstrong",
        :duration => 3934080,
        :sample_rate => 44100
        },
      14  => {
        :name => "Bile",
        :file => "Bile",
        :duration => 3284297,
        :sample_rate => 44100
        },
      15  => {
        :name => "Exploding Hearts",
        :file => "Exploding Hearts",
        :duration => 17964288,
        :sample_rate => 44100
        },
      16  => {
        :name => "Give Up",
        :file => "Give Up",
        :duration => 3123599,
        :sample_rate => 44100
        },
      17  => {
        :name => "Burning Sunset",
        :file => "Burning Sunset",
        :duration => 8027136,
        :sample_rate => 44100
        },
      18  => {
        :name => "Boy Oh Boy",
        :file => "Boy Oh Boy",
        :duration => 7354368,
        :sample_rate => 44100
        },
      19  => {
        :name => "Devil's Bath Boys",
        :file => "Bathhouse Evil",
        :duration => 8956800,
        :sample_rate => 44100
        },
      20  => {
        :name => "Bradley Baby",
        :file => "Bradley Baby",
        :duration => 10747679,
        :sample_rate => 44100
        },
      21  => {
        :name => "Bradley",
        :file => "Bradley",
        :duration => 13524034,
        :sample_rate => 44100
        },
      22  => {
        :name => "Brawlin'",
        :file => "Brawlin'",
        :duration => 3110400,
        :sample_rate => 44100
        },
      23  => {
        :name => "Cassette Blues",
        :file => "Cassette",
        :duration => 786105,
        :sample_rate => 44100
        },
      24  => {
        :name => "Child's Call",
        :file => "Child's Call",
        :duration => 1693341,
        :sample_rate => 44100
        },
      25  => {
        :name => "Chris Columbo",
        :file => "Chris Columbo",
        :duration => 6018048,
        :sample_rate => 44100
        },
      26  => {
        :name => "Dandy Boy",
        :file => "Dandy Boy",
        :duration => 3842177,
        :sample_rate => 44100
        },
      27  => {
        :name => "Bath Boys",
        :file => "Bathhouse Clean",
        :duration => 8956800,
        :sample_rate => 44100
        },
      28  => {
        :name => "Death Lingers",
        :file => "Death Lingers",
        :duration => 1942272,
        :sample_rate => 44100
        },
      29  => {
        :name => "Deep Inside Me",
        :file => "Deep Inside Me",
        :duration => 6492143,
        :sample_rate => 44100
        },
      30  => {
        :name => "Desert Stroll",
        :file => "Desert Stroll",
        :duration => 3293568,
        :sample_rate => 44100
        },
      31  => {
        :name => "Die Die Die!",
        :file => "Die Die Die",
        :duration => 5045997,
        :sample_rate => 44100
        },
      32  => {
        :name => "Don't Go In There",
        :file => "Don't go in There",
        :duration => 1416455,
        :sample_rate => 44100
        },
      33  => {
        :name => "Evil Draws Near",
        :file => "Evil Draws Near",
        :duration => 5140224,
        :sample_rate => 44100
        },
      34  => {
        :name => "Father's Call",
        :file => "Father's Call",
        :duration => 7909765,
        :sample_rate => 44100
        },
      35  => {
        :name => "F#-k You",
        :file => "Fuck You",
        :duration => 2482560,
        :sample_rate => 44100
        },
      36  => {
        :name => "Garbage Day",
        :file => "Garbage Day",
        :duration => 5890705,
        :sample_rate => 44100
        },
      37  => {
        :name => "Go Home Johnny",
        :file => "Go Home Johnny",
        :duration => 9204170,
        :sample_rate => 44100
        },
      38  => {
        :name => "Goodbye Baby",
        :file => "Goodbye Baby",
        :duration => 6480089,
        :sample_rate => 44100
        },
      39  => {
        :name => "Goodbye",
        :file => "Goodbye",
        :duration => 7788129,
        :sample_rate => 44100
        },
      40  => {
        :name => "Horse Sh!t",
        :file => "Horse Shit",
        :duration => 3745152,
        :sample_rate => 44100
        },
      41  => {
        :name => "I Am Satan",
        :file => "I Am Satan",
        :duration => 7185703,
        :sample_rate => 44100
        },
      42  => {
        :name => "Joy Boy",
        :file => "Joy Boy",
        :duration => 1497562,
        :sample_rate => 44100
        },
      43  => {
        :name => "Last Call Before Hell",
        :file => "Last Call Before Hell weird",
        :duration => 2297088,
        :sample_rate => 44100
        },
      44  => {
        :name => "Lord",
        :file => "Lord",
        :duration => 10583702,
        :sample_rate => 44100
        },
      45  => {
        :name => "Men at Work",
        :file => "Men at Work",
        :duration => 2457515,
        :sample_rate => 44100
        },
      46  => {
        :name => "Work Harder",
        :file => "Work Harder",
        :duration => 4627819,
        :sample_rate => 44100
        },
      47  => {
        :name => "Muddy Waters",
        :file => "Muddy Waters",
        :duration => 8575078,
        :sample_rate => 44100
        },
      48  => {
        :name => "My Lord, My Wally",
        :file => "My Lord, My Wally",
        :duration => 5947164,
        :sample_rate => 44100
        },
      49  => {
        :name => "Ode to the Oblivious",
        :file => "Ode to the Oblivious",
        :duration => 9087501,
        :sample_rate => 44100
        },
      50  => {
        :name => "Ollie's",
        :file => "Ollie's",
        :duration => 955631,
        :sample_rate => 44100
        },
      51  => {
        :name => "Pebble Man",
        :file => "Pebble Man",
        :duration => 5502547,
        :sample_rate => 44100
        },
      52  => {
        :name => "Praise Wally",
        :file => "Praise Wally",
        :duration => 5752294,
        :sample_rate => 44100
        },
      53  => {
        :name => "Rando March",
        :file => "Rando March",
        :duration => 5789443,
        :sample_rate => 44100
        },
      54  => {
        :name => "Rando Road",
        :file => "New Road",
        :duration => 3302568,
        :sample_rate => 44100
        },
      55  => {
        :name => "Shardy's Shanty",
        :file => "Shardy's Shanty",
        :duration => 5789411,
        :sample_rate => 44100
        },
      56  => {
        :name => "Soft Skin",
        :file => "Soft Skin",
        :duration => 4007281,
        :sample_rate => 44100
        },
      57  => {
        :name => "Steel Mill",
        :file => "Steel Mill",
        :duration => 5080320,
        :sample_rate => 44100
        },
      58  => {
        :name => "Summer Breeze",
        :file => "Summer Breeze",
        :duration => 756112,
        :sample_rate => 44100
        },
      59  => {
        :name => "Weird Sh!t",
        :file => "Scary Boy",
        :duration => 4337280,
        :sample_rate => 44100
        },
      60  => {
        :name => "Super Working Stiff",
        :file => "Super Working Stiff",
        :duration => 5357860,
        :sample_rate => 44100
        },
      61  => {
        :name => "Tallgrass Tussle",
        :file => "Tall Grass Tussle",
        :duration => 6024960,
        :sample_rate => 44100
        },
      62  => {
        :name => "The Art of Flesh",
        :file => "The Art of Flesh",
        :duration => 5088384,
        :sample_rate => 44100
        },
      63  => {
        :name => "The End is Nigh",
        :file => "The End is Nigh",
        :duration => 10248873,
        :sample_rate => 44100
        },
      64  => {
        :name => "The Highway King",
        :file => "The Highway King",
        :duration => 9340416,
        :sample_rate => 44100
        },
      65  => {
        :name => "The Sireen's Call",
        :file => "The Sireen's Call",
        :duration => 1412352,
        :sample_rate => 44100
        },
      66  => {
        :name => "Bo's Bro",
        :file => "Bo's Bro",
        :duration => 1726061,
        :sample_rate => 44100
        },
      67  => {
        :name => "Vroom Vroom",
        :file => "Hawk Land",
        :duration => 9490176,
        :sample_rate => 44100
        },
      68  => {
        :name => "Welcome Home",
        :file => "Welcome Home",
        :duration => 3044088,
        :sample_rate => 44100
        },
      69  => {
        :name => "Welcome to Hell",
        :file => "Welcome to Hell",
        :duration => 4814208,
        :sample_rate => 44100
        },
      70  => {
        :name => "Welcomed Death",
        :file => "Welcomed Death",
        :duration => 10692864,
        :sample_rate => 44100
        },
      71  => {
        :name => "The Band's Call",
        :file => "The Band's Call",
        :duration => 3847680,
        :sample_rate => 44100
        },
      72  => {
        :name => "Life is Trash",
        :file => "Life is Trash",
        :duration => 8850816,
        :sample_rate => 44100
        },
      73  => {
        :name => "Working Stiff",
        :file => "Working Stiff",
        :duration => 5359104,
        :sample_rate => 44100
        },
      74  => {
        :name => "Hernandez Ocean",
        :file => "Hernandez Ocean",
        :duration => 3161088,
        :sample_rate => 44100
        },
      75  => {
        :name => "Power Mountian",
        :file => "Power Mountian",
        :duration => 5916672,
        :sample_rate => 44100
        },
      76  => {
        :name => "Balloon Man",
        :file => "Balloon Man",
        :duration => 4377600,
        :sample_rate => 44100
        },
      77  => {
        :name => "Wonder Wizard",
        :file => "Wizard",
        :duration => 353259,
        :sample_rate => 44100
        },
      78  => {
        :name => "Bill Collectors",
        :file => "Bill Collectors",
        :duration => 265289,
        :sample_rate => 44100
        },
      79  => {
        :name => "Sunset Express",
        :file => "Sunset Express",
        :duration => 450969,
        :sample_rate => 44100
        },
      80  => {
        :name => "Death Queen",
        :file => "Death Queen",
        :duration => 334195,
        :sample_rate => 44100
        },
      81  => {
        :name => "Cinder Sluggan",
        :file => "Cinder",
        :duration => 353259,
        :sample_rate => 44100
        },
      82  => {
        :name => "Biscuits n' Gravy",
        :file => "Biscuits n Gravy",
        :duration => 441459,
        :sample_rate => 44100
        },
      83  => {
        :name => "Go Home Boys",
        :file => "Go Home",
        :duration => 441459,
        :sample_rate => 44100
        },
      84  => {
        :name => "Man's Worst Friend",
        :file => "Man's Worst Friend",
        :duration => 353030,
        :sample_rate => 44100
        },
      85  => {
        :name => "Cosmic Boys",
        :file => "Cosmic Boys",
        :duration => 177778,
        :sample_rate => 44100
        },
      86  => {
        :name => "Hot Soup Baby",
        :file => "Gary's Theme",
        :duration => 415275,
        :sample_rate => 44100
        },
      87  => {
        :name => "Foreign Objection",
        :file => "Foreign Objection",
        :duration => 368189,
        :sample_rate => 44100
        },
      88  => {
        :name => "Crossbones",
        :file => "Crossbones",
        :duration => 314212,
        :sample_rate => 44100
        },
      89  => {
        :name => "Zaladin",
        :file => "Zaladin",
        :duration => 355327,
        :sample_rate => 44100
        },
      90  => {
        :name => "Live in Joy",
        :file => "Joy Lives in Me",
        :duration => 6062096,
        :sample_rate => 44100
        },
      91  => {
        :name => "God's Call",
        :file => "Trumpet Cave",
        :duration => 1448181,
        :sample_rate => 44100
        },
      92  => {
        :name => "Patience, My Child!",
        :file => "Bathhouse entrance",
        :duration => 1330364,
        :sample_rate => 44100
        },
      93  => {
        :name => "The Sacrifice",
        :file => "The Sacrifice",
        :duration => 7344391,
        :sample_rate => 44100
        },
      94  => {
        :name => "Dead Children",
        :file => "Dead Children",
        :duration => 1596672,
        :sample_rate => 44100
        },
      95  => {
        :name => "Satan's Call",
        :file => "Satan's Call",
        :duration => 1275513,
        :sample_rate => 44100
        },
      96  => {
        :name => "Death's Call",
        :file => "Death's Call",
        :duration => 2469087,
        :sample_rate => 44100
        },
      97  => {
        :name => "Nobody's Call",
        :file => "Nobody's Call",
        :duration => 1480759,
        :sample_rate => 44100
        },
      98  => {
        :name => "Fear",
        :file => "Fear",
        :duration => 502895,
        :sample_rate => 44100
        },
      99  => {
        :name => "Love",
        :file => "Love",
        :duration => 1456128,
        :sample_rate => 44100
        },
      100 => {
        :name => "All Hail the Fishmen's Cave",
        :file => "All Hail the Fishmen's Cave",
        :duration => 5647556,
        :sample_rate => 44100
        },
      101 => {
        :name => "Blood Cave",
        :file => "Blood Cave",
        :duration => 706978,
        :sample_rate => 44100
        },
      102 => {
        :name => "Boy Oh Boy Record",
        :file => "Boy Oh Boy Record",
        :duration => 8113536,
        :sample_rate => 44100
        },
      103 => {
        :name => "Desert Stroll Cave",
        :file => "Desert Stroll cave",
        :duration => 3294720,
        :sample_rate => 44100
        },
      104 => {
        :name => "Shardy's Cave",
        :file => "Shardy's Cave",
        :duration => 5791669,
        :sample_rate => 44100
        },
      105 => {
        :name => "Summer Love Indoors",
        :file => "Summer Love Indoors",
        :duration => 2958643,
        :sample_rate => 44100
        },
      106 => {
        :name => "Work Smarter",
        :file => "Work Smarter",
        :duration => 4628334,
        :sample_rate => 44100
        },
      107 => {
        :name => "Turbo Heat Outside",
        :file => "xxx outside",
        :duration => 5618304,
        :sample_rate => 44100
        },
      108 => {
        :name => "Plastic Cave",
        :file => "Plastic Cave",
        :duration => 5024644,
        :sample_rate => 44100
        },
      109 => {
        :name => "Gotta Die Sometime",
        :file => "Gotta Die Sometime",
        :duration => 296462,
        :sample_rate => 44100
        },
      } # DO NOT REMOVE THIS
    end
  end
end

# =============================================================================
# CONFIGURATION END
# =============================================================================

#==============================================================================
# ** Scene_MusicPlayer
#==============================================================================

class Scene_MusicPlayer < Scene_Base
  #--------------------------------------------------------------------------
  # * Start Processing
  #--------------------------------------------------------------------------
  def start
    super
    create_windows
  end
  #--------------------------------------------------------------------------
  # * Create All Windows
  #--------------------------------------------------------------------------
  def create_windows
    create_music_control_window
    create_music_select_window
  end
  #--------------------------------------------------------------------------
  # * Create Window_MusicControl
  #--------------------------------------------------------------------------
  def create_music_control_window
    @music_control_window = Window_MusicControl.new
  end
  #--------------------------------------------------------------------------
  # * Create Window_MusicSelect
  #--------------------------------------------------------------------------
  def create_music_select_window
    @music_select_window = Window_MusicSelect.new(0, 24 * 4 - 16)
    @music_select_window.viewport = @viewport
    @music_select_window.set_handler(:ok,     method(:on_music_ok))
    @music_select_window.set_handler(:cancel, method(:on_music_cancel))
  end
  #--------------------------------------------------------------------------
  # * On Music Selection
  #--------------------------------------------------------------------------
  def on_music_ok
    @music_select_window.select_current_track
    selected_track = @music_select_window.current_track
    current_track = @music_control_window.track_id
    
    if current_track == selected_track
      if @music_select_window.is_playing
        @music_control_window.stop
        @music_select_window.is_playing = false
      else
        @music_control_window.play
        @music_select_window.is_playing = true
      end
    else
      @music_control_window.set_track(selected_track)
      @music_select_window.is_playing = true
    end
    @music_select_window.redraw_two_last_items
  end
  #--------------------------------------------------------------------------
  # * On Music Window Cancel
  #--------------------------------------------------------------------------
  def on_music_cancel
    @music_control_window.clear
    @music_select_window.clear
    return_scene
  end
end

#==============================================================================
# ** Window_MusicControl
#------------------------------------------------------------------------------
#  This window displays music playback information and handles controls like
#   volume and pitch changing, seeking.
#==============================================================================

class Window_MusicControl < Window_Base
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_reader :track_id   # Current Track ID
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize
    super(0, 0, Graphics.width, fitting_height(3) - 16)
    @track_id = -1
    @track_data = nil
    @volume = YuriSH::Const::MusicPlayer::VOLUME_DEFAULT
    @pitch = YuriSH::Const::MusicPlayer::PITCH_DEFAULT
    @last_pos = 0
    @start_time = 0
    @playing = false
    refresh
  end
  #--------------------------------------------------------------------------
  # * Clear
  #--------------------------------------------------------------------------
  def clear
    stop
    @track_id = -1
    @track_data = nil
    @volume = YuriSH::Const::MusicPlayer::VOLUME_DEFAULT
    @pitch = YuriSH::Const::MusicPlayer::PITCH_DEFAULT
    @last_pos = 0
    @start_time = 0
    @playing = false
  end
  #--------------------------------------------------------------------------
  # * Returns File Name Of Current Item
  #--------------------------------------------------------------------------
  def get_file_name
    return "" if @track_data.nil?
    @track_data.include?(:file) ? @track_data[:file] : @track_data[:name]
  end
  #--------------------------------------------------------------------------
  # * Returns Sample Rate Of Current Item
  #--------------------------------------------------------------------------
  def get_sample_rate
    return YuriSH::Const::MusicPlayer::DEFAULT_RATE if @track_data.nil?
    @track_data.include?(:sample_rate) ? @track_data[:sample_rate] : YuriSH::Const::MusicPlayer::DEFAULT_RATE
  end
  #--------------------------------------------------------------------------
  # * Set Track
  #--------------------------------------------------------------------------
  def set_track(id)
    if id != @track_id
      stop
      @track_id = id
      @track_data = YuriSH::Const::MusicPlayer::TRACKS[@track_id]
      @last_pos = 0
      @start_time = 0
      play
    end
  end
  #--------------------------------------------------------------------------
  # * Play Current Track
  #--------------------------------------------------------------------------
  def play(pos = -1)
    @start_time = Time.now
    @last_pos = pos if pos >= 0
    Audio.bgm_play('Audio/BGM/' + get_file_name, @volume, @pitch, @last_pos)
    @playing = true
  end
  #--------------------------------------------------------------------------
  # * Stop Current Track
  #--------------------------------------------------------------------------
  def stop
    @last_pos = Audio.bgm_pos
    Audio.bgm_stop
    @playing = false
  end
  #--------------------------------------------------------------------------
  # * Move Playback By Specified Number Of Seconds
  #--------------------------------------------------------------------------
  def move_by(seconds)
    return unless @playing
    stop
    @last_pos += YuriSH::Const::MusicPlayer::VXACE_HZ_RATE * seconds
    @last_pos = 0 if @last_pos < 0
    play
  end
  #--------------------------------------------------------------------------
  # * Change Volume
  #--------------------------------------------------------------------------
  def change_volume(value)
    @volume = value
    @volume = 100 if @volume > 100
    @volume = 0 if @volume < 0
    refresh_controls
    @last_pos = Audio.bgm_pos
    play if @playing
  end
  #--------------------------------------------------------------------------
  # * Change Pitch
  #--------------------------------------------------------------------------
  def change_pitch(value)
    p_min = YuriSH::Const::MusicPlayer::PITCH_RANGE.min
    p_max = YuriSH::Const::MusicPlayer::PITCH_RANGE.max
    @pitch = value
    @pitch = p_max if @pitch > p_max
    @pitch = p_min if @pitch < p_min
    refresh_controls
    @last_pos = Audio.bgm_pos
    play if @playing
  end
  #--------------------------------------------------------------------------
  # * Returns Duration Parameters
  #     0 - Max. Duration (seconds)
  #     1 - Current Duration (seconds)
  #     2 - Rate (0.0 - 1.0)
  #--------------------------------------------------------------------------
  def get_duration_params
    if @track_id < 0 or @track_data.nil?
      return [0, 0, 0]
    end
    
    max_dur = @track_data[:duration] / get_sample_rate.to_f
    cur_dur = (Time.now - @start_time) * (@pitch / 100.0)
    cur_dur += (@last_pos / YuriSH::Const::MusicPlayer::VXACE_HZ_RATE.to_f)
    cur_dur = cur_dur % max_dur
    r_rate = cur_dur / max_dur
    return [max_dur, cur_dur, r_rate]
  end
  #--------------------------------------------------------------------------
  # * Formats Raw Seconds To "M:SS" Format.
  #--------------------------------------------------------------------------
  def format_time(sec_value)
    "%d:%02d" % [sec_value / 60, sec_value % 60]
  end
  #--------------------------------------------------------------------------
  # * Refresh
  #--------------------------------------------------------------------------
  def refresh
    refresh_on_update
    refresh_controls
  end
  #--------------------------------------------------------------------------
  # * Refresh (Called Each Frame)
  #--------------------------------------------------------------------------
  def refresh_on_update
    contents.clear_rect(0, 0, contents_width, 36)
    p_params = get_duration_params
    
    draw_track_name(@track_id, @track_data[:name]) if @track_id >= 0
    draw_track_duration(p_params[0], p_params[1])
    draw_progress_gauge(p_params[2])
  end
  #--------------------------------------------------------------------------
  # * Refresh Controls
  #--------------------------------------------------------------------------
  def refresh_controls
    contents.clear_rect(0, 36, contents_width, 20)
    draw_volume_control
    draw_pitch_control
  end
  #--------------------------------------------------------------------------
  # * Draw Track Name and ID
  #--------------------------------------------------------------------------
  def draw_track_name(id, name)
    change_color(text_color(9))
    draw_text(4, 0, contents_width - 8, line_height, "%03d" % id, 0)
    
    change_color(normal_color)
    draw_text(44, 0, contents_width - 8, line_height, name, 0)
  end
  #--------------------------------------------------------------------------
  # * Draw Track Duration
  #--------------------------------------------------------------------------
  def draw_track_duration(max_time, current_time)
    draw_text(4, 0, contents_width - 8, line_height,
      "%s / %s" % [format_time(current_time), format_time(max_time)], 2)
  end
  #--------------------------------------------------------------------------
  # * Draw Progress Gauge
  #--------------------------------------------------------------------------
  def draw_progress_gauge(rate)
    draw_gauge(0, line_height - 12, contents_width, rate,
      text_color(YuriSH::Const::MusicPlayer::MAIN_GAUGE[0]),
      text_color(YuriSH::Const::MusicPlayer::MAIN_GAUGE[1]))
  end
  #--------------------------------------------------------------------------
  # * Draw Volume Control
  #--------------------------------------------------------------------------
  def draw_volume_control
    next_pos = 4
    d_height = line_height * 2 - 14
    draw_text(next_pos, d_height, contents_width, line_height, "Volume", 0)
    
    next_pos += 66
    draw_icon(YuriSH::Const::MusicPlayer::MINUS_ICON, next_pos, d_height)
    
    next_pos += 30
    draw_gauge(next_pos, d_height, 100, @volume / 100.0,
      text_color(YuriSH::Const::MusicPlayer::VOLUME_GAUGE[0]),
      text_color(YuriSH::Const::MusicPlayer::VOLUME_GAUGE[1]))
      
    gauge_rect = Rect.new(next_pos, d_height, 100, line_height)
    draw_text(gauge_rect, "%d%%" % @volume, 1)
    
    next_pos += 106
    draw_icon(YuriSH::Const::MusicPlayer::PLUS_ICON, next_pos, d_height)
  end
  #--------------------------------------------------------------------------
  # * Draw Pitch Control
  #--------------------------------------------------------------------------
  def draw_pitch_control
    next_pos = contents_width - 24
    d_height = line_height * 2 - 14
    draw_icon(YuriSH::Const::MusicPlayer::PLUS_ICON, next_pos, d_height)
    
    next_pos -= 106
    draw_gauge(next_pos, d_height, 100, (@pitch - 50) / 100.0,
      text_color(YuriSH::Const::MusicPlayer::PITCH_GAUGE[0]),
      text_color(YuriSH::Const::MusicPlayer::PITCH_GAUGE[1]))
    
    gauge_rect = Rect.new(next_pos, d_height, 100, line_height)
    draw_text(gauge_rect, "%d%%" % @pitch, 1)
    
    next_pos -= 30
    draw_icon(YuriSH::Const::MusicPlayer::MINUS_ICON, next_pos, d_height)
    
    next_pos -= 56
    draw_text(next_pos, d_height, contents_width, line_height, "Pitch", 0)
  end
  #--------------------------------------------------------------------------
  # * Handle Player Input
  #--------------------------------------------------------------------------
  def handle_input
    if Input.press?(:CTRL)
      handle_pitch
    elsif Input.press?(:SHIFT)
      handle_volume
    else
      handle_move
    end
  end
  #--------------------------------------------------------------------------
  # * Handle Input For Pitch
  #--------------------------------------------------------------------------
  def handle_pitch
    if Input.trigger?(:LEFT) or Input.repeat?(:LEFT)
      change_pitch(@pitch - YuriSH::Const::MusicPlayer::PITCH_STEP)
      Sound.play_cursor
    elsif Input.trigger?(:RIGHT) or Input.repeat?(:RIGHT)
      change_pitch(@pitch + YuriSH::Const::MusicPlayer::PITCH_STEP)
      Sound.play_cursor
    end
  end
  #--------------------------------------------------------------------------
  # * Handle Input For Volume
  #--------------------------------------------------------------------------
  def handle_volume
    if Input.trigger?(:LEFT) or Input.repeat?(:LEFT)
      change_volume(@volume - YuriSH::Const::MusicPlayer::VOLUME_STEP)
      Sound.play_cursor
    elsif Input.trigger?(:RIGHT) or Input.repeat?(:RIGHT)
      change_volume(@volume + YuriSH::Const::MusicPlayer::VOLUME_STEP)
      Sound.play_cursor
    end
  end
  #--------------------------------------------------------------------------
  # * Handle Input For Moving
  #--------------------------------------------------------------------------
  def handle_move
    if @playing
      if Input.trigger?(:LEFT) or Input.repeat?(:LEFT)
        move_by(-YuriSH::Const::MusicPlayer::SEEK_STEP)
        Sound.play_cursor
      elsif Input.trigger?(:RIGHT) or Input.repeat?(:RIGHT)
        move_by(YuriSH::Const::MusicPlayer::SEEK_STEP)
        Sound.play_cursor
      end
    end
  end
  #--------------------------------------------------------------------------
  # * Update
  #--------------------------------------------------------------------------
  def update
    super
    handle_input
    refresh_on_update if @playing
  end
end

#==============================================================================
# ** Window_MusicSelect
#------------------------------------------------------------------------------
#  This window displays a list of music items.
#==============================================================================

class Window_MusicSelect < Window_Selectable
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_accessor  :prev_index    # previous cursor position
  attr_accessor  :current_track # currently selected track
  attr_accessor  :is_playing    # is track playing (technical value)
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize(x, y)
    super(x, y, window_width, window_height)
    @current_track = -1
    @previous_index = -1
    @is_playing = false
    refresh
    select(0)
    activate
  end
  #--------------------------------------------------------------------------
  # * Clear
  #--------------------------------------------------------------------------
  def clear
    unselect
    @current_track = -1
    @previous_index = -1
    @is_playing = false
  end
  #--------------------------------------------------------------------------
  # * Returns Data Hash By Index
  #--------------------------------------------------------------------------
  def get_data(index)
    i_key = YuriSH::Const::MusicPlayer::TRACKS.keys[index]
    i_item = YuriSH::Const::MusicPlayer::TRACKS[i_key]
    return {:key => i_key, :data => i_item}
  end
  #--------------------------------------------------------------------------
  # * Returns File Name Of Current Item
  #--------------------------------------------------------------------------
  def get_file_name(index)
    data = get_data(index)
    data[:data].include?(:file) ? data[:data][:file] : data[:data][:name]
  end
  #--------------------------------------------------------------------------
  # * Processing When OK Button Is Pressed
  #--------------------------------------------------------------------------
  def process_ok
    if current_item_enabled?
      Sound.play_ok
      Input.update
      call_ok_handler
    else
      Sound.play_buzzer
    end
  end
  #--------------------------------------------------------------------------
  # * Get Window Width
  #--------------------------------------------------------------------------
  def window_width
    return Graphics.width
  end
  #--------------------------------------------------------------------------
  # * Get Window Height
  #--------------------------------------------------------------------------
  def window_height
    fitting_height(visible_line_number)
  end
  #--------------------------------------------------------------------------
  # * Get Number of Lines to Show
  #--------------------------------------------------------------------------
  def visible_line_number
    return 13
  end
  #--------------------------------------------------------------------------
  # * Get Number of Items
  #--------------------------------------------------------------------------
  def item_max
    return YuriSH::Const::MusicPlayer::TRACKS.size
  end
  #--------------------------------------------------------------------------
  # * Select Item
  #--------------------------------------------------------------------------
  def select(index)
    self.prev_index = self.index
    super(index)
    redraw_two_last_items
  end
  #--------------------------------------------------------------------------
  # * Redraw Current And Previous Items
  #--------------------------------------------------------------------------
  def redraw_two_last_items
    redraw_item(self.prev_index)
    redraw_item(self.index)
  end
  #--------------------------------------------------------------------------
  # * Select Current Track
  #--------------------------------------------------------------------------
  def select_current_track
    data = get_data(self.index)
    self.current_track = data[:key]
  end
  #--------------------------------------------------------------------------
  # * Deselect Current Track
  #--------------------------------------------------------------------------
  def deselect_current_track
    self.current_track = -1
  end
  #--------------------------------------------------------------------------
  # * Width Of Track ID String
  #--------------------------------------------------------------------------
  def track_id_width
    return 40
  end
  #--------------------------------------------------------------------------
  # * Get Activation State of Selection Item
  #--------------------------------------------------------------------------
  def current_item_enabled?
    return item_enabled?(self.index)
  end
  #--------------------------------------------------------------------------
  # * Returns True If Item Is Enabled
  #--------------------------------------------------------------------------
  def item_enabled?(index)
    return (file_exists?(index) and item_unlocked?(index))
  end
  #--------------------------------------------------------------------------
  # * Returns True If Item Is Unlocked
  #--------------------------------------------------------------------------
  def item_unlocked?(index)
    return true unless YuriSH::Const::MusicPlayer::UNLOCK_MODE
    data = get_data(index)
    return $game_music_player.unlocked?(data[:key])
  end
  #--------------------------------------------------------------------------
  # * Returns True If File Exists
  #--------------------------------------------------------------------------
  def file_exists?(index)
    f_path = "Audio/BGM/" + get_file_name(index)
    [".ogg", ".wav"].each do |x|
      return true if FileTest.exist?(f_path + x)
    end
    return false
  end
  #--------------------------------------------------------------------------
  # * Draw Item
  #--------------------------------------------------------------------------
  def draw_item(index)
    data = get_data(index)
    is_enabled = item_enabled?(index)
    is_unlocked = item_unlocked?(index)
    text_rect = item_rect_for_text(index)
    icon_x = text_rect.width - 24
    icon_y = text_rect.y
    
    change_color(text_color(YuriSH::Const::MusicPlayer::ID_COLOR), is_enabled)
    draw_text(text_rect, "%03d" % data[:key], 0)
    
    text_rect.x += track_id_width
    text_rect.width -= track_id_width
    change_color(normal_color, is_enabled)
    draw_text(text_rect,
      is_unlocked ? data[:data][:name] : YuriSH::Const::MusicPlayer::LOCKED_NAME,
      0)
    
    if self.current_track == data[:key]
      if self.is_playing
        draw_icon(YuriSH::Const::MusicPlayer::PAUSE_ICON,
          icon_x, icon_y, is_enabled)
      else
        draw_icon(YuriSH::Const::MusicPlayer::PLAY_ICON,
          icon_x, icon_y, is_enabled)
      end
    elsif self.index == index
      draw_icon(YuriSH::Const::MusicPlayer::PLAY_ICON,
        icon_x, icon_y, is_enabled)
    end
  end
end

#==============================================================================
# ** Scene_Title
#==============================================================================

class Scene_Title < Scene_Base
  #--------------------------------------------------------------------------
  # * Create Command Window
  #--------------------------------------------------------------------------
  alias create_command_window_yurish_a2kvj create_command_window
  def create_command_window
    create_command_window_yurish_a2kvj
    @command_window.set_handler(:music_player, method(:command_music_player))
  end
  #--------------------------------------------------------------------------
  # * [Music Player] Command
  #--------------------------------------------------------------------------
  def command_music_player
    close_command_window
    SceneManager.call(Scene_MusicPlayer)
  end
end

#==============================================================================
# ** Window_TitleCommand
#==============================================================================

class Window_TitleCommand < Window_Command
  #--------------------------------------------------------------------------
  # * Create Command List
  #--------------------------------------------------------------------------
  alias make_command_list_yurish_a2kvj make_command_list
  def make_command_list
    make_command_list_yurish_a2kvj
    c_com = {
      :name => "Music Player",
      :symbol => :music_player,
      :enabled => true,
      :ext => nil}
    @list.insert(@list.size-1, c_com)
  end
end

# Stuff below exists only if UNLOCK_MODE is enabled.
if YuriSH::Const::MusicPlayer::UNLOCK_MODE

#==============================================================================
# ** Game_MusicPlayer
#------------------------------------------------------------------------------
#  Helper class for storing music unlock data across different saves.
# The instance of this class is referenced by $game_music_player.
#==============================================================================

class Game_MusicPlayer
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_accessor :data         # Unlock Data
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  def initialize
    @data = []
  end
  #--------------------------------------------------------------------------
  # * Save Data To File Manually
  #--------------------------------------------------------------------------
  def save
    return DataManager.save_music_data_with_rescue
  end
  #--------------------------------------------------------------------------
  # * Returns True If Music Track Is Unlocked
  #--------------------------------------------------------------------------
  def unlocked?(id)
    @data.include?(id) or YuriSH::Const::MusicPlayer::TRACKS[id].fetch(:unlocked, false)
  end
  #--------------------------------------------------------------------------
  # * Unlock Music Tracks
  #--------------------------------------------------------------------------
  def unlock(*args)
    @data.concat(args)
    @data.uniq!
  end
  #--------------------------------------------------------------------------
  # * Lock Music Tracks
  #--------------------------------------------------------------------------
  def lock(*args)
    @data.delete_if { |x| args.include?(x) }
  end
  #--------------------------------------------------------------------------
  # * Unlock All Tracks
  #--------------------------------------------------------------------------
  def unlock_all
    @data = YuriSH::Const::MusicPlayer::TRACKS.keys
  end
  #--------------------------------------------------------------------------
  # * Lock All Tracks
  #--------------------------------------------------------------------------
  def lock_all
    @data = []
  end
end
  
#==============================================================================
# ** DataManager
#==============================================================================

module DataManager
  #--------------------------------------------------------------------------
  # * Aliases
  #--------------------------------------------------------------------------
  class << self
    alias init_yurish_a2kvj init
    alias save_game_without_rescue_yurish_a2kvj save_game_without_rescue
  end
  #--------------------------------------------------------------------------
  # * Initialize Module
  #--------------------------------------------------------------------------
  def self.init
    load_music_data
    init_yurish_a2kvj
  end
  #--------------------------------------------------------------------------
  # * Execute Save (No Exception Processing)
  #--------------------------------------------------------------------------
  def self.save_game_without_rescue(index)
    if save_game_without_rescue_yurish_a2kvj(index)
      save_music_data_without_rescue
    end
    return true
  end
  #--------------------------------------------------------------------------
  # * Load Music Data
  #--------------------------------------------------------------------------
  def self.load_music_data
    if music_data_exists?
      $game_music_player = load_data(YuriSH::Const::MusicPlayer::DATA_PATH)
    else
      $game_music_player = Game_MusicPlayer.new
      return save_music_data_with_rescue
    end
    return true
  end
  #--------------------------------------------------------------------------
  # * Save Music Data (With Exception Processing)
  #--------------------------------------------------------------------------
  def self.save_music_data_with_rescue
    begin
      save_music_data_without_rescue
    rescue
      delete_music_data
      return false
    end
    return true
  end
  #--------------------------------------------------------------------------
  # * Save Music Data (No Exception Processing)
  #--------------------------------------------------------------------------
  def self.save_music_data_without_rescue
    File.open(YuriSH::Const::MusicPlayer::DATA_PATH, "wb") do |file|
      Marshal.dump($game_music_player, file)
    end
    return true
  end
  #--------------------------------------------------------------------------
  # * Delete Music Data
  #--------------------------------------------------------------------------
  def self.delete_music_data
    File.delete(YuriSH::Const::MusicPlayer::DATA_PATH) rescue nil
  end
  #--------------------------------------------------------------------------
  # * Returns True If Music Data Exists.
  #--------------------------------------------------------------------------
  def self.music_data_exists?
    FileTest.exist?(YuriSH::Const::MusicPlayer::DATA_PATH)
  end
end

end