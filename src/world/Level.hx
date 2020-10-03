package world;

class LevelException extends haxe.Exception {}

class Level extends Process {
  // rendering layers
  static var _inc = 0;
  public static var BG_LAYER = _inc++;
  public static var FG_LAYER = _inc++;

  public var name        (default, null  ) : LevelName;
  public var displayName (default, null  ) : String;
         var collisions                    : Vector<Vector<Collision>>;
         var background                    : h2d.Object;
         var foreground                    : h2d.Object;
  public var height      (default, set   ) : Int = -1;
  public var width       (default, set   ) : Int = -1;
  public var gridX       (default, set   ) : Int = -1;
  public var gridY       (default, set   ) : Int = -1;
  public var pixelHeight (get    , never ) : Int;
  public var pixelWidth  (get    , never ) : Int;
         var managers                      : Array<Manager> = [];

  public function new( name        : LevelName
                     , displayName : String
                     , ?parent     : Process ) {
    super( parent );
    this.name        = name;
    this.displayName = displayName;
    this.collisions  = null;
    this.background  = null;
  }

  public inline function addManager( manager : Manager ) : Void {
    managers.push( manager );
    Boot.ME.layers.add( manager.layers, Boot.ENTITY_LAYER );
  }

  // Collision management
  public inline function setCollision( x : Int
                                     , y : Int
                                     , collision : Collision ) : Void {
    collisions[ y ][ x ] = collision;
  }

  public inline function isValid( x : Int, y : Int ) : Bool {
    return ( x >= 0 && y >= 0 && x < width && y < height);
  }

  public inline function hasCollision( x : Int, y : Int ) : Bool {
    return isValid( x, y ) && collisions[ y ][ x ] != Collision.NONE;
  }

  // Level loading.  These setter functions should not be used once the level is
  // loaded.
  public function setBackground( background : h2d.Object ) : Void {
    assert( this.background == null );

    this.background = background;
    layers.add( background, BG_LAYER );
  }

  public function setForeground( foreground : h2d.Object ) : Void {
    assert( this.foreground == null );

    this.foreground = foreground;
    layers.add( foreground, FG_LAYER );
  }

  public function set_height( height : Int ) : Int {
    if ( this.height != -1 && this.height != height ) {
      throw new LevelException( "Inconsistent level height: " + this.height +
                                " and " + height );
    }
    return (this.height = height);
  }

  public function set_width( width : Int ) : Int {
    if ( this.width != -1 && this.width != width ) {
      throw new LevelException( "Inconsistent level width: " + this.width +
                                " and " + width );
    }
    return (this.width = width);
  }

  public function set_gridX( gridX : Int ) : Int {
    if ( this.gridX != -1 && this.gridX != gridX ) {
      throw new LevelException( "Inconsistent gridX in level " + displayName +
                                ": " + this.gridX + " and " + gridX );
    }
    return (this.gridX = gridX);
  }

  public function set_gridY( gridY : Int ) : Int {
    if ( this.gridY != -1 && this.gridY != gridY ) {
      throw new LevelException( "Inconsistent gridY in level " + displayName +
                                ": " + this.gridY + " and " + gridY );
    }
    return (this.gridY = gridY);
  }

  public inline function get_pixelHeight( ) : Int {
    return height * gridX;
  }

  public inline function get_pixelWidth( ) : Int {
    return width * gridY;
  }
}
