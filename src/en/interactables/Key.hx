package en.interactables;

class Key extends Interactable {
  var startCx : Int;
  var startCy : Int;
  var startXr : Float;
  var startYr : Float;

  static var LOGGER = HexLog.getLogger( );

  public function new( cx : Int, cy: Int, xr : Float, yr : Float, player: Player ) {
    super( cx, cy, "key_small", player );
    this.cx = startCx = cx;
    this.cy = startCy = cy;
    this.xr = startXr = xr;
    this.yr = startYr = yr;
    interactRadius = 1.0;
  }

  override function interact( ) {
    LOGGER.debug( "What a nice key!" );
  }

  override public function resetObject( ) : Void {
    super.resetObject( );
    this.cx = startCx;
    this.cy = startCy;
    this.xr = startXr;
    this.yr = startYr;
  }
}