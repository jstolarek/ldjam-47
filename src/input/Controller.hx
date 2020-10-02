// Game controller support
// =======================
//
// Implements game controller support: maintaining list of available devices,
// querying button presses, mapping between logical and physical buttons on a
// pad.
//
// (c) Jan Stolarek 2020, MIT License

package input;

// Note [ABXY button layout]
// =========================
//
// The following physical button layout is assumed:
//
//     Y
//   X   B
//     A
//
// A represents the bottom button, B represents the right button, X represents
// the left button, Y represents the top button.  This is regardless of labels
// on the pad itself as this is meant to be an internal representation.
// User-facing button labels are controlled via `hxd.PadConfig.names` entries.
// For example SNES controller will have logical button A labelled as "B", and B
// labelled as "A", and similarly for X and Y buttons.


// Note [Unimplemented controller features]
// ========================================
//
// Several features are still unimplemented at this point because I didn't need
// them:
//
//   * proper analog support.  At the moment both analog sticks and triggers are
//     treated in a binary way (pressed or not).  This needs a method that will
//     read `pad.values` and return a Float if it exceeds the `analogDeadZone`.
//
//   * single button press (reported only after button has been newly pressed)
//     and long button presses (recognizing that a button is being held for a
//     period of time).  At the moment this class only reports whether a button
//     is pressed at this moment, without taking any previous state into
//     account.  Doing this properly requires a `beforeUpdate` method that is
//     run in the process update loop before `update`.
//
//   * at the moment game assumes a single player.  Existing controller
//     management will require some adjusting to support two players, in
//     particular when it comes to managing controller assignment.  Things to
//     keep in mind:
//
//     - each player can have different input schemes in configuration
//     - players should be able to choose which pad to use (including none)


// Note [Logical and physical buttons]
// ===================================
//
// Different pads may report different indices of the same logical buttons.  For
// example, Logitech F310 reports buttons A, B, X and Y as 0, 1, 2, and 3,
// respectively, whereas Mayflash F101 reports these buttons as 1, 4, 0, and 3.
// The goal os for the application to operate on the logical buttons and not the
// physical ones.  Logical buttons are defined as `PadKey` enum and are meant to
// be used throughout the application, in particular in the `Player` class.  The
// mapping from logical buttons to physical buttons is done via configuration
// `Config.PadConfig`.  The configuration is persisted in a *.json file loaded
// at game startup and then used to create a mapping for a controller based on
// its name (different pads can have different mappings).

class PadKeyException extends haxe.Exception {}

// Logical buttons recognized by the library
enum abstract PadKey(Int) from Int to Int {
  var NONE         = -1;

  var LEFT_AXIS_X  = 0;
  var LEFT_AXIS_Y  = 1;
  var RIGHT_AXIS_X = 2;
  var RIGHT_AXIS_Y = 3;

  // See Note [ABXY button layout]
  var A            = 4;
  var B            = 5;
  var X            = 6;
  var Y            = 7;

  var L1           = 8;
  var R1           = 9;
  var L2           = 10;
  var R2           = 11;
  var L3           = 12;
  var R3           = 13;

  var DPAD_UP      = 14;
  var DPAD_DOWN    = 15;
  var DPAD_LEFT    = 16;
  var DPAD_RIGHT   = 17;

  var SELECT       = 18;
  var START        = 19;
  var HOME         = 20;

  public static inline var length : Int = 21; // NONE not included in length

  @:to
  public function toString( ) : String {
    switch ( this ) {
      case NONE         : return "NONE";
      case LEFT_AXIS_X  : return "LEFT_AXIS_X";
      case LEFT_AXIS_Y  : return "LEFT_AXIS_Y";
      case RIGHT_AXIS_X : return "RIGHT_AXIS_X";
      case RIGHT_AXIS_Y : return "RIGHT_AXIS_Y";
      case A            : return "A";
      case B            : return "B";
      case X            : return "X";
      case Y            : return "Y";
      case L1           : return "L1";
      case R1           : return "R1";
      case L2           : return "L2";
      case R2           : return "R2";
      case L3           : return "L3";
      case R3           : return "R3";
      case DPAD_UP      : return "DPAD_UP";
      case DPAD_DOWN    : return "DPAD_DOWN";
      case DPAD_LEFT    : return "DPAD_LEFT";
      case DPAD_RIGHT   : return "DPAD_RIGHT";
      case SELECT       : return "SELECT";
      case START        : return "START";
      case HOME         : return "HOME";
      default           :
        throw new PadKeyException( "Unrecognised PadKey index: " + this );
    }
  }
}

class Controller {
  static var LOGGER = HexLog.getLogger( );
  static var AVAILABLE_DEVICES : Array<Controller> = null;

  var name    : String;
  var index   : Int;
  var pad     : hxd.Pad;
  var mapping : Vector<Int>;
  var buttons : Vector<String>;

  var analogDeadZone         : Float = 0.15;
  var analogAsButtonDeadZone : Float = 0.70;

  static var player (get, never) : Player;

  private function new( p : hxd.Pad ) {
    pad   = p;
    name  = pad.name;
    index = pad.index;

    var padConfig = Settings.getPadConfig( name );
    // See Note [Logical and physical buttons]
    mapping = new Vector<Int>( PadKey.length );
    mapping[ LEFT_AXIS_X  ] = padConfig.analogX;
    mapping[ LEFT_AXIS_Y  ] = padConfig.analogY;
    mapping[ RIGHT_AXIS_X ] = padConfig.ranalogX;
    mapping[ RIGHT_AXIS_Y ] = padConfig.ranalogY;
    mapping[ A            ] = padConfig.A;
    mapping[ B            ] = padConfig.B;
    mapping[ X            ] = padConfig.X;
    mapping[ Y            ] = padConfig.Y;
    mapping[ L1           ] = padConfig.LB;
    mapping[ R1           ] = padConfig.RB;
    mapping[ L2           ] = padConfig.LT;
    mapping[ R2           ] = padConfig.RT;
    mapping[ L3           ] = padConfig.analogClick;
    mapping[ R3           ] = padConfig.ranalogClick;
    mapping[ DPAD_UP      ] = padConfig.dpadUp;
    mapping[ DPAD_DOWN    ] = padConfig.dpadDown;
    mapping[ DPAD_LEFT    ] = padConfig.dpadLeft;
    mapping[ DPAD_RIGHT   ] = padConfig.dpadRight;
    mapping[ SELECT       ] = padConfig.back;
    mapping[ START        ] = padConfig.start;
    mapping[ HOME         ] = padConfig.home;

    buttons = new Vector<String>( PadKey.length );
    buttons[ LEFT_AXIS_X  ] = padConfig.names[ LEFT_AXIS_X  ];
    buttons[ LEFT_AXIS_Y  ] = padConfig.names[ LEFT_AXIS_Y  ];
    buttons[ RIGHT_AXIS_X ] = padConfig.names[ RIGHT_AXIS_X ];
    buttons[ RIGHT_AXIS_Y ] = padConfig.names[ RIGHT_AXIS_Y ];
    buttons[ A            ] = padConfig.names[ A            ];
    buttons[ B            ] = padConfig.names[ B            ];
    buttons[ X            ] = padConfig.names[ X            ];
    buttons[ Y            ] = padConfig.names[ Y            ];
    buttons[ L1           ] = padConfig.names[ L1           ];
    buttons[ R1           ] = padConfig.names[ R1           ];
    buttons[ L2           ] = padConfig.names[ L2           ];
    buttons[ R2           ] = padConfig.names[ R2           ];
    buttons[ L3           ] = padConfig.names[ L3           ];
    buttons[ R3           ] = padConfig.names[ R3           ];
    buttons[ DPAD_UP      ] = padConfig.names[ DPAD_UP      ];
    buttons[ DPAD_DOWN    ] = padConfig.names[ DPAD_DOWN    ];
    buttons[ DPAD_LEFT    ] = padConfig.names[ DPAD_LEFT    ];
    buttons[ DPAD_RIGHT   ] = padConfig.names[ DPAD_RIGHT   ];
    buttons[ SELECT       ] = padConfig.names[ SELECT       ];
    buttons[ START        ] = padConfig.names[ START        ];
    buttons[ HOME         ] = padConfig.names[ HOME         ];
  }

  public inline function isDummy( ) : Bool {
    return (this.index < 0);
  }

  public inline function isConnected( ) : Bool {
    return (pad != null && pad.connected);
  }

  public inline function isDown( key : PadKey ) : Bool {
    return ((key : Int) >= 0) && ((key : Int) < PadKey.length) &&
      switch ( key ) {
        case LEFT_AXIS_X, LEFT_AXIS_Y, RIGHT_AXIS_X, RIGHT_AXIS_Y, R2, L2 :
          isAnalogDown( key );
        default : pad.isDown( mapping[ key ] );
    }
  }

  // See Note [Unimplemented controller features]
  inline function isAnalogDown( key : PadKey ) : Bool {
    // assumes 0 <= key < PadKey.length
    return (Math.abs( pad.values[ mapping[ key ] ] ) > analogAsButtonDeadZone);
  }

  static inline function get_player( ) : Player {
    return Boot.ME.player;
  }

  // Static functions for managing connecting and disconnecting of controllers

  public static function getController( ) : Controller {
    if ( AVAILABLE_DEVICES == null ) {
      AVAILABLE_DEVICES = [];
      hxd.Pad.wait( onConnect );
    }

    var controller = AVAILABLE_DEVICES.shift( );

    if ( controller == null ) {
      LOGGER.info( "Creating dummy controller" );
      controller = new Controller( hxd.Pad.createDummy( ) );
    }

    return controller;
  }

  static function onConnect( pad : hxd.Pad ) : Void {
    var name  = pad.name;
    var index = pad.index;
    LOGGER.info( "Pad connected, name = " + name + ", index = " + index );
    var controller = new Controller( pad );
    AVAILABLE_DEVICES.push( controller );
    if ( player != null && !player.hasController( ) ) {
      LOGGER.info( "Assigning pad to player, name = " + name
                                       + ", index = " + index );
      player.controller = getController( );
    }

    pad.onDisconnect = function ( ) {
      LOGGER.info( "Pad disconnected, name = " + name  + ", index = " + index );
      AVAILABLE_DEVICES.remove( controller );
      // If this was an active pad assign a new one
      if ( player != null && !player.hasController( ) ) {
        player.controller = getController( );
      }
    }
  }
}
