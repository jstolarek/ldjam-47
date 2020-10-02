// HUD
// ===
//
// User HUD that displays things like score, lives, etc.  Also, some debugging
// information can be added here.
//
// (c) Jan Stolarek 2020, MIT License

package ui;

class Hud extends Process {
  static var LOGGER    = HexLog.getLogger();

  var fps : h2d.Text;

  // Intentional lack of parent so that the HUD is rendered in s2d.  This
  // prevents moving of the user HUD together with the camera
  public function new( ) {
    super( );

    fps = new h2d.Text( Fonts.barlow24 );
    fps.textColor = 0xDD0000;
    fps.x = 10;
    fps.y = 10;
    layers.add( fps, 0 );
  }

  override function update( ) {
    if ( Boot.ME.console.hasFlag ( Console.Flag.FPS ) ) {
      fps.text = Std.string( Math.floor( hxd.Timer.fps( ) ) );
    } else {
      fps.text = "";
    }
  }
}
