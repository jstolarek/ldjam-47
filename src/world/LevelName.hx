package world;

class LevelNameException extends haxe.Exception {}

enum abstract LevelName(Int) from Int to Int {
  var OPEN_SPACE_1;

  @:from
  public static function fromString( str : String ) : LevelName {
    switch ( str ) {
      case "open_space_1" : return OPEN_SPACE_1;
      default            :
        throw new LevelNameException( "Unrecognised level name: " + str );
    }
  }

  @:to
  public function toString( ) : String {
    switch ( this ) {
      case OPEN_SPACE_1 : return "open_space_1";
      default          :
        throw new LevelNameException( "Unrecognised level index: " + this );
    }
  }
}
