// Entities
// ========
//
// Entity is a process with animations, states, and (x, y) coordinates.
//
// (c) Jan Stolarek 2020, MIT License

package engine;

// Note [Coordinate system]
// ========================
//
//            x axis
//  (0, 0) ----------> (max_x, 0)
//     |                    |
//     |                    | y axis
//     v                    v
// (0,max_y) -------> (max_x, max_y)
//
// Game area consists of tiles placed on a grid.  Grid size is determined by
// level and stored in (gx, gy) fields for convenience.  Entity coordinates are
// expressed using coordinates of a grid tile (cx, cy) and a fractional location
// within a particular tile (xr, yr).  Values of xr and yr are floats from [0.0,
// 1.0) range.  Properties (x, y) store the decoded coordinates.


// TODO [Actions]
// --------------
//
// Entities should be able to take different internal states (charging a shot,
// performing attack animation, etc.).  Actions can be created, canceled.  There
// should be functions that say when a character is in a given state.  This
// should be combined with animations, possibly having a way of setting an
// active animation based on a condition, similarly to dn's registerStateAnim.


class Entity<S,T> extends Process implements Camera.Followable {
  static var LOGGER = HexLog.getLogger();

  // rendering layers
  static var _inc = 0;
  public static var MAIN_LAYER  = _inc++;
  public static var DEBUG_LAYER = _inc++;

  // See Note [Coordinate system]
  // cx, cy - grid coordinates
  // xr, yr - fractional coordinates within a single grid cell
  public var cx : Int = 0;
  public var cy : Int = 0;
  public var xr (default, set) : Float = 0.0;
  public var yr (default, set) : Float = 0.0;
  // gx, gy - grid size taken from the current level
         var gx (get, never) : Int;
         var gy (get, never) : Int;
  // x, y - actual coordinates based on all of the above
  public var x (get, never) : Float;
  public var y (get, never) : Float;
  // camera focus point
  public var focusX (get, never) : Float;
  public var focusY (get, never) : Float;

  // vx, vy - speed
  // frict  - speed attenuation
  public var vx    : Float = 0.0;
  public var vy    : Float = 0.0;
  public var frict : Float = Const.FRICTION;

  // Additional properties for convenience
  public var world (get, never) : World;
  public var level (get, never) : Level;
  // Debug label
  var debugLabel : Null<h2d.Text>;

  // Common entity logic
  var cooldown  : Cooldown<T>;
  var animation : Animation<S>;

  public function new( ?parent : Process ) {
    super( parent );

    cooldown  = new Cooldown<T>( );
    animation = new Animation<S>( );
    layers.add( animation, Entity.MAIN_LAYER );

#if ( devel )
    debugLabel = new h2d.Text( Fonts.barlow24 );
    layers.add( debugLabel, DEBUG_LAYER );
    debugLabel.visible = false;
#end
  }

  override function update( ) {
    animation.update( );
  }

  override function postUpdate( ) {
    layers.x = x - animation.pivotX;
    layers.y = y - animation.pivotY;

    // place the debugging label at the pivot
    debugLabel.x = animation.pivotX - Std.int( debugLabel.textWidth * 0.5 );
    debugLabel.y = animation.pivotY;
  }

  // When overriding update/fixedUpdate function this function has to called to
  // get friction to work
  function applySpeedFriction( ) : Void {
    vx *= frict;
    if ( Math.abs( vx ) <= Const.SPEED_CUTOFF ) {
      vx = 0;
    }

    vy *= frict;
    if ( Math.abs( vy ) <= Const.SPEED_CUTOFF ) {
      vy = 0;
    }
  }

  public inline function setDebugLabel( v : Dynamic, ?color = 0xffffff ) {
#if ( devel )
    if ( Boot.ME.console.hasFlag( Console.Flag.DEBUG_LABELS ) ) {
      debugLabel.visible   = true;
      debugLabel.text      = Std.string( v );
      debugLabel.textColor = color;
    } else {
      hideDebugLabel( );
    }
#end
  }

  public inline function hideDebugLabel( ) {
#if ( devel )
    debugLabel.visible = false;
#end
  }

   public inline function showDebugLabel( ) {
#if ( devel )
    debugLabel.visible = true;
#end
  }

  // Property accessors

  public inline function set_xr( new_xr : Float ) : Float {
    xr = new_xr;
    while ( xr >= 1.0 ) { xr--; cx++; }
    while ( xr <  0.0 ) { xr++; cx--; }
    return xr;
  }

  public inline function set_yr( new_yr : Float ) : Float {
    yr = new_yr;
    while ( yr >= 1.0 ) { yr--; cy++; }
    while ( yr <  0.0 ) { yr++; cy--; }
    return yr;
  }

  public inline function get_gx( ) : Int {
    return Boot.ME.world.currentLevel.gridX;
  }

  public inline function get_gy( ) : Int {
    return Boot.ME.world.currentLevel.gridY;
  }

  public inline function get_x( ) : Float {
    return (cx + xr) * gx;
  }

  public inline function get_y( ) : Float {
    return (cy + yr) * gy;
  }

  public inline function get_focusX( ) : Float {
    return x;
  }

  public inline function get_focusY( ) : Float {
    return y;
  }

  public inline function get_world( ) : World {
    return Boot.ME.world;
  }

  public inline function get_level( ) : Level {
    return Boot.ME.world.currentLevel;
  }
}
