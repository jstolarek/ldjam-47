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

enum abstract AnimationPriority(Int) from Int to Int {
  var IDLE_ANIM_PRIORITY = 0;
  var SIT_ANIM_PRIORITY  = 1;
  var WALK_ANIM_PRIORITY = 2;
}

// list of states a player can be in
// Describes animation state
enum abstract State(Int) from Int to Int {
  var IDLE;
  var SIT;
  var WALK_UP;
  var WALK_DOWN;
  var WALK_RIGHT;
  var WALK_LEFT;
  var WALK_UP_RIGHT;
  var WALK_UP_LEFT;
  var WALK_DOWN_RIGHT;
  var WALK_DOWN_LEFT;

  public static inline var length : Int = 10;

  @:to
  public function toString( ) : String {
    switch ( this ) {
      case IDLE            : return "idle";
      case SIT             : return "sit";
      case WALK_UP         : return "walk_up";
      case WALK_DOWN       : return "walk_down";
      case WALK_RIGHT      : return "walk_right";
      case WALK_LEFT       : return "walk_left";
      case WALK_UP_RIGHT   : return "walk_up_right";
      case WALK_UP_LEFT    : return "walk_up_left";
      case WALK_DOWN_RIGHT : return "walk_down_right";
      case WALK_DOWN_LEFT  : return "walk_down_left";
      default   :
        throw new PlayerException( "Unrecognised player state: " + this );
    }
  }

  @:from
  public static function fromString( str : String ) : State {
    switch ( str ) {
      case "idle": return IDLE;
      case "sit" : return SIT;
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
         var startY     : Int = 3;

  var collisionBox      : Rect;
  var collisionBoxRect  : h2d.Graphics;


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

  public var unnoticed : Bool;
  public var working   : Bool;
  public var hasKey    : Bool;

  public function new( ?parent : Process ) {
    super( parent );

    keyInputs  = Settings.keyInputScheme;
    padInputs  = Settings.padInputScheme;
    controller = Controller.getController( );
    actions    = new Vector<Bool>( Action.length );
    unnoticed  = true;
    working    = false;
    hasKey     = false;

    // starting coordinates
    cx = startX;
    cy = startY;
    yr = 0.25;
    speed = Const.PLAYER_SPEED;

    collisionBox = { x : 6, y : 24, w : 19, h : 7 };

    resetActions( );
    setAnimations();
    setWorking( );

#if ( devel )
    collisionBoxRect = new h2d.Graphics( );
    collisionBoxRect.beginFill( 0xFFFF0000 );
    collisionBoxRect.drawRect( collisionBox.x, collisionBox.y
                             , collisionBox.w, collisionBox.h );
    collisionBoxRect.endFill( );
    collisionBoxRect.visible = false;
    layers.add( collisionBoxRect, Entity.DEBUG_LAYER );
#end
  }

  override function fixedUpdate( ) {
    vx = vy = 0.0; // either this of applySpeedFriction below

    if ( isActions( [ UP, DOWN, LEFT, RIGHT ] ) ) {
      working = false;
    }

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

#if ( devel )
    if ( console.hasFlag( Console.Flag.HITBOXES ) ) {
      collisionBoxRect.visible = true;
    } else {
      collisionBoxRect.visible = false;
    }
#end
  }

  private inline function setAnimations() : Void {
    animation.stateAnims =
      Aseprite.loadStateAnimation( "player", State.fromString );
//    animation.pivot = new Animation.Pivot( 0.5, 0.5, true );

    animation.registerStateAnimation( WALK_UP, WALK_ANIM_PRIORITY,
      function ( ) {
        return actions[ UP ];
    } );

    animation.registerStateAnimation( WALK_DOWN, WALK_ANIM_PRIORITY,
      function ( ) {
        return actions[ DOWN ];
    } );

    animation.registerStateAnimation( WALK_RIGHT, WALK_ANIM_PRIORITY,
      function ( ) {
        return actions[ RIGHT ];
    } );

    animation.registerStateAnimation( WALK_LEFT, WALK_ANIM_PRIORITY,
      function ( ) {
        return actions[ LEFT ];
    } );

    animation.registerStateAnimation( WALK_UP_RIGHT, WALK_ANIM_PRIORITY,
      function ( ) {
        return actions[ UP ] && actions[ RIGHT ];
      } );

    animation.registerStateAnimation( WALK_DOWN_RIGHT, WALK_ANIM_PRIORITY,
      function ( ) {
        return actions[ DOWN ] && actions[ RIGHT ];
    } );

    animation.registerStateAnimation( WALK_UP_LEFT, WALK_ANIM_PRIORITY,
      function ( ) {
        return actions[ UP ] && actions[ LEFT ];
    } );

    animation.registerStateAnimation( WALK_DOWN_LEFT, WALK_ANIM_PRIORITY,
      function ( ) {
        return actions[ DOWN ] && actions[ LEFT ];
    } );

    animation.registerStateAnimation( SIT, SIT_ANIM_PRIORITY,
      function ( ) {
        return working;
    } );

    animation.registerStateAnimation( IDLE, IDLE_ANIM_PRIORITY, function ( ) {
      return true;
    } );
  }

  override inline function hasCircCollWith<S, T>(e: Entity<S, T>) {
    if( Std.is(e, Manager) ) return true;
    return false;
  }

  private inline function handleCollisions( ) : Void {
    // Handle collisions with desks
    var sgn = (x:Float) -> (x == 0) ? 0 : ((x > 0) ? 1 : -1);
    var svx = sgn(vx);
    var svy = sgn(vy);
    var coll = (sx:Int, sy:Int) -> {
      var cx = (sx == 1) ? rightCx : leftCx;
      var cy = (sy == 1) ? downCx : upCx;
      return level.hasDeskCollision(cx, cy);
    }
    var stopX = () -> {
      xr -= vx;
      vx = 0.0; // stop
    };
    var stopY = () -> {
      yr -= vy;
      vy = 0.0; // stop
    };

    // Moving left or right
    if (svx != 0 && svy == 0) {
      if (coll(svx, 1) || coll(svx, -1)) {
        stopX();
      }
    }
    // Moving up or down
    else if (svx == 0 && svy != 0) {
      if (coll(1, svy) || coll(-1, svy)) {
        stopY();
      }
    }
    // Moving diagonally
    else if (svx != 0 && svy != 0) {
      if ((coll(svx, -1) && coll(svx, 1)) || coll(svx, svy * -1)) {
        stopX();
      } else if ((coll(-1, svy) && coll(1, svy)) || coll(svx * -1, svy)) {
        stopY();
      } else if (coll(svx, svy)) {
        var dx = (svx > 0) ? rightXr: 1.0 - leftXr;
        var dy = (svy > 0) ? downYr : 1.0 - upYr;

        if (dx == dy) {
          // when equal (very rarely) prefer stopping in y direction
          // to avoid full stop
          stopY();
        } else if (dx > dy) {
          stopY();
        } else {
          stopX();
        }
      }
    }
  }

  private inline function checkIfWorking( ) : Void {
    if ( actions[ ATTACK ] ) {
      setWorking( );
    }
  }

  function setWorking( ) {
    var collison_upper  = level.isWithinWorkArea( leftCx , upCx   )
      || level.isWithinWorkArea( rightCx, upCx   );
    var collision_lower = level.isWithinWorkArea( leftCx , downCx )
      || level.isWithinWorkArea( rightCx, downCx );
    var collision_left  = level.isWithinWorkArea( leftCx , downCx )
      || level.isWithinWorkArea( leftCx , upCx   );
    var collision_right = level.isWithinWorkArea( rightCx, downCx )
      || level.isWithinWorkArea( rightCx, upCx   );

    if ( collison_upper || collision_lower || collision_left || collision_right ) {
      working = true;
    }

    if ( collision_left && collision_right ) {
      cx = leftCx;
      cy = upCx - 1;
      xr = 0.5;
      yr = 0.25;
    } else if ( collision_left ) {
      cx = leftCx - 1;
      cy = upCx - 1;
      xr = 0.5;
      yr = 0.25;
    } else if ( collision_right ) {
      cx = rightCx;
      cy = upCx - 1;
      xr = 0.5;
      yr = 0.25;
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

  public function isActions( actionsToCheck : Array<Action> ) : Bool {
    for ( action in actionsToCheck ) {
      if ( actions[ action ] ) {
        return true;
      }
    }
    return false;
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
