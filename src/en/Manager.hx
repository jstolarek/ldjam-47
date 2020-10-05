package en;

class ManagerException extends haxe.Exception {}

// list of states a manager can be in
enum abstract ManagerAnimState(Int) from Int to Int {
  var IDLE;
  var SIT;
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
      case SIT             : return "sit";
      case WALK_UP         : return "walk_up";
      case WALK_UP_RIGHT   : return "walk_up_right";
      case WALK_RIGHT      : return "walk_right";
      case WALK_DOWN_RIGHT : return "walk_down_right";
      case WALK_DOWN       : return "walk_down";
      case WALK_DOWN_LEFT  : return "walk_down_left";
      case WALK_LEFT       : return "walk_left";
      case WALK_UP_LEFT    : return "walk_up_left";
      default :
        throw new ManagerException( "Unrecognised manager state: " + this );
    }
  }

  @:from
  public static function fromString( str : String ) : ManagerAnimState {
    switch ( str ) {
      case "idle"            : return IDLE;
      case "sit"             : return SIT;
      case "walk_up"         : return WALK_UP;
      case "walk_up_right"   : return WALK_UP_RIGHT;
      case "walk_right"      : return WALK_RIGHT;
      case "walk_down_right" : return WALK_DOWN_RIGHT;
      case "walk_down"       : return WALK_DOWN;
      case "walk_down_left"  : return WALK_DOWN_LEFT;
      case "walk_left"       : return WALK_LEFT;
      case "walk_up_left"    : return WALK_UP_LEFT;
      default :
        throw new ManagerException( "Unrecognised manager state: " + str );
    }
  }
}

class Manager extends Entity<ManagerAnimState, String> implements Resetable {
  static var LOGGER = HexLog.getLogger();

  var patrolPath : Array<Point> = [];
  var target     : Int          = 0;
  var direction  : Direction    = UP;
  var sightAngle : Float        = Math.PI / 4;
  var sightLength: Float        = 8.0;
  var sightData  : Array<Float> = [];
  var startXPos  : Int          = 0;
  var startYPos  : Int          = 0;
  var pieOfSight : h2d.Graphics;
  var lineofsight : h2d.Graphics;
  var directionChange : Bool;
  var player : Player;
  var managerText : h2d.Object;

  public function new( ?parent : Process, startX : Int, startY : Int
                     , patrolPath : Array<Point>
                     , pl: Player ) {
    super( parent );

    cx      = startXPos = startX;
    cy      = startYPos = startY;
    xr      = 0.0;
    yr      = 0.0;
    target  = 0;
    this.patrolPath = patrolPath;
    player = pl;
    managerText = Aseprite.loadSpriteSheet("speech");
    managerText.y -= 20.0; //h4ckss
    managerText.visible = false;
    layers.add(managerText, Entity.MAIN_LAYER);

    // [0] x, [1] y, [2] cone length, [3] sight direction, [4] width of the angle
    sightData =  [0.0, 0.0, sightLength * 12.0, 0.0, sightAngle];
    updateDirection( );
    updateSight( );

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
    super.fixedUpdate( );

    var target    = getTarget( );
    var xModifier = Direction.xModifier( direction );
    var yModifier = Direction.yModifier( direction );

    var angle = Utils.angleTo( x, y, target.x * gx, target.y * gx );

    if(!checkIfPlayerInSight( ) || player.working) {
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
        updateSight( );
      }
    }

    if( checkIfPlayerInSight( ) && player.unnoticed && !player.working ) {
      noticePlayer( );
    }
  }

  override function hasCircCollWith<S, T>(e: Entity<S, T>) : Bool {
    if( Std.is(e, Player) ) return true;
    return false;
  }

  override function onTouch<S, T>(e: Entity<S, T>) {
    pieOfSight.remove();
    if( player.unnoticed && !player.working ) {
      noticePlayer( );
    }
  }

  inline function updateDirection( ) : Void {
    var oldDirection = direction;
    direction = Direction.directionTo( x, y,
      patrolPath[ target ].x * gx, patrolPath[ target ].y * gy );

    if( oldDirection != direction ) {
      directionChange = true;
    }
  }

  inline function updateSight() : Void {
    sightData[0] = gx * 0.5;
    sightData[1] = gx * 0.5;
    if (directionChange) {
      directionChange = false;
      pieOfSight.remove();

      switch(direction) {
        // http://www.math.com/tables/graphs/unitcircle.gif but clockwise
        case UP:
          sightData[3] = 3 * Math.PI / 2.0;
        case UP_RIGHT:
          sightData[3] = 7 * Math.PI / 4.0;
        case RIGHT:
          sightData[3] = 0.0;
        case LEFT:
          sightData[3] = Math.PI;
        case DOWN:
          sightData[3] = Math.PI / 2.0;
        case DOWN_LEFT:
          sightData[3] = 3 * Math.PI / 4.0;
        case DOWN_RIGHT:
          sightData[3] = Math.PI / 4.0;
        case UP_LEFT:
          sightData[3] = 5 * Math.PI / 4.0;
      }

#if ( devel )
      drawDebugPie( );
#end
    }
  }

  private inline function drawDebugPie( ) {
    pieOfSight = new h2d.Graphics();
    pieOfSight.beginFill(0xF000FFAA, 0.2);
    pieOfSight.drawPie(sightData[0], sightData[1], sightData[2], sightData[3]  - sightAngle / 2.0, sightData[4]);
    pieOfSight.endFill();
    layers.add(pieOfSight, Entity.MAIN_LAYER);
  }

  private function checkIfPlayerInSight( ) : Bool {
    var managerPosLocal = [gx * 0.5, gy * 0.5];
    var managerPos      = [x + managerPosLocal[0], y + managerPosLocal[1]];
    var playerPos       = [player.x + player.gx * 0.5, player.y + player.gy * 0.5];
    var playerToManager = [playerPos[0] - managerPos[0], playerPos[1] - managerPos[1]];
    var dist = Math.sqrt(Math.pow(playerToManager[0], 2) + Math.pow(playerToManager[1], 2));

    //Line from Manager to Player
    //drawDebugLine( [managerPos[0], managerPos[1]], [playerPos[0], playerPos[1]], parent.layers );
    //Line from Manager to Player in Manager's local coordinates
    //drawDebugLine( [gx * 0.5, gy * 0.5], [playerToManager[0], playerToManager[1]] );

    if( dist < sightData[2] ) {
      var playerToManagerNormalized = [ (playerToManager[0]) / dist, (playerToManager[1]) / dist]; //normalized vector
      var managerForwardDirection   = [ Math.cos( sightData[3] ) , Math.sin( sightData[3] ) ];
      var dotProduct                = playerToManagerNormalized[0] * managerForwardDirection[0]
                                    + playerToManagerNormalized[1] * managerForwardDirection[1];
      var angle                     = Math.acos( dotProduct ) * 180.0 / Math.PI;
      //Line from Manager to Player in Manager's local coordinates
      //drawDebugLine( [gx * 0.5, gy * 0.5], [playerToManager[0], playerToManager[1]] );
      //Line showing the front of Manager
      //drawDebugLine( [managerPosLocal[0], managerPosLocal[1]],
        //[managerForwardDirection[0] * 200.0 + managerPosLocal[0], managerForwardDirection[1] * 200.0 + managerPosLocal[1]] );
      if( angle < (hxd.Math.radToDeg(sightAngle)) / 2.0 ) {
        //LOGGER.debug("Angle: " + angle);
        return true;
      }
    }
    return false;
  }

  private function drawDebugLine(from : Array<Float>, to : Array<Float>, ?parentLayers : h2d.Layers) {
    var layersToAttachTo = (parentLayers == null? layers : parentLayers);
    lineofsight.remove();
    lineofsight = new h2d.Graphics(Main.ME.s2d);
    lineofsight.lineStyle(1.0, 0xFF0000, 1.0);
    lineofsight.moveTo(from[0], from[1]);
    lineofsight.lineTo(to[0], to[1]);
    layersToAttachTo.add(lineofsight, Entity.MAIN_LAYER);
  }

  private function noticePlayer( ) : Void {
    if ( !Boot.ME.console.hasFlag( Console.Flag.GOD ) ) {
      player.unnoticed = false;
      animation.paused = true;
      managerText.visible = true;

    cooldown.setMs("ending", 3000, function ( ) {
        LOGGER.info("<< GAME RESET >>");
        Boot.ME.loopLevel();
      });
    }
  }

  public function resetObject() : Void {
    cx      = startXPos;
    cy      = startYPos;
    xr     = 0.0;
    yr     = 0.0;
    target = 0;
    sightData =  [0.0, 0.0, sightLength * 12.0, 0.0, sightAngle];
    updateDirection( );
    updateSight( );
    animation.paused = false;
    managerText.visible = false;
  }
}
