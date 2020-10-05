package world;

class CollisionException extends haxe.Exception {}

enum abstract Collision(Int) from Int to Int {
  var NONE;
  var DESK;
  var WORK_AREA;
  var DOOR;

  @:from
  public static function fromString( str : String ) : Collision {
    switch ( str ) {
      case "0" : return NONE;
      case "1" : return DESK;
      case "2" : return WORK_AREA;
      case "3" : return DOOR;
      default  :
        throw new CollisionException( "Unrecognised collision type: " + str );
    }
  }
}
