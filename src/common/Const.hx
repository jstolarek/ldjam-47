// Game-wide constants
// ===================
//
// So that there's a single place to tweak things.
//
// (c) Jan Stolarek 2020, MIT License

package common;

// Note [OGMO level constants]
// ===========================
//
// Several types of OGMO level constants must be defined and synchronized with
// constants used in OGMO project files in order for level loading to work
// correctly:
//
//  * `LAYER_*` need to correspond to layer names
//  * `LEVEL_FIELD_*` need to correspond to extra level values

// Note [Canvas size]
// ==================
//
// Canvas size is expressed in logical pixels.  It can be arbitrary, but as a
// convenient simplification it is expresses as the tile count multiplied by
// grid size.  The lattaer is assumed to be 16 as default. This value is
// intended to be the same as the same as grid size assumed in assets (OGMO
// levels in particular), but this is not enforced or required in any way.

class Const {

  // LDJAM-47 GAME CONSTANTS
  public static inline var PLAYER_SPEED            = 0.15;
  public static inline var MANAGER_BASE_SPEED      = 0.12;
  public static inline var MANAGER_ALARMED_SPEED   = 0.15;
  public static inline var MANAGER_TARGET_DEADZONE = 2;
  public static inline var COFFEE_SPEED_BOOST_FACTOR = 2;
  public static inline var COFFEE_BOOST_DURATION   = 5000; // in miliseconds

  // OGMO CONSTANTS.  See Note [OGMO level constants]
  // Layer names
  public static inline var LAYER_BG    = "background";
  public static inline var LAYER_COLLS = "collisions";
  public static inline var LAYER_FG    = "foreground";
  // Custom values available for levels
  public static inline var LEVEL_FIELD_NAME         = "name";
  public static inline var LEVEL_FIELD_DISPLAY_NAME = "display_name";

  // RENDERING SETTINGS
  // Rendering canvas size in logical pixels.  See Note [Canvas size].
  public static inline var CANVAS_WIDTH  = 32 * 16;
  public static inline var CANVAS_HEIGHT = 18 * 16;
  // Camera speeds.  See Note [Camera movement wobble]
  public static inline var CAMERA_SPEED        = 0.04;
  public static inline var CAMERA_SPEED_CUTOFF = 0.0001;
  public static inline var CAMERA_FRICTION     = 0.8;
  public static inline var CAMERA_DEADZONE     = 1;

  // DEFAULT PHYSICS SETTINGS
  // Speed attenuation
  public static inline var FRICTION     = 0.8;
  // Minimal speed.  If speed gets smaller it is set to 0
  public static inline var SPEED_CUTOFF = 0.001;

  // ENGINE CONSTANTS
  // Desired refresh rate.  Assigned to hxd.Timer.wantedFPS on startup
  public static inline var WANTED_FPS  = 60;
  // Desired game logic update frequency.  See Note [Process loop]
  public static inline var FIXED_FPS   = 30;
  // Overrides 15 frames per second defined in h2d.Anim.new( ... )
  public static inline var ANIM_SPEED  = 20;
  // Canvas name defined in index.html
  public static inline var JS_CANVAS   = "webgl";
  // Message timeout in graphical console
  public static inline var LOG_TIMEOUT = 5;

  // Derived constants
  public static var FIXED_FPS_RATIO   = Const.WANTED_FPS / Const.FIXED_FPS;
  public static var COMMIT_HASH_FULL  = Utils.getGitCommitHash( );
  public static var COMMIT_HASH       = COMMIT_HASH_FULL.substr( 0, 8 );

  // CONFIG CONSTANTS
  // Configuration file
  public static var CONFIG_FILE = "config.json";
  // Number of messages displayed in graphical console.
  // See Note [Limiting console slowdowns]
  public static var LOG_MAX_SIZE = 500; // if number of messages exceeds this...
  public static var LOG_MIN_SIZE = 20;  // ...then to this number of messages
}
