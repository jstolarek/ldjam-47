package assets;

class PNGUtilsException extends haxe.Exception {}

class PNGUtils {
  static var base64PNGMagic (default, never) = "data:image/png;base64";

  function new( ) { }

  // Decodes a base64-encoded PNG image to Tile
  static public function base64ToTile( base64 : String ) : h2d.Tile {
    var stream = base64.split( "," );
    if ( stream.length != 2 ) {
      throw new PNGUtilsException( "Can't parse base64 stream: " +
        base64.substr( 0, base64PNGMagic.length + 1 ) + "..." );
    }

    if ( stream[ 0 ] != base64PNGMagic ) {
      throw new PNGUtilsException
        ( "Unexpected magic number in base64 stream: " + stream[ 0 ] );
    }

    var bytes       = haxe.crypto.Base64.decode( stream[ 1 ] );
    var inputStream = new haxe.io.BytesInput( bytes );
    var pngData     = new format.png.Reader( inputStream ).read( );
    var header      = format.png.Tools.getHeader( pngData );
    var pixels      = hxd.Pixels.alloc( header.width, header.height, BGRA );

    format.png.Tools.extract32( pngData, pixels.bytes );
    return h2d.Tile.fromPixels( pixels );
  }
}
