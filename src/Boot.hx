// Game entry point
// ================
//
// Initializes game logic.  Once fully implemented it is intended to manage
// transitions between game menu, and various game states (intro, main game
// loop, pause menu, score screen, etc).
//
// (c) Jan Stolarek 2020, MIT License

// Note [World before entities]
// ============================
//
// Entities read grid size from the current level.  This means that a current
// level must be set before Entities are used.

import en.Manager; //FIXME: force compilation
import en.interactables.*;

class Boot extends Process {
  public static var ME : Boot = null;
         static var LOGGER    = HexLog.getLogger();

  // rendering layers
  static var _inc : Int = 0;
  public static var WORLD_LAYER   = _inc++;
  public static var ENTITY_LAYER  = _inc++;
  public static var GUI_LAYER     = _inc++;
  public static var CONSOLE_LAYER = _inc++;
  // Properties for convenience
  public var player  (default, null) : Player  = null;
  public var world   (default, null) : World   = null;
  public var camera  (default, null) : Camera  = null;
  // debugging console
  public var console (default, null) : Console = null;

  var hud : Hud = null;

  public function new ( ) {
    super( );
    ME = this;

#if ( js )
    Main.canvas.addEventListener( "keydown", function ( e ) {
        if ( ( e.keyCode == hxd.Key.ENTER && e.altKey )
            || e.keyCode == hxd.Key.F11 ) {
          Main.toggleFullscreen( );
        }
      });
#end

    // Create debugging console, plug directly to top-level scene
    var consoleLayer = new h2d.Object( );
    Main.ME.s2d.add( consoleLayer, CONSOLE_LAYER );
    console = new Console( Fonts.barlow18, 0xFFFF00, consoleLayer );

    // See Note [World before entities]
    world = new World( this );
    showChild( world, WORLD_LAYER );
    OGMOUtils.loadWorld(   hxd.Res.office
                       , [ hxd.Res.levels.open_space_1 ]
                       , world );
    world.setCurrentLevel( LevelName.OPEN_SPACE_1 );

    player = new Player( );

    var coffee = new Coffee( 1, 3, player );
    layers.add( coffee.layers, ENTITY_LAYER );

    var key = new Key( 14, 6, player );
    layers.add( key.layers, ENTITY_LAYER );

    layers.add( player.layers, ENTITY_LAYER );

    camera = new Camera( );
    camera.target = player;

    hud = new Hud( );
    hud.show( GUI_LAYER );

    world.currentLevel.addManager( new Manager( world.currentLevel, 1, 2,
        [ { x : 7, y : 2 }, { x : 7, y : 6 }
        , { x : 1, y : 6 }, { x : 1, y : 2 } ]
      ) );
  }

  override function update( ) {
#if ( hl )
    if ( ( hxd.Key.isPressed( hxd.Key.ENTER ) && hxd.Key.isDown( hxd.Key.ALT ) )
        || hxd.Key.isPressed( hxd.Key.F11 ) ) {
      Main.toggleFullscreen( );
    }
#end

    if ( hxd.Key.isPressed( hxd.Key.QWERTY_TILDE ) ) {
      if ( console != null && console.isActive( ) ) {
        LOGGER.debug( "Hiding debugging console" );
        console.hide( );
      } else {
        LOGGER.debug( "Showing debugging console" );
        console.show( );
      }
    }
  }
}
