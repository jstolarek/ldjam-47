package world;

class CollisionException extends haxe.Exception {}

enum abstract Collision(Int) from Int to Int {
  var NONE;
  var WALL;

  @:from
  public static function fromString( str : String ) : Collision {
    switch ( str ) {
      case "0" : return NONE;
      case "1" : return WALL;
      default  :
        throw new CollisionException( "Unrecognised collision type: " + str );
    }
  }
}
