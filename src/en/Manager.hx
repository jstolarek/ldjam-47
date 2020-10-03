package en;

class ManagerException extends haxe.Exception {}

// list of states a manager can be in
enum abstract State(Int) from Int to Int {
  var WALK;

  public static inline var length : Int = 2;

  @:to
  public function toString( ) : String {
    switch ( this ) {
      case WALK : return "walk";
      default   :
        throw new ManagerException( "Unrecognised player state: " + this );
    }
  }

  @:from
  public static function fromString( str : String ) : State {
    switch ( str ) {
      case "walk" : return WALK;
      default   :
        throw new ManagerException( "Unrecognised player state: " + str );
    }
  }
}


class Manager extends Entity<State, Unit> {

}
