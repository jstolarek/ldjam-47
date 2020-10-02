// Tileset
// =======
//
// Representation of a tileset used to create a level in OGMO.  Tilesets are
// stored as part of the world representation.  Tiles are assumed to have the
// same size.
//
// (c) Jan Stolarek 2020, MIT License

package assets;

class TileSetException extends haxe.Exception {}

class TileSet {
  public var tile(default, null) : h2d.Tile;
         var label               : String;
         var tiles               : Vector<h2d.Tile>;
         var tileWidth           : Int;
         var tileHeight          : Int;

  public function new( template : ogmo.Project.TilesetTemplate ) {
    label = template.label;

    if ( template.tileSeparationX != 0 || template.tileSeparationY != 0 ) {
      throw new TileSetException( "Tile separation not supported (in tileset "
                                + label + ")" );
    }

    if ( template.image != null && template.image.length > 0 ) {
      tile = PNGUtils.base64ToTile( template.image );
    } else {
      throw new TileSetException( "No tile data in " + template.label + ". " +
        "PNG tileset must be embedded in project file." );
    }

    tileWidth  = template.tileWidth;
    tileHeight = template.tileHeight;

    var tileRows    = Math.ceil( tile.height / tileHeight );
    var tileColumns = Math.ceil( tile.width  / tileWidth  );
    tiles           = new Vector( tileRows * tileColumns );

    for (y in 0...tileRows ) {
      for (x in 0...tileColumns ) {
        tiles[ y * tileColumns + x ] =
          tile.sub( x * tileWidth, y * tileHeight, tileWidth, tileHeight );
      }
    }
  }

  public inline function getTile( index : Int ) : h2d.Tile {
    return tiles[ index ];
  }
}
