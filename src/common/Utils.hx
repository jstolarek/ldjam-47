package common;

import haxe.macro.*;
import haxe.macro.Expr;

class Utils {
  function new( ) { }

  // Deserialize JSON map stored in `field`
  public static function parseJSONMap<T>( dynobj : Dynamic, field : String )
      : Map<String, T> {
    var map = new Map<String, T>();
    var mapJSON = Reflect.field( dynobj, field );

    for ( key in Reflect.fields( mapJSON ) ) {
      map.set( key, Reflect.field( mapJSON, key ) );
    }

    return map;
  }

  public static inline function msToFrames( ms      : Float
                                          , baseFPS : Float ) : Float {
    return ms * baseFPS / 1000;
  }

  public static inline function secToFrames( sec     : Float
                                           , baseFPS : Float ) : Float {
    return sec * baseFPS;
  }

  // Compute Euclidean distance between two points
  public static inline function dist( sx : Float, sy : Float
                                    , dx : Float, dy : Float ) : Float {
    var x = sx - dx;
    var y = sy - dy;
    return Math.sqrt( x * x + y * y );
  }

  // Restrict val to range [min, max]
  public static inline function fclamp( val : Float, min : Float
                                      , max : Float ) : Float {
    return (val < min) ? min : (val > max) ? max : val;
  }

  public static function mkVector2D<T>( height : Int, width : Int )  {
    var vec = new Vector( height );
    for ( y in 0...height ) {
      vec[ y ] = new Vector<T>( width );
    }
    return vec;
  }

  // Return git commit hash used for the build.  Use Const.COMMIT_HASH and
  // Const.COMMIT_HASH_FULL.  Adapted from Haxe Code Cookbook:
  //
  // https://code.haxe.org/category/macros/add-git-commit-hash-in-build.html
  public static macro function getGitCommitHash( ) : ExprOf<String> {
    var process    = new sys.io.Process( "git", [ "rev-parse", "HEAD" ] );
    var commitHash = "";

    if ( process.exitCode( ) == 0 ) {
      commitHash = process.stdout.readLine( );
    } else {
      var message = process.stderr.readAll( ).toString( );
      var pos     = Context.currentPos( );
#if ( devel )
      Context.warning( "Cannot execute `git rev-parse HEAD`. " + message, pos );
#else
      Context.error  ( "Cannot execute `git rev-parse HEAD`. " + message, pos );
#end
    }

    // Generates a string expression
    return macro $v{commitHash};
  }

}
