package world;

class LevelNameException extends haxe.Exception {}

enum abstract LevelName(Int) from Int to Int {
  var TEST_ROOM_1;
  var TEST_ROOM_2;

  @:from
  public static function fromString( str : String ) : LevelName {
    switch ( str ) {
      case "test_room_1" : return TEST_ROOM_1;
      case "test_room_2" : return TEST_ROOM_2;
      default            :
        throw new LevelNameException( "Unrecognised level name: " + str );
    }
  }

  @:to
  public function toString( ) : String {
    switch ( this ) {
      case TEST_ROOM_1 : return "test_room_1";
      case TEST_ROOM_2 : return "test_room_2";
      default          :
        throw new LevelNameException( "Unrecognised level index: " + this );
    }
  }
}
