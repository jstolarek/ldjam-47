// HUD
// ===
//
// User HUD that displays things like score, lives, etc.  Also, some debugging
// information can be added here.
//
// (c) Jan Stolarek 2020, MIT License

package ui;

class IntroException extends haxe.Exception {}

enum abstract IntroState(Int) from Int to Int {
    var INTRO;
    var CONTROLS;
    var NO_DISPLAY;

    public static inline var length : Int = 2;

    @:to
    public function toString( ) : String {
      switch ( this ) {
        case INTRO : return "intro";
        case NO_DISPLAY : return "no_display";
        case CONTROLS : return "controls";
        default   :
          throw new IntroException( "Unrecognised intro state: " + this );
      }
    }

    @:from
    public static function fromString( str : String ) : IntroState {
      switch ( str ) {
        case "intro" : return INTRO;
        case "no_display" : return NO_DISPLAY;
        case "controls" : return CONTROLS;
        default   :
          throw new IntroException( "Unrecognised intro state: " + str );
      }
    }
  }

class Intro extends Entity<IntroState, String> {
    public var spriteName = "intro";
           var player : Player;
    public var noDisplay : Bool = false;
    public var controls  : Bool = true;

    public function new( pl : Player ) {
        super( );

        cx = 0;
        cy = 1;
        player = pl;

        animation.stateAnims =
            Aseprite.loadStateAnimation( spriteName, IntroState.fromString );

        animation.registerStateAnimation( CONTROLS, 1, function ( ) {
           return controls;
        }, false );

        //animation.pivot = new Animation.Pivot( 0.5, 0.5, true );
        animation.registerStateAnimation( NO_DISPLAY, 1, function ( ) {
           return noDisplay;
        }, false );

        animation.registerStateAnimation( INTRO, 0, function ( ) {
            return true;
         }, false );

    }

    override function fixedUpdate( ) {
        if( !noDisplay ) {
            if (player.isAction( UP )
                || player.isAction( DOWN )
                || player.isAction( LEFT )
                || player.isAction( RIGHT )
                || player.isAction( ATTACK )
                || hxd.Key.isPressed( hxd.Key.ENTER )
                || hxd.Key.isPressed( hxd.Key.ESCAPE )
                || hxd.Key.isPressed( hxd.Key.SPACE )
                ) {
              if ( controls ) {
                controls = false;
                cooldown.setMs( "foo", 200 );
              } else if ( !cooldown.has ("foo")) {
                noDisplay = true;
              }
            }
        }
    }

}
