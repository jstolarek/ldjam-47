// Sprite animation
// ================
//
// A custom animation object that can play animation in one of two ways:
//
//  * it is possible to define state animations, which are animations that are
//    played when a given condition is satisfied.  Animations are ordered by
//    priority, the first one that matches is used.
//
//  * animations can be assembled in a queue and played in a sequence
//
// (c) Jan Stolarek 2020, MIT License

package engine;

// Note [Animation TODOs]
// ======================
//
// Several things are still unfinished or unimplemented at all:
//
//  * pivot support is broken.  In particular, camera does not follow an Entity
//    correctly when animation has a pivot.
//
//  * treatment of animation size needs rethinking.  Right now 
//
//  * destroying animation is not implemented

// Central animation point, expressed either in absolute pixels or relatively to
// animation size
class Pivot {
  public var x (default, null) : Float = 0.0;
  public var y (default, null) : Float = 0.0;
  public var isRelative        : Bool  = false;

  public function new( ?x=0.0, ?y=0.0, ?isRelative=false ) {
    this.x          = x;
    this.y          = y;
    this.isRelative = isRelative;
  }

  public function setAbsolute( x : Float, y : Float ) : Void {
    this.x = x;
    this.y = y;
    isRelative = false;
  }

  public function setRelative( x : Float, y : Float ) : Void {
    this.x = x;
    this.y = y;
    isRelative = true;
  }
}

// Describes size of a frame and placement of actual sprite inside a frame.
// This handles situations where frame is actually larger than the sprite
// itself.
typedef FrameDesc =
  { x            : Int // placement of sprite inside a frame
  , y            : Int
  , width        : Int // size of a sprite located at (x, y)
  , height       : Int
  , sourceWidth  : Int // frame size
  , sourceHeight : Int
  }

// A single state animation as contained in resources
class StateAnim {
  public var frames     : Array<h2d.Tile>  = []; // invariant: same lengths
  public var framesDesc : Array<FrameDesc> = [];

  public function new( ) { }
}

// A concrete instance of animation.  Can be paused, sped up, reversed, etc.
@:allow( engine.Animation )
class StateAnimInstance {
  var repeat    : Int          = 0;
  var looped    : Bool         = false;
  var speed     : Float        = 1.0;
  var reversed  : Bool         = false;
  var priority  : Int          = 0;
  var stateAnim : StateAnim    = null;
  var condition : Void -> Bool = null;
  var frameIdx  : Int          = 0;

  // Current animation frame and its description
  var frame     (get, null) : h2d.Tile;
  var frameDesc (get, null) : FrameDesc;

  function new( ) { }

  inline function get_frame( ) : h2d.Tile {
    return stateAnim.frames[ reversed ? stateAnim.frames.length - frameIdx - 1
                                      : frameIdx ];
  }

  inline function get_frameDesc( ) : FrameDesc {
    return stateAnim.framesDesc[
      reversed ? stateAnim.frames.length - frameIdx - 1 : frameIdx
    ];
  }

  inline function hasNextFrame( ) : Bool {
    return ( looped || repeat > 1 ||
             ( repeat == 0 && frameIdx < stateAnim.frames.length - 1 ) );
  }

  // Attempts to advance animation to next frame.  Returns false if animation
  // has no more frames to play
  inline function advanceFrame( ) : Bool {
    var isNextFrameAvailable = hasNextFrame( );
    if ( isNextFrameAvailable ) {
      frameIdx++;
      if ( frameIdx == stateAnim.frames.length ) {
        frameIdx = 0;
        repeat--;
      }
    }
    return isNextFrameAvailable;
  }
}

// Animation is parameterized by T that enumerates all possible animation states
// defined in asperite sprite sheet.  In practice T has to be either an Int or
// an abstract enum with Int as an underlying type.  Use Unit if animation
// contains only one state.
class Animation<T> extends h2d.Drawable {
  static var LOGGER = HexLog.getLogger( );

  public var stateAnims           : Map<T, StateAnim>;
  // Known state animations
         var registeredStateAnims : Array<StateAnimInstance>;
  // Queue of animations to play.  When using state animations we only make use
  // of the first element in the queue, which contains animation corresponding
  // to the current state.
         var animationQueue       : Array<StateAnimInstance>;
  public var useStateAnimations   : Bool;
  public var pivot (default, set) : Pivot;
  public var paused               : Bool;

         var framesElapsed        : Float;

  public var width            (get, never) : Float;
  public var height           (get, never) : Float;
         var currentAnimation (get, never) : Null<StateAnimInstance>;
         var hasAnimation     (get, never) : Bool;
  public var pivotX           (get, never) : Float;
  public var pivotY           (get, never) : Float;

  public function new ( ?parent : h2d.Object ) {
    super( parent );

    framesElapsed        = 0.0;
    useStateAnimations   = false;
    paused               = false;
    animationQueue       = [ ];
    registeredStateAnims = [ ];
    pivot                = new Pivot( );
  }

  public function registerStateAnimation( state      : T
                                        , priority   : Int
                                        , ?condition : Void -> Bool
                                        , ?loop      : Bool
                                        ) : Void {
    useStateAnimations = true;

    var anim = new StateAnimInstance( );
    anim.stateAnim = stateAnims.get( state );
    anim.priority  = priority;
    if( loop != null){
      anim.looped = loop;
    } else {
      anim.looped    = true; // state animations assumed to be loops by default
    }
    if ( condition != null ) {
      anim.condition = condition;
    } else {
      anim.condition = function ( ) { return true; }
    }

    registeredStateAnims.push( anim );
    registeredStateAnims.sort( function ( a, b ) {
        return -Reflect.compare( a.priority, b.priority );
      } );
  }

  function updateStateAnimation( ) : Void {
    if ( useStateAnimations ) {
      for ( anim in registeredStateAnims ) {
        if ( anim.condition( ) ) {
          if ( animationQueue.length == 0 || animationQueue[ 0 ] != anim ) {
            animationQueue = [ anim ];
          }
          return;
        }
      }
    }
  }

  public inline function clearAnimationQueue( ) : Animation<T> {
    animationQueue = [ ];
    return this;
  }

  public inline function clearStateAnimations( ) : Animation<T> {
    useStateAnimations   = false;
    animationQueue       = [ ];
    registeredStateAnims = [ ];
    return this;
  }

  public function update( ) {
    updateStateAnimation( );
  }

  override function draw( ctx : h2d.RenderContext ) {
    if ( currentAnimation != null ) {
      emitTile( ctx, currentAnimation.frame );
    }
  }

  override function sync( ctx : h2d.RenderContext ) {
    super.sync( ctx );

    if ( !paused && currentAnimation != null ) {
      framesElapsed += Const.ANIM_SPEED * ctx.elapsedTime *
        currentAnimation.speed;

      while ( framesElapsed >= 1.0 ) {
        framesElapsed -= 1.0;
        // Advance one frame of current animation.  If animation has no frames
        // left advance to next animation, unless we're using state animations -
        // in such cases there should always be just one animation in the queue.
        if ( !currentAnimation.advanceFrame( ) && !useStateAnimations ) {
          animationQueue.shift( );
        }
      }
    }
  }

  inline function set_pivot( pivot : Pivot ) : Pivot {
    this.pivot = pivot;
    this.x = -pivotX;
    this.y = -pivotY;
    return pivot;
  }

  inline function get_width( ) : Float {
    return hasAnimation ? currentAnimation.frameDesc.sourceWidth : 0;
  }

  inline function get_height( ) : Float {
    return hasAnimation ? currentAnimation.frameDesc.sourceHeight : 0;
  }

  inline function get_hasAnimation( ) : Bool {
    return animationQueue != null && animationQueue.length > 0;
  }

  inline function get_currentAnimation( ) : StateAnimInstance {
    return hasAnimation ? animationQueue[ 0 ] : null;
  }

  public inline function get_pivotX( ) : Float {
    return pivot.isRelative ? pivot.x * width : pivot.x;
  }

  public inline function get_pivotY( ) : Float {
    return pivot.isRelative ? pivot.y * height : pivot.y;
  }
}
