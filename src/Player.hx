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
// walk left is a mirror reflection of right
enum abstract State(Int) from Int to Int {
  var IDLE;
  var WALK_UP;
  var WALK_DOWN;
  var WALK_RIGHT;
  var WALK_UP_RIGHT;
  var WALK_DOWN_RIGHT;

  public static inline var length : Int = 2;

  @:to
  public function toString( ) : String {
    switch ( this ) {
      case IDLE            : return "idle";
      case WALK_UP         : return "walk_up";
      case WALK_DOWN       : return "walk_down";
      case WALK_RIGHT      : return "walk_right";
      case WALK_UP_RIGHT   : return "walk_up_right";
      case WALK_DOWN_RIGHT : return "walk_down_right";
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
      case "walk_up_right": return WALK_UP_RIGHT;
      case "walk_down_right": return WALK_DOWN_RIGHT;
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
    resetActions( );

    setAnimations();
  }

  private inline function setAnimations() : Void {
    // BEGIN TEST STUFF
    animation.stateAnims =
      Aseprite.loadStateAnimation( "player", State.fromString );
    animation.pivot = new Animation.Pivot( 0.5, 0.75, true );

    // starting coordinates
    cx = 6;
    cy = 8;

    spr.anim.registerStateAnim("hero-walk-up", 3, 0.4, function() return isWalk() && direction == UP );
    spr.anim.registerStateAnim("hero-walk-diagonal-top-right", 3, 0.4, function() return isWalk() && (direction == UP_RIGHT || direction == UP_LEFT ));
    spr.anim.registerStateAnim("hero-walk-right", 3, 0.4, function() return isWalk() && (direction == RIGHT || direction == LEFT ));
    spr.anim.registerStateAnim("hero-walk-diagonal-down-right", 3, 0.4, function() return isWalk() && (direction == DOWN_RIGHT || direction == DOWN_LEFT ));
    spr.anim.registerStateAnim("hero-walk-down", 3, 0.4, function() return isWalk() && direction == DOWN );
    spr.anim.registerStateAnim("hero-idle", 2, 0.1, function() return isIdle() );
    spr.anim.registerStateAnim("skull", 1, 0.2, function() return isDead() );

    animation.registerStateAnimation( WALK_UP, 1, function ( ) {
      return;
    } );

    animation.registerStateAnimation( WALK_DOWN, 1, function ( ) {
      return actions[ LEFT ] || actions[ RIGHT ];
    } );

    animation.registerStateAnimation( WALK_RIGHT, 1, function ( ) {
      return actions[ LEFT ] || actions[ RIGHT ];
    } );

    animation.registerStateAnimation( WALK_UP_RIGHT, 1, function ( ) {
        return actions[ LEFT ] || actions[ RIGHT ];
      } );

    animation.registerStateAnimation( WALK_DOWN_RIGHT, 1, function ( ) {
      return actions[ LEFT ] || actions[ RIGHT ];
    } );

    animation.registerStateAnimation( IDLE, 0, function ( ) {
        return true;
      } );

    // FIXME: hack for prototyping purposes
    animation.scaleX = 0.5;
    animation.scaleY = 0.5;
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

  override function fixedUpdate( ) {
    // BEGIN TEST STUFF
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

    applySpeedFriction( );

  }

  override function update( ) {
    if ( !(console.isActive( ) && console.hasFlag( Flag.EXCLUSIVE_FOCUS ) ) ) {
      actions[ UP     ] = isKeyDown( keyInputs.up    , padInputs.up     );
      actions[ DOWN   ] = isKeyDown( keyInputs.down  , padInputs.down   );
      actions[ LEFT   ] = isKeyDown( keyInputs.left  , padInputs.left   );
      actions[ RIGHT  ] = isKeyDown( keyInputs.right , padInputs.right  );
      actions[ JUMP   ] = isKeyDown( keyInputs.jump  , padInputs.jump   );
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
