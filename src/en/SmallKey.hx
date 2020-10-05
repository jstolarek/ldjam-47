package en;

enum abstract KeyState(Int) from Int to Int {
  var NORMAL;
  var HIGHLIGHT;

  public static inline var length : Int = 2;

  @:from
  public static function fromString( str : String ) : KeyState {
    switch ( str ) {
      case "normal": return NORMAL;
      case "highlight" : return HIGHLIGHT;
      default   :
        throw new haxe.Exception( "Unrecognised key state: " + str );
    }
  }
}

class SmallKey extends Entity<KeyState, Unit> implements Resetable {

  var startCx : Int;
  var startCy : Int;
  var startXr : Float;
  var startYr : Float;

  public function new( cx, cy, xr, yr ) {
    super( );
    this.cx = startCx = cx;
    this.cy = startCy = cy;
    this.xr = startXr = xr;
    this.yr = startYr = yr;

    animation.stateAnims =
      Aseprite.loadStateAnimation( "key_small", KeyState.fromString );

    animation.registerStateAnimation( NORMAL, 0, function( ) { return true; } );
  }

  public function resetObject() : Void {
    this.cx = startCx;
    this.cy = startCy;
    this.xr = startXr;
    this.yr = startYr;
  }

}