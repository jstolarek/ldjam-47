// Player
// ======
//
// Implements mapping between player actions and logical controller
// buttons/keyboard keys.
//
// (c) Jan Stolarek 2020, MIT License

import ui.Console;

class PlayerException extends haxe.Exception {}

// List of primitive actions that a player can input via keyboard or controller
enum abstract Action(Int) from Int to Int {
  var UP;
  var DOWN;
  var LEFT;
  var RIGHT;
  var ATTACK; //maybe later: interact

  public static inline var length : Int = 6;

  @:to
  public function toString( ) : String {
    switch ( this ) {
      case UP     : return "UP"    ;
      case DOWN   : return "DOWN"  ;
      case LEFT   : return "LEFT"  ;
      case RIGHT  : return "RIGHT" ;
      case ATTACK : return "ATTACK";
      default     :
        throw new PlayerException( "Unrecognised player action: " + this );
    }
  }
}

// list of states a player can be in
// Describes animation state
enum abstract State(Int) from Int to Int {
  var IDLE;
  var WALK_UP;
  var WALK_DOWN;
  var WALK_RIGHT;
  var WALK_LEFT;
  var WALK_UP_RIGHT;
  var WALK_UP_LEFT;
  var WALK_DOWN_RIGHT;
  var WALK_DOWN_LEFT;

  public static inline var length : Int = 2;

  @:to
  public function toString( ) : String {
    switch ( this ) {
      case IDLE            : return "idle";
      case WALK_UP         : return "walk_up";
      case WALK_DOWN       : return "walk_down";
      case WALK_RIGHT      : return "walk_right";
      case WALK_LEFT       : return "walk_left";
      case WALK_UP_RIGHT   : return "walk_up_right";
      case WALK_UP_LEFT   : return "walk_up_left";
      case WALK_DOWN_RIGHT : return "walk_down_right";
      case WALK_DOWN_LEFT : return "walk_down_left";
      default   :
        throw new PlayerException( "Unrecognised player state: " + this );
    }
  }

  @:from
  public static function fromString( str : String ) : State {
    switch ( str ) {
      case "idle": return IDLE;
      case "walk_up": return WALK_UP;
      case "walk_down": return WALK_DOWN;
      case "walk_right": return WALK_RIGHT;
      case "walk_left": return WALK_LEFT;
      case "walk_up_right": return WALK_UP_RIGHT;
      case "walk_up_left": return WALK_UP_LEFT;
      case "walk_down_right": return WALK_DOWN_RIGHT;
      case "walk_down_left": return WALK_DOWN_LEFT;
      default   :
        throw new PlayerException( "Unrecognised player state: " + str );
    }
  }
}

typedef InputScheme<T> =
  { up     : T
  , down   : T
  , left   : T
  , right  : T
  , jump   : T
  , attack : T
  }

class Player extends Entity<State, String> {
  static var LOGGER = HexLog.getLogger( );

  // Player input
  public var keyInputs  : InputScheme<Int>;
  public var padInputs  : InputScheme<Controller.PadKey>;
  public var controller : Controller;
         var direction  : Direction;
         var actions    : Vector<Bool>;

  // Properties for convenience
  var console (get, never) : Console;

  public function new( ?parent : Process ) {
    super( parent );

    keyInputs  = Settings.keyInputScheme;
    padInputs  = Settings.padInputScheme;
    controller = Controller.getController( );
    actions    = new Vector<Bool>( Action.length );
    // starting coordinates
    cx = 6;
    cy = 8;

    resetActions( );
    setAnimations();

    // FIXME: hack for prototyping purposes
    animation.scaleX = 2;
    animation.scaleY = 2;
  }

  override function fixedUpdate( ) {
    if ( isAction( UP ) ) {
      vy = -Const.PLAYER_SPEED;
    }

    if ( isAction( DOWN ) ) {
      vy = Const.PLAYER_SPEED;
    }

    if ( isAction( LEFT ) ) {
      vx = -Const.PLAYER_SPEED;
    }

    if ( isAction( RIGHT ) ) {
      vx = Const.PLAYER_SPEED;
    }

    setDebugLabel( "(x=" + Std.string( Math.floor( x ) ) +
                  ", y=" + Std.string( Math.floor( y ) ) + ")", 0x66dd99 );
    // END TEST STUFF

    xr += vx;
    yr += vy;

    handleCollisions( );
    applySpeedFriction( );
  }

  private inline function setAnimations() : Void {
    // BEGIN TEST STUFF
    animation.stateAnims =
      Aseprite.loadStateAnimation( "player", State.fromString );
    animation.pivot = new Animation.Pivot( 0.5, 1, true );

    animation.registerStateAnimation( WALK_UP, 1, function ( ) {
      return actions[ UP ];
    } );

    animation.registerStateAnimation( WALK_DOWN, 1, function ( ) {
      return actions[ DOWN ];
    } );

    animation.registerStateAnimation( WALK_RIGHT, 1, function ( ) {
      return actions[ RIGHT ];
    } );

    animation.registerStateAnimation( WALK_LEFT, 1, function ( ) {
      return actions[ LEFT ];
    } );

    animation.registerStateAnimation( WALK_UP_RIGHT, 1, function ( ) {
        return actions[ UP ] && actions[ RIGHT ];
      } );

    animation.registerStateAnimation( WALK_DOWN_RIGHT, 1, function ( ) {
      return actions[ DOWN ] && actions[ RIGHT ];
    } );

    animation.registerStateAnimation( WALK_UP_LEFT, 1, function ( ) {
      return actions[ UP ] && actions[ LEFT ];
    } );

    animation.registerStateAnimation( WALK_DOWN_LEFT, 1, function ( ) {
      return actions[ DOWN ] && actions[ LEFT ];
    } );

    animation.registerStateAnimation( IDLE, 0, function ( ) {
      return true;
    } );
  }

  override inline function hasCircCollWith<S, T>(e: Entity<S, T>) {
    if( Std.is(e, Manager) ) return true;
    return false;
  }

  private inline function handleCollisions( ) : Void {
    if ( xr > 0.4 && level.hasDeskCollision( cx + 1, cy ) ) {
      xr = 0.4;
      if ( vx > 0 ) {
        vx /= 4;
      }
    }

    if ( xr >= 0.3 && level.hasDeskCollision( cx + 1, cy ) ) {
      if ( vx > 0 ) {
        vx /= 2;
      }
    }
/*
*/

    if ( xr < 0.1 && level.hasDeskCollision( cx - 1, cy ) ) {
      xr = 0.1;
      if ( vx < 0 ) {
        vx /= 4;
      }
    }

/*
    if ( xr < 0.4 && level.hasDeskCollision( cx - 1, cy ) ) {
      if ( vx < 0 ) {
        vx/=2;
      }
    }
*/

    if ( yr > 0.4 && level.hasDeskCollision( cx, cy + 1 ) ) {
      yr = 0.4;
      if ( vy > 0 ) {
        vy /= 4;
      }
    }


    if ( yr < 0.6 && level.hasDeskCollision( cx, cy ) ) {
      yr = 0.6;
      if ( vy < 0 ) {
        vy /= 4;
      }
    }
  }

  private inline function resetActions( ) : Void {
    for ( i in 0...actions.length ) {
      actions[ i ] = false;
    }
  }

  public inline function hasController( ) : Bool {
    return ( controller != null && controller.isConnected( ) &&
            !controller.isDummy( ) );
  }

  override function update( ) {
    if ( !(console.isActive( ) && console.hasFlag( Flag.EXCLUSIVE_FOCUS ) ) ) {
      actions[ UP     ] = isKeyDown( keyInputs.up    , padInputs.up     );
      actions[ DOWN   ] = isKeyDown( keyInputs.down  , padInputs.down   );
      actions[ LEFT   ] = isKeyDown( keyInputs.left  , padInputs.left   );
      actions[ RIGHT  ] = isKeyDown( keyInputs.right , padInputs.right  );
      actions[ ATTACK ] = isKeyDown( keyInputs.attack, padInputs.attack );
    } else {
      resetActions( );
    }

    super.update( );
    cooldown.update( Process.TMOD );
  }

  public inline function isAction( action : Action ) : Bool {
    return actions[ action ];
  }

  inline function isKeyDown( keyboardKey   : Int
                           , controllerKey : Controller.PadKey ) : Bool {
    return hxd.Key.isDown( keyboardKey )
        || controller.isDown( controllerKey );
  }

  inline function get_console( ) : Console {
    return Boot.ME.console;
  }
}
