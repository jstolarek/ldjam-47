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
}
