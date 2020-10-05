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
  var debugGrid : h2d.Graphics;

  // measuring play time
  var gameTimeText : h2d.Text;
  var gameTime     : Float;
  var keyIcon      : h2d.Bitmap;

  var player (get, never) : Player;

  // Intentional lack of parent so that the HUD is rendered in s2d.  This
  // prevents moving of the user HUD together with the camera
  public function new( ) {
    super( );

    fps = new h2d.Text( Fonts.barlow24 );
    fps.textColor = 0xDD0000;
    fps.x = 10;
    fps.y = 10;
    layers.add( fps, 0 );

    debugGrid = new h2d.Graphics( );

    var width  = Boot.ME.world.currentLevel.width;
    var height = Boot.ME.world.currentLevel.height;
    var gx     = Boot.ME.world.currentLevel.gridX;
    var gy     = Boot.ME.world.currentLevel.gridY;

    for ( x in 0...width ) {
      debugGrid.beginFill(0xFF0000FF);
      debugGrid.drawRect(x*gx, 0, 1, height * gy);
      debugGrid.endFill();
    }

    for ( y in 0...height ) {
      debugGrid.beginFill(0xFF0000FF);
      debugGrid.drawRect(0, y*gy, width * gx, 1);
      debugGrid.endFill( );
    }

    debugGrid.visible = false;
    layers.add( debugGrid, 0 );

    gameTimeText           = new h2d.Text( Fonts.barlow24 );
    gameTimeText.textColor = 0xFFFF00;
    gameTimeText.visible   = true;
    gameTimeText.y         = 10;
    gameTimeText.text      = "0.0";
    gameTimeText.x         = 10; // Const.CANVAS_WIDTH - gameTimeText.textWidth - 10;
    layers.add( gameTimeText, 0 );

    keyIcon         = new h2d.Bitmap( hxd.Res.key_icon.toTile() );
    keyIcon.x       = 10;
    keyIcon.y       = 40;
    keyIcon.visible = false;
    layers.add( keyIcon, 0 );
  }

  override function update( ) {
    if ( Boot.ME.console.hasFlag ( Console.Flag.FPS ) ) {
      fps.text = Std.string( Math.floor( hxd.Timer.fps( ) ) );
    } else {
      fps.text = "";
    }

    if ( Boot.ME.console.hasFlag( Console.Flag.GRID ) ) {
      debugGrid.visible = true;
    } else {
      debugGrid.visible = false;
    }

    gameTimeText.text = "Time: " + Utils.floatToString( Boot.ME.gameTime, 2 );
    // gameTimeText.x    = Const.CANVAS_WIDTH - gameTimeText.textWidth - 10;

    if ( player.hasKey ) {
      keyIcon.visible = true;
    } else {
      keyIcon.visible = false;
    }
  }

  inline function get_player( ) {
    return Boot.ME.player;
  }
}
