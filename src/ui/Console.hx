// Console
// =======
//
// A console combined with logging system.  Press ~ to show/hide.  Can be
// extended with custom commands - see heaps.io documentation.
//
// (c) Jan Stolarek 2020, MIT License

package ui;

// Note [Limiting console slowdowns]
// =================================
//
// Too many messages displayed in the console leads to drastic FPS drops because
// all the messages are stored in one huge texture.  So once in a while, when
// the number of messages exceeds a defined maximum, we remove old messages
// (which aren't displayed anyway) and only keep a small number of recent
// messages.

enum abstract Flag(String) from String to String {
  // Display FPS counter
  var FPS               = "fps";
  // Display debug labels on entities
  var DEBUG_LABELS      = "labels";
  // Show debugging messages from loggers even when console isn't active
  var ALWAYS_SHOW_DEBUG = "debug";
  // Should console have exclusive focus?  If set then player actions are not
  // registered when console is open.
  var EXCLUSIVE_FOCUS   = "focus";
  var GRID              = "grid";
  var GOD               = "god";
}

class Console extends h2d.Console {
  var flags    : Map<Flag, Unit> = null;
  var messages : Array<String>   = [];

  public function new( font    : h2d.Font
                     , ?color=0xFFFFFF
                     , ?parent : h2d.Object ) {
    super( font, parent );

    h2d.Console.HIDE_LOG_TIMEOUT = Const.LOG_TIMEOUT;

    flags = new Map<Flag, Unit>( );

    addCommand( "set", [ { name : "flag", opt : false, t : AString } ],
     function ( flag ) {
        flags.set( flag, Unit );
        log( "+" + flag, 0x00EE00 );
      } );
    addAlias( "+", "set" );

    addCommand( "unset", [ { name : "flag", opt : true, t : AString } ],
     function ( flag ) {
       if ( flag != null ) {
        flags.remove( flag );
        log( "-" + flag, 0xEE0000 );
       } else {
        flags.clear( );
        log( "Clearing all flags", 0xEE0000 );
       }
      } );
    addAlias( "-", "unset" );

    // Flags enabled by default
//    flags.set( ALWAYS_SHOW_DEBUG, Unit );
    flags.set( EXCLUSIVE_FOCUS  , Unit );
    flags.set( DEBUG_LABELS     , Unit );
    flags.set( GRID             , Unit );

    haxe.Log.trace = function ( message, ?pos ) {
#if ( devel )
      if ( isActive( ) || hasFlag( ALWAYS_SHOW_DEBUG ) ) {
        log( Std.string( message ), color );
        messages.push( message );
      }

      // See Note [Limiting console slowdowns]
      if ( messages.length > Const.LOG_MAX_SIZE ) {
        while ( messages.length > Const.LOG_MIN_SIZE ) {
          messages.shift( );
        }
        logTxt.text = "";
        for ( message in messages ) { log( message, color ); }
      }
#end
    }
  }

  public inline function hasFlag( flag : String ) : Bool {
#if ( devel )
    return flags.exists( flag );
#else
    return false;
#end
  }
}
