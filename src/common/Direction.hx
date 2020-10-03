package common;

class DirectionException extends haxe.Exception {}

enum abstract Direction(Int) from Int to Int {
  var UP         = 0;
  var UP_RIGHT   = 1;
  var RIGHT      = 2;
  var DOWN_RIGHT = 3;
  var DOWN       = 4;
  var DOWN_LEFT  = 5;
  var LEFT       = 6;
  var UP_LEFT    = 7;

  @:to
  public function toString( ) : String {
    switch ( this ) {
      case UP         : return "up";
      case UP_RIGHT   : return "up_right";
      case RIGHT      : return "right";
      case DOWN_RIGHT : return "down_right";
      case DOWN       : return "down";
      case DOWN_LEFT  : return "down_left";
      case LEFT       : return "left";
      case UP_LEFT    : return "up_left";
      default :
        throw new DirectionException( "Unrecognised player state: " + this );
    }
  }

  public static inline var length : Int = 8;

  public static function directionTo( fromX : Float, fromY : Float
                                    , toX   : Float, toY   : Float ) {
    var direction = UP;
    var angle     = Utils.angleTo( fromX, fromY, toX, toY );

    if ( angle > -Math.PI/8 && angle <= Math.PI/8 ) {
      direction = RIGHT;
    } else if ( angle < -1/8 * Math.PI && angle >= -3/8 * Math.PI ) {
      direction = UP_RIGHT;
    } else if ( angle < -3/8 * Math.PI && angle >= -5/8 * Math.PI ) {
      direction = UP;
    } else if ( angle < -5/8 * Math.PI && angle >= -7/8 * Math.PI ) {
      direction = UP_LEFT;
    } else if ( angle < -7/8 * Math.PI ) {
      direction = LEFT;
    } else if ( angle > 1/8 * Math.PI && angle <= 3/8 * Math.PI ) {
      direction = DOWN_RIGHT;
    } else if ( angle > 3/8 * Math.PI && angle <= 5/8 * Math.PI ) {
      direction = DOWN;
    } else if ( angle > 5/8 * Math.PI && angle <= 7/8 * Math.PI ) {
      direction = DOWN_LEFT;
    }

    return direction;
  }

  public static inline function xModifier( dir : Direction ) {
    var modifier = 0;
    if ( dir == UP_LEFT || dir == LEFT || dir == DOWN_LEFT ) {
      modifier = -1;
    } else if ( dir == UP_RIGHT || dir == RIGHT || dir == DOWN_RIGHT ) {
      modifier = 1;
    }
    return modifier;
  }

  public static inline function yModifier( dir : Direction ) {
    var modifier = 0;
    if ( dir == UP_LEFT || dir == UP || dir == UP_RIGHT ) {
      modifier = -1;
    } else if ( dir == DOWN_LEFT || dir == DOWN || dir == DOWN_RIGHT ) {
      modifier = 1;
    }
    return modifier;
  }
}
