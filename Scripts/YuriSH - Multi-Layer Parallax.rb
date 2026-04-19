# =============================================================================
# ** Multi-Layered Parallaxes
# * By YuriSH
# -----------------------------------------------------------------------------
# This script implements parallaxes with multiple layers.
# =============================================================================

$imported = {} if $imported.nil?
$imported["YuriSH_MultiLayerParallaxes"] = true

# =============================================================================
# ** ParallaxManager
# -----------------------------------------------------------------------------
# Stores parallax layer info for each background image.
# =============================================================================

module YuriSH
  module ParallaxManager
    #--------------------------------------------------------------------------
    # List Of Parallaxes
    # Add your parallaxes here!
    # Format is as follows:
    # -------------------------------------------------------------------------
    # "MainBG"  =>  {id => ParallaxLayer.new(...), id2 => ParallaxLayer.new(...), ...}
    # -------------------------------------------------------------------------
    # ParallaxLayer.new("LayerSuffix", sx, xy, ox, oy)
    #--------------------------------------------------------------------------
    # "MainBG"      - Name of the base parallax image. Layers will be attached to
    #                 this parallax.
    # id            - ID of the layer. Must be a positive number above 0.
    #                 Should be unique (no repeating numbers within one parallax).
    # "LayerSuffix" - Suffix of the layer image. It will be added to base parallax
    #                 name with "_" symbol, like "MainBG_LayerSuffix".
    # sx, sy        - Scroll multipliers. sx - horizontal, sy - vertical.
    #                 Default: 1.0, which means they will scroll at the same rate
    #                 as base parallax. Lower numbers mean slower movement,
    #                 higher numbers - faster movement.
    # ox, oy        - Offset values. Positive numbers mean offset to right/down,
    #                 Negative numbes - offset to left/up.
    # There can be ANY numbers of ParallaxLayers.
    # (Technically there is a limit at around 100 layers after which layers will
    # render above tilesets and events so be aware)
    #--------------------------------------------------------------------------
    LAYERS = {
      "L1" => {
        1 => ParallaxLayer.new("Layer1", 0.8, 1.0, 45, 0),
        2 => ParallaxLayer.new("Layer2", 1.0, 1.0,  0, 0),
        3 => ParallaxLayer.new("Layer3", 1.1, 1.0, 45, 0),
        4 => ParallaxLayer.new("Layer4", 1.2, 1.0,  0, 0),
      },
    }
    #--------------------------------------------------------------------------
    # * If Parallax Is Dirty (Needs Updating)
    # * ParallaxGraphic => TrueOrFalse
    #--------------------------------------------------------------------------
    @dirty = {}
    #--------------------------------------------------------------------------
    # * Gets Layers Associated With Parallax Graphic
    #--------------------------------------------------------------------------
    def self.get_layers(graphic)
      LAYERS.has_key?(graphic) ? LAYERS[graphic] : nil
    end
    #--------------------------------------------------------------------------
    # * Parallax Was Marked As Dirty?
    #--------------------------------------------------------------------------
    def self.dirty?(graphic)
      @dirty.has_key?(graphic) ? @dirty[graphic] : false
    end
    #--------------------------------------------------------------------------
    # * Sets Dirty Flag For Parallax
    #--------------------------------------------------------------------------
    def self.set_dirty(graphic, value)
      @dirty[graphic] = value if LAYERS.has_key?(graphic)
    end
  end
end

# =============================================================================
# ** ParallaxLayer
# -----------------------------------------------------------------------------
# Data class that stores info about parallax layers.
# =============================================================================

class ParallaxLayer
  #----------------------------------------------------------------------------
  # * Public Instance Variables
  #----------------------------------------------------------------------------
  attr_reader   :graphic
  attr_accessor :sx
  attr_accessor :sy
  attr_accessor :ox
  attr_accessor :oy
  #----------------------------------------------------------------------------
  # * Object Initialization
  #----------------------------------------------------------------------------
  def initialize(graphic = "", sx = 1.0, sy = 1.0, ox = 0, oy = 0)
    @graphic = graphic
    @sx = sx
    @sy = sy
    @ox = ox
    @oy = oy
  end
end

# =============================================================================
# ** Spriteset_Map
# =============================================================================

class Spriteset_Map
  #--------------------------------------------------------------------------
  # * Object Initialization
  #--------------------------------------------------------------------------
  alias initialize_yurish_4sakv initialize
  def initialize
    create_layers
    initialize_yurish_4sakv
  end
  #--------------------------------------------------------------------------
  # * Add Layer
  #--------------------------------------------------------------------------
  def add_layer(id, data)
    layer = Plane.new(@viewport1)
    layer.bitmap = Cache.parallax(data.graphic)
    layer.z = -100 + id + 1
    if @layers.has_key?(id)
      @layers[id].bitmap.dispose if @layers[id].bitmap
      @layers[id].dispose
    end
    @layers[id] = {:layer => layer, :data => data}
  end
  #--------------------------------------------------------------------------
  # * Create Layers
  #--------------------------------------------------------------------------
  def create_layers
    @layers = {}
    layer_data = YuriSH::ParallaxManager.get_layers(@parallax_name)
    return if layer_data.nil?
    layer_data.each do |id, data|
      add_layer(id, data)
    end
  end
  #--------------------------------------------------------------------------
  # * Frame Update
  #--------------------------------------------------------------------------
  alias update_yurish_4sakv update
  def update
    update_yurish_4sakv
    update_layers
  end
  #--------------------------------------------------------------------------
  # * Update Layers
  #--------------------------------------------------------------------------
  def update_layers
    if YuriSH::ParallaxManager.dirty?(@parallax_name)
      YuriSH::ParallaxManager.set_dirty(@parallax_name, false)
      dispose_layers
      create_layers
      Graphics.frame_reset
    end
    @layers.each do |key, value|
      layer = value[:layer]
      data = value[:data]
      layer.ox = $game_map.parallax_ox(@parallax.bitmap) * data.sx + data.ox
      layer.oy = $game_map.parallax_oy(@parallax.bitmap) * data.sy + data.oy
    end
  end
  #--------------------------------------------------------------------------
  # * Update Parallax
  #--------------------------------------------------------------------------
  alias update_parallax_yurish_4sakv update_parallax
  def update_parallax
    if @parallax_name != $game_map.parallax_name
      YuriSH::ParallaxManager.set_dirty($game_map.parallax_name, true)
    end
    update_parallax_yurish_4sakv
  end
  #--------------------------------------------------------------------------
  # * Dispose
  #--------------------------------------------------------------------------
  alias dispose_yurish_4sakv dispose
  def dispose
    dispose_yurish_4sakv
    dispose_layers
  end
  #--------------------------------------------------------------------------
  # * Dispose Layers
  #--------------------------------------------------------------------------
  def dispose_layers
    @layers.each do |key, value|
      layer = value[:layer]
      layer.bitmap.dispose if layer.bitmap
      layer.dispose
    end
  end
end