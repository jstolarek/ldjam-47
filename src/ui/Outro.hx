// HUD
// ===
//
// User HUD that displays things like score, lives, etc.  Also, some debugging
// information can be added here.
//
// (c) Jan Stolarek 2020, MIT License

package ui;

class OutroException extends haxe.Exception {}

enum abstract OutroState(Int) from Int to Int {
    var OUTRO;
    var NO_DISPLAY;

    public static inline var length : Int = 2;

    @:to
    public function toString( ) : String {
      switch ( this ) {
        case OUTRO : return "outro";
        case NO_DISPLAY : return "no_display";
        default   :
          throw new OutroException( "Unrecognised outro state: " + this );
      }
    }

    @:from
    public static function fromString( str : String ) : OutroState {
      switch ( str ) {
        case "outro" : return OUTRO;
        case "no_display" : return NO_DISPLAY;
        default   :
          throw new OutroException( "Unrecognised outro state: " + str );
      }
    }
  }

class Outro extends Entity<OutroState, String> {
           var player : Player;
           var scoreText : h2d.Text;
           var boot : Boot;
           var gameFinished : Bool = false;

    public function new( pl : Player, bt : Boot ) {
        super( );

        cx = 0;
        cy = 1;
        player = pl;
        boot = bt;

        scoreText = new h2d.Text( Fonts.barlow32 );
        scoreText.text    = "  You escaped!  "
                          + "\nYour time: ";
        scoreText.textColor = 0xFFFF00;
        scoreText.x       = (Const.CANVAS_WIDTH  - scoreText.textWidth) * 0.5;
        scoreText.y       = (Const.CANVAS_HEIGHT - scoreText.textHeight) * 0.5;
        scoreText.visible = false;
        layers.add( scoreText, Boot.GUI_LAYER );

    }

    override function fixedUpdate( ) {
        if( !gameFinished && player.doorOpen ) {
            gameFinished = true;
            showOutro( boot.gameTime );
        }
    }

    public function showOutro( score : Float ) {
        scoreText.text = scoreText.text + Utils.floatToString(score, 2) + "s";
        scoreText.visible = true;
    }

}
