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

class Player extends Entity<State, String> implements Resetable {
  static var LOGGER = HexLog.getLogger( );

  // Player input
  public var keyInputs  : InputScheme<Int>;
  public var padInputs  : InputScheme<Controller.PadKey>;
  public var controller : Controller;
         var direction  : Direction;
         var actions    : Vector<Bool>;
  public var speed      : Float;
         var startX     : Int = 12;
         var startY     : Int = 1;

  var collisionBox      : Rect;

  var left    (get, never) : Float; inline function get_left()    { return x    + collisionBox.x;         }
  var up      (get, never) : Float; inline function get_up()      { return y    + collisionBox.y;         }
  var right   (get, never) : Float; inline function get_right()   { return left + collisionBox.w;         }
  var down    (get, never) : Float; inline function get_down()    { return up   + collisionBox.h;         }
  var leftCx  (get, never) : Int;   inline function get_leftCx()  { return Math.floor( left  / gx );      }
  var upCx    (get, never) : Int;   inline function get_upCx()    { return Math.floor( up    / gy );      }
  var rightCx (get, never) : Int;   inline function get_rightCx() { return Math.floor( right / gx );      }
  var downCx  (get, never) : Int;   inline function get_downCx()  { return Math.floor( down  / gy );      }
  var leftXr  (get, never) : Float; inline function get_leftXr()  { return (left  - (leftCx  * gx)) / gx; }
  var upYr    (get, never) : Float; inline function get_upYr()    { return (up    - (upCx    * gy)) / gy; }
  var rightXr (get, never) : Float; inline function get_rightXr() { return (right - (rightCx * gx)) / gx; }
  var downYr  (get, never) : Float; inline function get_downYr()  { return (down  - (downCx  * gy)) / gy; }

  // Properties for convenience
  var console (get, never) : Console;

  public var unnoticed     : Bool;
  public var working     : Bool;

  public function new( ?parent : Process ) {
    super( parent );

    keyInputs  = Settings.keyInputScheme;
    padInputs  = Settings.padInputScheme;
    controller = Controller.getController( );
    actions    = new Vector<Bool>( Action.length );
    unnoticed = true;
    working = false;

    // starting coordinates
    cx = startX;
    cy = startY;
    yr = 0.25;
    speed = Const.PLAYER_SPEED;

    collisionBox = { x : 6, y : 24, w : 19, h : 7 };

    resetActions( );
    setAnimations();

#if ( devel )
    var collisionBoxRect = new h2d.Graphics( );
    collisionBoxRect.beginFill( 0xFFFF0000 );
    collisionBoxRect.drawRect( collisionBox.x, collisionBox.y
                             , collisionBox.w, collisionBox.h );
    collisionBoxRect.endFill( );
    layers.add( collisionBoxRect, Entity.DEBUG_LAYER );
#end
  }

  override function fixedUpdate( ) {
    vx = vy = 0.0; // either this of applySpeedFriction below

    if ( isAction( UP ) ) {
      if ( y > 0 ) {
        vy = -speed;
      }
    }

    if ( isAction( DOWN ) ) {
      if ( y < ( level.height - 1 ) * gy ) {
        vy = speed;
      }
    }

    if ( isAction( LEFT ) ) {
      if ( x > 0 ) {
        vx = -speed;
      }
    }

    if ( isAction( RIGHT ) ) {
      if ( x < ( level.width - 1 ) * gx ) {
        vx = speed;
      }
    }

    setDebugLabel( "(x=" + Utils.floatToString( cx + xr, 2 ) +
                  ", y=" + Utils.floatToString( cy + yr, 2 ) + ")", 0x66dd99 );

    xr += vx;
    yr += vy;

    if ( x < 0 ) {
      xr = 0.0;
      vx = 0.0;
      cx = 0;
    }

    if ( y < 0 ) {
      yr = 0.0;
      vy = 0.0;
      cy = 0;
    }

    handleCollisions( );
    checkIfWorking( );
//    applySpeedFriction( );
  }

  private inline function setAnimations() : Void {
    animation.stateAnims =
      Aseprite.loadStateAnimation( "player", State.fromString );
//    animation.pivot = new Animation.Pivot( 0.5, 0.5, true );

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

    // if moving up then check collisions of both upper corners
    if ( vy < 0 && ( level.hasDeskCollision( leftCx , upCx ) ||
                     level.hasDeskCollision( rightCx, upCx ) ) ) {
      yr -= vy;
      vy = 0.0; // stop
      //cy = upCx;
      //yr = 0.25;
    }

    // if moving down check collisions on both lower corners
    if ( vy > 0 && ( level.hasDeskCollision( leftCx , downCx ) ||
                     level.hasDeskCollision( rightCx, downCx ) ) ) {
      yr -= vy;
      vy = 0.0; // stop
//      cy = downCx - 1;
//      yr = 0.0;
    }

    // if moving left check collisions on both left corners
    if ( vx < 0 && ( level.hasDeskCollision( leftCx, downCx ) ||
                     level.hasDeskCollision( leftCx, upCx   ) ) ) {
      xr -= vx;
      vx = 0.0; // stop
//      cx = leftCx;
//      xr = 0.85;
    }

    // if moving right check collisions on both right corners
    if ( vx > 0 && ( level.hasDeskCollision( rightCx, downCx ) ||
                     level.hasDeskCollision( rightCx, upCx   ) ) ) {
      xr -= vx;
      vx = 0.0; // stop
//      cx = rightCx - 1;
//      xr = 0.2;
    }

  }

  private inline function checkIfWorking( ) : Void {
    var atTheDesk = false;

    var collison_upper = level.isWithinWorkArea( leftCx , upCx ) || level.isWithinWorkArea( rightCx, upCx);
    var collision_lower = level.isWithinWorkArea( leftCx , downCx ) || level.isWithinWorkArea( rightCx, downCx);
    var collision_left = level.isWithinWorkArea( leftCx, downCx ) || level.isWithinWorkArea( leftCx, upCx);
    var collision_right = level.isWithinWorkArea( rightCx, downCx ) || level.isWithinWorkArea( rightCx, upCx);


    if (collison_upper || collision_lower || collision_left || collision_right) {
        atTheDesk = true;
    }

    working = atTheDesk;
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
    if ( !(console.isActive( ) && console.hasFlag( Flag.EXCLUSIVE_FOCUS ) ) && unnoticed ) {
      actions[ UP     ] = isKeyDown( keyInputs.up    , padInputs.up     );
      actions[ DOWN   ] = isKeyDown( keyInputs.down  , padInputs.down   );
      actions[ LEFT   ] = isKeyDown( keyInputs.left  , padInputs.left   );
      actions[ RIGHT  ] = isKeyDown( keyInputs.right , padInputs.right  );
      actions[ ATTACK ] = isKeyDown( keyInputs.attack, padInputs.attack );
    } else {
      resetActions( );
    }

    if ( actions[ UP ] && actions[ DOWN ] ) {
      actions[ UP   ] = false;
      actions[ DOWN ] = false;
    }

    if ( actions[ LEFT ] && actions[ RIGHT ] ) {
      actions[ LEFT  ] = false;
      actions[ RIGHT ] = false;
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

  public function resetObject() : Void {
    unnoticed = true;
    cx = startX;
    cy = startY;
    yr = 0.25;
    speed = Const.PLAYER_SPEED;
    resetActions( );
  }
}
