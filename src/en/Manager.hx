package en;

class ManagerException extends haxe.Exception {}

// list of states a manager can be in
enum abstract ManagerAnimState(Int) from Int to Int {
  var IDLE;
  var WALK_UP;
  var WALK_UP_RIGHT;
  var WALK_RIGHT;
  var WALK_DOWN_RIGHT;
  var WALK_DOWN;
  var WALK_DOWN_LEFT;
  var WALK_LEFT;
  var WALK_UP_LEFT;

  public static inline var length : Int = 9;

  @:to
  public function toString( ) : String {
    switch ( this ) {
      case IDLE            : return "idle";
      case WALK_UP         : return "walk_up";
      case WALK_UP_RIGHT   : return "walk_up_right";
      case WALK_RIGHT      : return "walk_right";
      case WALK_DOWN_RIGHT : return "walk_down_right";
      case WALK_DOWN       : return "walk_down";
      case WALK_DOWN_LEFT  : return "walk_down_left";
      case WALK_LEFT       : return "walk_left";
      case WALK_UP_LEFT    : return "walk_up_left";
      default :
        throw new ManagerException( "Unrecognised player state: " + this );
    }
  }

  @:from
  public static function fromString( str : String ) : ManagerAnimState {
    switch ( str ) {
      case "idle"            : return IDLE;
      case "walk_up"         : return WALK_UP;
      case "walk_up_right"   : return WALK_UP_RIGHT;
      case "walk_right"      : return WALK_RIGHT;
      case "walk_down_right" : return WALK_DOWN_RIGHT;
      case "walk_down"       : return WALK_DOWN;
      case "walk_down_left"  : return WALK_DOWN_LEFT;
      case "walk_left"       : return WALK_LEFT;
      case "walk_up_left"    : return WALK_UP_LEFT;
      default :
        throw new ManagerException( "Unrecognised player state: " + str );
    }
  }
}

class Manager extends Entity<ManagerAnimState, Unit> {
  static var LOGGER = HexLog.getLogger();

  var patrolPath : Array<Point> = [];
  var target     : Int          = 0;
  var direction  : Direction    = UP;

  public function new( ?parent : Process, startX : Int, startY : Int
                     , patrolPath : Array<Point> ) {
    super( parent );

    cx     = startX;
    cy     = startY;
    xr     = 0.0;
    yr     = 0.0;
    target = 0;
    this.patrolPath = patrolPath;

    updateDirection( );

    animation.stateAnims =
      Aseprite.loadStateAnimation( "player", ManagerAnimState.fromString );

    animation.registerStateAnimation( WALK_UP, 1, function ( ) {
        return direction == UP;
      } );
    animation.registerStateAnimation( WALK_UP_RIGHT, 1, function ( ) {
        return direction == UP_RIGHT;
      } );
    animation.registerStateAnimation( WALK_RIGHT, 1, function ( ) {
        return direction == RIGHT;
      } );
    animation.registerStateAnimation( WALK_DOWN_RIGHT, 1, function ( ) {
        return direction == DOWN_RIGHT;
      } );
    animation.registerStateAnimation( WALK_DOWN, 1, function ( ) {
        return direction == DOWN;
      } );
    animation.registerStateAnimation( WALK_DOWN_LEFT, 1, function ( ) {
        return direction == DOWN_LEFT;
      } );
    animation.registerStateAnimation( WALK_LEFT, 1, function ( ) {
        return direction == LEFT;
      } );
    animation.registerStateAnimation( WALK_UP_LEFT, 1, function ( ) {
        return direction == UP_LEFT;
      } );
    animation.registerStateAnimation( IDLE, 0, function ( ) {
        return true;
      } );

    animation.setScale( 2 );
  }

  inline function nextTarget( ) : Void {
    target = (target + 1) % patrolPath.length;
  }

  inline function getTarget( ) : Point {
    return patrolPath[ target ];
  }

  inline function getNextTarget( ) : Point {
    return patrolPath[ (target + 1) % patrolPath.length ];
  }

  override public function fixedUpdate( ) {
    var target    = getTarget( );
    var xModifier = Direction.xModifier( direction );
    var yModifier = Direction.yModifier( direction );

    var angle = Utils.angleTo( x, y, target.x * gx, target.y * gx );

    vx = Math.cos( angle ) * Const.MANAGER_BASE_SPEED;
    vy = Math.sin( angle ) * Const.MANAGER_BASE_SPEED;

    xr += vx;
    yr += vy;

    var target_dist = Utils.dist( x, y, target.x * gx, target.y * gy );
    if ( target_dist < Const.MANAGER_TARGET_DEADZONE ) {
      cx = target.x;
      cy = target.y;
      xr = 0.0;
      yr = 0.0;
      vx = 0.0;
      vy = 0.0;

      nextTarget( );
      updateDirection( );
    }

  }

  inline function updateDirection( ) : Void {
    direction = Direction.directionTo( x, y,
      patrolPath[ target ].x * gx, patrolPath[ target ].y * gy );
  }
}
