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
  var JUMP;
  var ATTACK;

  public static inline var length : Int = 6;

  @:to
  public function toString( ) : String {
    switch ( this ) {
      case UP     : return "UP"    ;
      case DOWN   : return "DOWN"  ;
      case LEFT   : return "LEFT"  ;
      case RIGHT  : return "RIGHT" ;
      case JUMP   : return "JUMP"  ;
      case ATTACK : return "ATTACK";
      default     :
        throw new PlayerException( "Unrecognised player action: " + this );
    }
  }
}

// list of states a player can be in
enum abstract State(Int) from Int to Int {
  var IDLE;
  var WALK;

  public static inline var length : Int = 2;

  @:to
  public function toString( ) : String {
    switch ( this ) {
      case IDLE : return "idle";
      case WALK : return "walk";
      default   :
        throw new PlayerException( "Unrecognised player state: " + this );
    }
  }

  @:from
  public static function fromString( str : String ) : State {
    switch ( str ) {
      case "idle" : return IDLE;
      case "walk" : return WALK;
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

    // BEGIN TEST STUFF
    animation.stateAnims =
      Aseprite.loadStateAnimation( "test/mai", State.fromString );
    animation.pivot = new Animation.Pivot( 0.25, 0.375, true );

    // starting coordinates
    cx = 6;
    cy = 8;

    animation.registerStateAnimation( WALK, 1, function ( ) {
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
