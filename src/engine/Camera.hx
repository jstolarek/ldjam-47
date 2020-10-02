// Camera movement
// ===============
//
// A simple camera system that follows either a specified target or is fixed at
// given coordinates.  Camera parameters can be set via Const file.
//
// (c) Jan Stolarek 2020, MIT License

package engine;

// Note [Camera movement]
// ======================
//
// Camera works by moving the h2d.Layers object that contains the level and
// entities (but not HUD/UI and console).  When the camera is in it leftmost
// position its x coordinate is 0.  When it moves right x coordinate becomes
// negative.  We make sure that the coordinates don't move out of that range.
// If the level is narrower than the canvas (window) size then we just center
// it.  Similarly for moving camera up & down.

// Note [Camera movement wobble]
// =============================
//
// The algorithm for following the target is very simple and if the camera
// movement constants are not picked carefully the camera can wobble.  This is
// caused by camera going past the point it's supposed to track, slowing down
// beyond the dead zone, and then going back.

// Objects that can be followed by the camera need to have focusX and focusY
// coordinates
interface Followable {
  public var focusX (get, never) : Float;
  public var focusY (get, never) : Float;
}

class DummyTarget implements Followable {
  public var focusX (get, never) : Float;
  public var focusY (get, never) : Float;
         var x                    : Float;
         var y                    : Float;

  public function new ( x : Float, y : Float ) {
    this.x = x;
    this.y = y;
  }

  public inline function get_focusX( ) : Float {
    return x;
  }

  public inline function get_focusY( ) : Float {
    return y;
  }
}

class Camera extends Process {
  static var LOGGER = HexLog.getLogger( );

  public var canvasWidth  (get    , never) : Int;
  public var canvasHeight (get    , never) : Int;
  public var target       (default, set  ) : Null<Followable>;
  public var level        (get    , never) : Level;
  public var scroller     (get    , never) : h2d.Layers;

  var x        : Float = 0.0;  // (x, y) - current camera location
  var y        : Float = 0.0;
  var vx       : Float = 0.0;
  var vy       : Float = 0.0;

  public function new( ?parent : Process ) {
    super( parent );
    target = new DummyTarget( 0.0, 0.0 );
  }

  public inline function toTarget( ) : Void {
    x = target.focusX;
    y = target.focusY;
  }

  public inline function toCoords( x : Float, y : Float ) : Void {
    target = new DummyTarget( x, y );
    toTarget( );
  }

  override function fixedUpdate( ) {
    super.fixedUpdate( );

    var tx = target.focusX;
    var ty = target.focusY;

    // See Note [Camera movement wobble]
    var dist = Utils.dist( x, y, tx, ty ) - Const.CAMERA_DEADZONE;
    if ( dist >= 0.0 ) {
      var angle = Math.atan2( ty - y, tx - x );
      vx += Math.cos( angle ) * dist * Const.CAMERA_SPEED;
      vy += Math.sin( angle ) * dist * Const.CAMERA_SPEED;
    } else {
      vx = 0.0;
      vy = 0.0;
    }

    x += vx;
    y += vy;

    applyCameraSpeedFriction( );
  }

  // See Note [Camera movement]
  override function postUpdate( ) {
    if ( canvasWidth < level.pixelWidth ) {
      scroller.x = Utils.fclamp( canvasWidth * 0.5 - x
                               , canvasWidth - level.pixelWidth, 0 );
    } else {
      // if level fits canvas center it vertically
      scroller.x = (canvasWidth - level.pixelWidth) * 0.5;
    }

    if ( canvasHeight < level.pixelHeight ) {
      scroller.y = Utils.fclamp( canvasHeight * 0.5 - y
                               , canvasHeight - level.pixelHeight, 0 );
    } else {
      // if level fits canvas center it horizontally
      scroller.y = (canvasHeight - level.pixelHeight) * 0.5;
    }
  }

  function applyCameraSpeedFriction( ) : Void {
    vx *= Const.CAMERA_FRICTION;
    if ( Math.abs( vx ) <= Const.CAMERA_SPEED_CUTOFF ) {
      vx = 0;
    }

    vy *= Const.CAMERA_FRICTION;
    if ( Math.abs( vy ) <= Const.CAMERA_SPEED_CUTOFF ) {
      vy = 0;
    }
  }

  public inline function set_target( target : Followable ) : Followable {
    this.target = target;
    toTarget( );
    return this.target;
  }

  public inline function get_level( ) : Level {
    return Boot.ME.world.currentLevel;
  }

  public inline function get_scroller( ) : h2d.Layers {
    return Boot.ME.layers;
  }

  public inline function get_canvasWidth( ) : Int {
    return Main.ME.width;
  }

  public inline function get_canvasHeight( ) : Int {
    return Main.ME.height;
  }
}
