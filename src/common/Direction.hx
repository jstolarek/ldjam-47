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

  public static directionTo( fromX : Float, fromY : Float
                           , toX   : Float, toY   : Float ) {
    var direction = UP;
    var angle     = Utils.angleTo( fromX, fromY, toX, toY );

    if ( angle > -M.PI/8 && angle <= M.PI/8 ) {
      direction = RIGHT;
    } else if ( angle < -1/8*M.PI && angle >= -3/8*M.PI ) {
      direction = UP_RIGHT;
    } else if ( angle < -3/8*M.PI && angle >= -5/8*M.PI ) {
      direction = UP;
    } else if ( angle < -5/8*M.PI && angle >= -7/8*M.PI ) {
      direction = UP_LEFT;
    } else if ( angle < -7/8*M.PI ) {
      direction = LEFT;
    } else if ( angle > 1/8*M.PI && angle <= 3/8*M.PI ) {
      direction = DOWN_RIGHT;
    } else if ( angle > 3/8*M.PI && angle <= 5/8*M.PI ) {
      direction = DOWN;
    } else if ( angle > 5/8*M.PI && angle <= 7/8*M.PI ) {
      direction = DOWN_LEFT;
    }

    return direction;
  }

  // Use to flip animation when player facing left
  public static inline flipDirection( d : Direction ) : Int {
    var flip = 1;
    if ( d == UP_LEFT || d == LEFT || d == DOWN_LEFT ) {
      flip = -1;
    }
    return flip;
  }
}
