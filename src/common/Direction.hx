package common;

enum abstract Direction(Int) from Int to Int {
  var UP         = 0;
  var UP_RIGHT   = 1;
  var RIGHT      = 2;
  var DOWN_RIGHT = 3;
  var DOWN       = 4;
  var DOWN_LEFT  = 5;
  var LEFT       = 6;
  var UP_LEFT    = 7;

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
}
