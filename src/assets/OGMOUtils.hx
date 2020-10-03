// OGMO support
// ============
//
// Basic support for loading levels designed using OGMO.  Relies on ogmo-3
// library as backend.  See Note [(Un)supported OGMO features].
//
// (c) Jan Stolarek 2020, MIT License

package assets;

// Note [(Un)supported OGMO features]
// ==================================
//
// At the moment OGMO support is very rudimentary.  Supported features:
//
//  * background layer loading (must be a 2D tile array)
//  * collisions layer loading (must be a 2D grid array)
//
// Everything else is unsupported.  In particular:
//
//  * entity layers
//  * different types of layer formats (1D, coords)
//  * tile separation in tilesets

class OGMOUtilsException extends haxe.Exception {}

typedef LayerCallback =
  TileSet -> ogmo.Level.LayerDefinition -> Level -> Void;

class OGMOUtils {
  static var LOGGER = HexLog.getLogger();

  // See Note [OGMO level constants]
  static var layerCallbacks : Map<String, LayerCallback> =
    [ Const.LAYER_BG    => loadBackgroundLayer
    , Const.LAYER_COLLS => loadCollisionsLayer
    , Const.LAYER_FG    => loadForegroundLayer ];

  function new( ) { }

  public static function loadWorld( project   :       hxd.res.Resource
                                  , levelsRes : Array<hxd.res.Resource>
                                  , world     : World ) {
    LOGGER.info( "Loading project: " + project.name );
    var project = ogmo.Project.create( project.entry.getText( ) );

    for ( tileset in project.tilesets ) {
      LOGGER.debug( "Building tileset: " + tileset.label );
      world.addTileSet( tileset.label, new TileSet( tileset ) );
    }

    for ( levelRes in levelsRes ) {
      LOGGER.info( "Loading level: " + levelRes.name );
      var ogmoLevel = ogmo.Level.create( levelRes.entry.getText( ) );
      // See Note [OGMO level constants]
      var levelName = LevelName.fromString(
                      ogmoLevel.values.get( Const.LEVEL_FIELD_NAME ) );
      var levelDisplayName
                    = ogmoLevel.values.get( Const.LEVEL_FIELD_DISPLAY_NAME );
      ogmoLevel.load( );

      // See Note [Process hierarchy]
      var level = new Level( levelName, levelDisplayName, world );
      world.addLevel( levelName, level );

      for ( layer in ogmoLevel.layers ) {
        layerCallbacks[ layer.name ]( world.getTileSet( layer.tileset )
                                    , layer, level );
      }
    }

    return world;
  }

  static function loadBackgroundLayer( tileset : TileSet
                                     , layer   : ogmo.Level.LayerDefinition
                                     , level   : Level ) : Void {
    LOGGER.debug( "Loading background layer" );

    if ( layer.data2D == null ) {
      throw new OGMOUtilsException( "No data2D in background layer for level "
                                  + level.displayName );
    }

    level.height = layer.gridCellsY;
    level.width  = layer.gridCellsX;
    level.gridY  = layer.gridCellHeight;
    level.gridX  = layer.gridCellWidth;

    var levelLayout : Array<Array<Int>> = layer.data2D;
    var background = new h2d.TileGroup( tileset.tile );
    background.x += layer.offsetX;
    background.y += layer.offsetY;

    for ( y in 0...levelLayout.length ) {
      for ( x in 0...levelLayout[ y ].length ) {
        if ( levelLayout[ y ][ x ] > -1 ) {
          background.add( x * layer.gridCellWidth
                        , y * layer.gridCellHeight
                        , tileset.getTile( levelLayout[ y ][ x ] ) );
        }
      }
    }
    level.setBackground( background );
  }

  static function loadCollisionsLayer( tileset : TileSet
                                     , layer   : ogmo.Level.LayerDefinition
                                     , level   : Level ) : Void {
    LOGGER.debug( "Loading collisions layer" );

    if ( layer.grid2D == null ) {
      throw new OGMOUtilsException( "No grid2D in collisions layer for level "
                                  + level.displayName );
    }
    level.height = layer.gridCellsY;
    level.width  = layer.gridCellsX;
    level.gridY  = layer.gridCellHeight;
    level.gridX  = layer.gridCellWidth;

    var collisionsLayout : Array<Array<String>> = layer.grid2D;
    @:privateAccess
      level.collisions = Utils.mkVector2D( level.height, level.width );

    for ( y in 0...collisionsLayout.length ) {
      for ( x in 0...collisionsLayout[ y ].length ) {
        level.setCollision( x, y,
          Collision.fromString( collisionsLayout[ y ][ x ] ) );
      }
    }
  }

  static function loadForegroundLayer( tileset : TileSet
                                     , layer   : ogmo.Level.LayerDefinition
                                     , level   : Level ) : Void {
    LOGGER.debug( "Loading foreground layer" );

    if ( layer.data2D == null ) {
      throw new OGMOUtilsException( "No data2D in foreground layer for level "
                                  + level.displayName );
    }

    var levelLayout : Array<Array<Int>> = layer.data2D;
    var foreground = new h2d.TileGroup( tileset.tile );
    foreground.x += layer.offsetX;
    foreground.y += layer.offsetY;

    for ( y in 0...levelLayout.length ) {
      for ( x in 0...levelLayout[ y ].length ) {
        if ( levelLayout[ y ][ x ] > -1 ) {
          foreground.add( x * layer.gridCellWidth
                        , y * layer.gridCellHeight
                        , tileset.getTile( levelLayout[ y ][ x ] ) );
        }
      }
    }
    level.setForeground( foreground );
  }
}
