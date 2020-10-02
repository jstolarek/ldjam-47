// Game world
// ==========
//
// Maintains the whole structure of a game world.  In particular, stores the
// list of levels and manages switching between them.
//
// (c) Jan Stolarek 2020, MIT License

package world;

// Note [Empty initial level]
// ==========================
//
// After the world is loaded from assets there is no `currentLevel`.  It is
// necessary to call `setCurrentLevel` before the game begins.

class WorldException extends haxe.Exception {}

class World extends Process {
  static var LOGGER = HexLog.getLogger();

  // rendering layers
  static var _inc = 0;
  public static var LEVEL_LAYER = _inc++;

  public var currentLevel (default, null) : Null<Level>;
         var tilesets                     : Map<String, TileSet>;
         var levels                       : Map<LevelName, Level>;

  public function new( ?parent  : Process ) {
    super( parent );

    this.tilesets     = new Map<String   , TileSet>();
    this.levels       = new Map<LevelName, Level  >();
    this.currentLevel = null; //See Note [Empty initial level]
  }

  public function addLevel( levelName : LevelName, level : Level ) : Void {
    if ( levels.exists( levelName ) ) {
      throw new WorldException( "Level \"" + levelName + "\" already exists" );
    }

    levels.set( levelName, level );
    addChild( level ); // process hierarchy
  }

  public inline function addTileSet( name : String, tileset : TileSet ) : Void {
    tilesets.set( name, tileset );
  }

  public inline function getTileSet( name : String ) : TileSet {
    return tilesets.get( name );
  }

  public function setCurrentLevel( levelName : LevelName ) : Void {
    LOGGER.info( "Setting current level: " + levelName );

    if ( currentLevel != null ) {
      hideChild( currentLevel );
    }
    currentLevel = levels.get( levelName );
    showChild( currentLevel, LEVEL_LAYER );
  }
}
