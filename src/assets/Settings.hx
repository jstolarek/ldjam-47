// Configuration
// =============
//
// Support for loading and saving game configuration to a file.
//
// (c) Jan Stolarek 2020, MIT License

package assets;

// Note [Configuration on JavaScript target]
// =========================================
//
// On JavaScript target there's no way to load or save configuration from the
// file system.  Therefore the game always uses the default, hardcoded
// configuration and there is no configuration saving at all.

typedef PadConfig =
  { analogX      : Int
  , analogY      : Int
  , ranalogX     : Int
  , ranalogY     : Int
  , A            : Int
  , B            : Int
  , X            : Int
  , Y            : Int
  , LB           : Int
  , RB           : Int
  , LT           : Int
  , RT           : Int
  , back         : Int
  , home         : Int
  , start        : Int
  , analogClick  : Int
  , ranalogClick : Int
  , dpadUp       : Int
  , dpadDown     : Int
  , dpadLeft     : Int
  , dpadRight    : Int
  , names        : Array<String>
  }

typedef SettingsData =
  { padDB          : Map<String, PadConfig>
  , keyInputScheme : Player.InputScheme<Int>
  , padInputScheme : Player.InputScheme<Controller.PadKey>
  , fullscreen     : Bool
  }

class Settings {
  static var LOGGER            = HexLog.getLogger( );
  static var ME : Settings     = null;
  var changed   : Bool         = false;
  var settings  : SettingsData = null;

  // Proxy properties redirecting to Settings
  public static var fullscreen     (get, never) : Bool;
  public static var keyInputScheme (get, never) : Player.InputScheme<Int>;
  public static var padInputScheme (get, never) :
    Player.InputScheme<Controller.PadKey>;

  private function new( ) { }

  public static function init( ) : Settings {
    if ( ME == null ) {
      ME = new Settings( );
#if ( hl )
      if ( sys.FileSystem.exists( Const.CONFIG_FILE ) ) {
        LOGGER.info( "Loading configuration from file: " + Const.CONFIG_FILE );
        var jsonString = sys.io.File.getContent( Const.CONFIG_FILE );
        ME.settings    = haxe.Json.parse( jsonString );

        // reconstruct maps
        ME.settings.padDB = Utils.parseJSONMap( ME.settings, "padDB" );
      } else {
        LOGGER.info( "Creating default configuration" );
        initDefaultSettings( );
        save( );
      }
#elseif ( js )
      // See Note [Configuration on JavaScript target]
      initDefaultSettings( );
#end
    }
    return ME;
  }

  // Save configuration only if changed
  public static inline function save( ) : Void {
    if ( ME.changed ) {
      forceSave( );
    }
  }

  public static inline function toggleFullscreen( ) : Void {
    ME.settings.fullscreen = !ME.settings.fullscreen;
    ME.changed = true;
  }

  // Save configuration unconditionally
  public static inline function forceSave( ) : Void {
#if ( hl )
    LOGGER.info( "Saving configuration to file: " + Const.CONFIG_FILE );
    sys.io.File.saveContent( Const.CONFIG_FILE
                           , haxe.Json.stringify( ME.settings, "  " ) );
#end
    ME.changed = false;
  }

  public static inline function markChanged( ) : Void {
    ME.changed = true;
  }

  private static function initDefaultSettings( ) : Void {
    var defaultControllerName = "XInput Controller";
    var defaultPadDB          = new Map<String, PadConfig>();
    defaultPadDB.set( defaultControllerName, defaultPadConfig( ) );

    var defaultKeyInputScheme =
      { up     : hxd.Key.UP
      , down   : hxd.Key.DOWN
      , left   : hxd.Key.LEFT
      , right  : hxd.Key.RIGHT
      , jump   : hxd.Key.SPACE
      , attack : hxd.Key.LSHIFT
      };

    var defaultPadInputScheme =
      { up     : Controller.PadKey.DPAD_UP
      , down   : Controller.PadKey.DPAD_DOWN
      , left   : Controller.PadKey.DPAD_LEFT
      , right  : Controller.PadKey.DPAD_RIGHT
      , jump   : Controller.PadKey.B
      , attack : Controller.PadKey.A
      };

    ME.settings =
      { padDB          : defaultPadDB
      , keyInputScheme : defaultKeyInputScheme
      , padInputScheme : defaultPadInputScheme
#if ( hl && release )
      , fullscreen     : true
#else
      , fullscreen     : false
#end
      };
  }

  public static inline function get_fullscreen( ) : Bool {
    return ME.settings.fullscreen;
  }

  public static inline function get_keyInputScheme( ) {
    return ME.settings.keyInputScheme;
  }

  public static inline function get_padInputScheme( ) {
    return ME.settings.padInputScheme;
  }

  public static function getPadConfig( name : String ) : PadConfig {
    if ( !ME.settings.padDB.exists( name ) ) {
      LOGGER.debug( "Creating default configuration for pad: " + name );
      ME.settings.padDB.set( name, defaultPadConfig( ) );
    }

    return ME.settings.padDB.get( name );
  }

  private static function defaultPadConfig( ) : PadConfig {
    var defaultPadConfig : PadConfig =
#if ( hl )
      { analogX      : 0
      , analogY      : 1
      , ranalogX     : 2
      , ranalogY     : 3
      , A            : 6
      , B            : 7
      , X            : 8
      , Y            : 9
      , LB           : 15
      , RB           : 16
      , LT           : 4
      , RT           : 5
      , back         : 10
      , home         : 11
      , start        : 12
      , analogClick  : 13
      , ranalogClick : 14
      , dpadUp       : 17
      , dpadDown     : 18
      , dpadLeft     : 19
      , dpadRight    : 20
#elseif ( js )
      { analogX      : 17
      , analogY      : 18
      , ranalogX     : 19
      , ranalogY     : 20
      , A            : 0
      , B            : 1
      , X            : 2
      , Y            : 3
      , LB           : 4
      , RB           : 5
      , LT           : 6
      , RT           : 7
      , back         : 8
      , home         : 16
      , start        : 9
      , analogClick  : 10
      , ranalogClick : 11
      , dpadUp       : 12
      , dpadDown     : 13
      , dpadLeft     : 14
      , dpadRight    : 15
#end
      , names        : [ "Left analog X" , "Left analog Y" ,
                         "Right analog X", "Right analog Y",
                         "A", "B", "X", "Y",
                         "Left Bumper"      , "Right Bumper",
                         "Left Trigger"     , "Right Trigger" ,
                         "Left Analog Click", "Right Analog Click",
                         "D-Pad Up", "D-Pad Down", "D-Pad Left", "D-Pad Right",
                         "Back", "Home", "Start"
                       ]
      };

    return defaultPadConfig;
  }
}
