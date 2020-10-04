// Application entry point
// =======================
//
// Entry point to the whole program.  Creates a heaps.io application (deriving
// from hxd.App) and sets up program-wide systems and settings (logging,
// resources, viewport scaling).  Finally, boots the game loop by creating a an
// instance of Boot class (a.k.a. pid 0 process).  Main class is a singleton,
// and also provides several convenience functions to get access to
// application-wide parameters (wanted FPS, window dimensions, etc).
//
// (c) Jan Stolarek 2020, MIT License

import hex.log.configuration.*;
import hex.log.layout.*;
import hex.log.target.*;

#if ( !( hl || js ) )
#error "Error: you must use either Hashlink (hl) or JavaScript (js) tagret"
#end

#if ( !( devel || release ))
#error "Error: define \"devel\" or \"release\" build"
#end

// Note [Logger setup]
// ===================
//
// By default root logger logs everything in a development build and nothing in
// release build.  To define specific rules for a logger or group of loggers use
// the following formula:
//
//   #if ( devel )
//   var loggerConfig = LoggerConfig.createLogger
//     ( "assets", LogLevel.WARN, loggerConfiguration, null );
//   loggerConfig.addLogTarget( traceTarget, LogLevel.WARN, null );
//   loggerConfiguration.addLogger( loggerConfig.name, loggerConfig );
//   #end
//
// where "assets" says that the configuration applied to all loggers inside the
// assets package, and LogLevel.WARN specifies a logging level.  Note that
// logging level is repeated twice: once for the logger itself and once for a
// logging target.  The lower of the two is applied.  These definitions need to
// be placed after the root logger has been defined but before the configuration
// has been set in the LoggerContext.  Wrapping the definitions inside #if-#end
// pragmas ensures that the logger will only be used for a development build and
// not the release build.


// Note [Resource finalization]
// ============================
//
// Sometimes it might be necessary to explicitly finalize and release some of
// the resources on application close.  One problem I personally encountered was
// a segmentation fault on Linux when the game music was not explicitly disposed
// via a call to `.sound.dispose` methods of a music resource.  Such resource
// releasing can be implemented inside this handler.  Note that the `onClose`
// handler is only called when an application is closed via Alt+F4 or clicking
// the `x` button of a window.  It does not trigger when an application is
// closed with a call to `hxd.System.exit()`.


// Note [Bullet time]
// ==================
//
// Development builds allow to manipulate game time using numeric keyboard:
//
//   * `+` and `-` speed up and slow down time flow
//   * Enter pauses/unpauses the game
//   * pressing 0 while the game is paused will advance to next fixed update
//     (with default settings these are two frames)

class Main extends hxd.App {
  public static var ME : Main = null;
         static var LOGGER    = HexLog.getLogger();

  // Properties for convenience
  public var wantedFPS  (get, never) : Float;
  public var width      (get, never) : Int;
  public var height     (get, never) : Int;
  public var fullscreen (get, never) : Bool;

#if ( devel )
  var speed  = 1.0;
  var paused = false;
#end

#if ( js )
  public static var canvas =
    js.Browser.document.getElementById( Const.JS_CANVAS );
#end

  function new( ) {
    super( );
    ME = this;
  }

  override function init( ) {
    hxd.Window.getInstance( ).title = "Game Stub"; // FIXME: set the game name

    // Initialize logging
    var loggerConfiguration = new BasicConfiguration();
    var traceLogLayout      = new DefaultTraceLogLayout();
    var traceTarget         = new TraceLogTarget( "", null, traceLogLayout );
#if ( devel )
    var rootLoggerConfig    = LoggerConfig.createRootLogger( LogLevel.ALL );
    // v- PLAYER-ONLY DEBUGGING (use "en" for managers etc)
    //var rootLoggerConfig    =  LoggerConfig.createLogger( "Player", LogLevel.DEBUG, loggerConfiguration, null );
#elseif ( release )
    var rootLoggerConfig    = LoggerConfig.createRootLogger( LogLevel.OFF );
#end

    rootLoggerConfig.addLogTarget( traceTarget, LogLevel.ALL, null );
    loggerConfiguration.addLogger( rootLoggerConfig.name, rootLoggerConfig );

    // See Note [Logger setup]
    LoggerContext.getContext().setConfiguration( loggerConfiguration );

    // Initialize resources
    LOGGER.info( "Initializing resource manager" );
#if ( js )
    hxd.Res.initEmbed( );
#elseif ( devel )
    hxd.Res.initLocal( );
#elseif ( release )
    hxd.Res.initPak( );
#end

    // Init various subsystems
    Settings.init( );
    Fonts.init( );

    // Engine settings
    s2d.scaleMode = LetterBox( Const.CANVAS_WIDTH, Const.CANVAS_HEIGHT, false
                             , Center, Center);
    hxd.Timer.wantedFPS = Const.WANTED_FPS;
    engine.fullScreen   = Settings.fullscreen;

    // Setup application onClose handle.  See Note [Resource finalization]
    hxd.Window.getInstance( ).onClose = function ( ) {
      LOGGER.info( "Closing application window" );
      Settings.save( );
      return true;
    };

    new Boot( ).show( 0 );
  }

  public inline function get_wantedFPS( ) : Float {
    return hxd.Timer.wantedFPS;
  }

  public inline function get_width( ) : Int {
    return Const.CANVAS_WIDTH;
  }

  public inline function get_height( ) : Int {
    return Const.CANVAS_HEIGHT;
  }

  public inline function get_fullscreen( ) : Bool {
#if ( hl )
    return h3d.Engine.getCurrent( ).fullScreen;
#elseif ( js )
    return js.Browser.document.fullscreen;
#end
  }

  public static function toggleFullscreen( ) : Void {
#if ( js )
    if ( ME.fullscreen ) {
      LOGGER.info( "Exiting fullscreen" );
      js.Browser.document.exitFullscreen();
    } else {
      LOGGER.info( "Entering fullscreen" );
      js.Browser.document.getElementById( Const.JS_CANVAS ).requestFullscreen();
    }
#elseif ( hl )
    LOGGER.info( h3d.Engine.getCurrent( ).fullScreen ? "Exiting fullscreen"
                                                     : "Entering fullscreen" );
    h3d.Engine.getCurrent( ).fullScreen = !h3d.Engine.getCurrent( ).fullScreen;
#end
    Settings.toggleFullscreen( );
  }

  override function update( _ : Float ) {
#if ( devel )
    // See Note [Bullet time]
    if ( hxd.Key.isPressed( hxd.Key.NUMPAD_ENTER ) ) {
      LOGGER.debug( "Toggling debug pause" );
      paused = !paused;
    }

    if ( hxd.Key.isPressed( hxd.Key.NUMPAD_ADD ) ) {
      speed += 0.2;
      LOGGER.debug( "Game speed set to " + speed );
    }

    if ( hxd.Key.isPressed( hxd.Key.NUMPAD_SUB ) ) {
      speed = Math.max( speed - 0.2, 0 );
      LOGGER.debug( "Game speed set to " + speed );
    }

    if ( paused ) {
      if ( hxd.Key.isPressed( hxd.Key.NUMPAD_0 ) ) {
        hxd.Timer.tmod = Const.FIXED_FPS_RATIO;
      } else {
        hxd.Timer.tmod = 0;
      }
    }

    hxd.Timer.dt *= speed;
#end

    super.update( hxd.Timer.dt );

    // See Note [Process loop]
    Process.updateAll( hxd.Timer.tmod );
  }

  override function onResize() {
    super.onResize( );
    Process.resizeAll( );
  }

  static function main( ) {
    new Main( );
  }
}
