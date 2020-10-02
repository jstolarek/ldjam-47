// Processes
// =========
//
// GameWheel stores all engine entities as processes organised in a tree
// hierarchy.  Each process has a unique id, might have a parent (if not, a
// process is stored in a global table of root processed) and children.  Each
// process can be either paused and destroyed.  Finally, all processes are
// repeatedly updated in loop - see Note [Process loop].
//
// Design of this file based on Sébastien Bénard's deepnightLibs.  The code here
// is mostly a rewrite of parts of his code with some minor design changes.
//
// (c) Jan Stolarek 2020, MIT License

package engine;

// Note [Process loop]
// ===================
//
// All processes are updated in a loop called from the application's main
// `update` function.  Update loop frequency is defined in Const.WANTED_FPS.
// Default value is 60FPS and heaps does its best to maintain that refresh rate.
// GameWheel measures time in frames elapsed since the last update
// (hxd.Timer.tmod) - ideally, this should of course be 1.  A single iteration
// of the update loop has the following structure:
//
//  1. Update the number of frames elapsed since the last call to application's
//     main `update` function.  This value is stored in a static variable
//     Process.TMOD shared between all processes.
//
//  2. Call `update` function of all processes.  This function should contain
//     things like rendering or logic.  It shouldn't update the game state but
//     rather use existing state to generate output for the user.  As such it
//     shouldn't care about the actual TMOD value.  Note that while heaps.io
//     does its best to maintain a desired update rate (Const.WANTED_FPS), the
//     actual refresh rate might actually be different than expected.  For this
//     reason this function shouldn't contain any time-sensitive computations.
//
//  3. Call `fixedUpdate` function of all processes.  This function should
//     contain all the updates to game logic.  This function is guaranteed to
//     run at a rate defined in Const.FIXED_FPS and it should thus contain all
//     time-sensitive computations like physics, etc.  Note that since the
//     update frequency is known and constant it doesn't have to be explicitly
//     taken into acount in the computations
//
//  4. Call `postUpdate` function of all processes.  Anything that should be
//     done only after all rendering and game logic updates have finished goes
//     in this functions.
//
//  5. Garbage collection.  Any processes that have been (marked as_ destroyed
//     are now removed.  It is important that this is only done after all the
//     updates have finished.  Otherwise there could be game logic
//     inconsistencies.
//
// Process loop traverses processes in a depth-first pre-order traversal, except
// for garbage collecting, which performs a depth-first post-order traversal.


// Note [Process hierarchy]
// ========================
//
// Processes are organized in a tree-like hierarchy.  Each process can have at
// most one parent and any number of children.  Processes without a parent are
// stored on a list of root processes.


// Note [Rendering hierarchy]
// ==========================
//
// Each process has `layers` field which is a `h2d.Layers` object - essentially
// a list of objects to render and their depth (lowest number levels are at the
// bottom).  Rendering layers are initialised in the constructor.  To render a
// process it must be stored on its parent process `layers` list.  Processes
// without a parent are rendered directly on `s2d` (heaps.io scene root).  This
// is managed using `show`/`hide`/`showChild`/`hideChild` functions.  It is
// important that correct process hierarchy exists before rendering hierarchy is
// managed - otherwise null pointer exceptions or assertion errors will happen.
//
// When a process changes its parent care should be taken to hide the process
// first.  Otherwise we'll be in a situation where a process' parent is
// different than `layers` parent.
//
// This isn't really an informed design, more of an attempt at future-proofing.
// Everything is subject to change as new needs emerge.

class ProcessException extends haxe.Exception {}

class Process {
  static var LOGGER = HexLog.getLogger();

  // process hierarchy
  static var ROOTS    : Array<Process> = [];
         var pid      : Int;
         var parent   : Null<Process>;
         var children : Array<Process>;

  // rendering hierarchy
  public var layers : h2d.Layers;

  // process status
  var paused    : Bool;
  var destroyed : Bool;

  // timings and updates
  static var TMOD              : Float = 1.0;
         var fixedUpdateFrames : Float = 0.0;

  public function new( ?parent : Process ) {
    pid               = Uniq.get();
    children          = [];
    paused            = false;
    destroyed         = false;
    layers            = new h2d.Layers( );
    this.parent       = parent;

    LOGGER.debug( "Creating process pid_" + pid );

    if ( parent == null ) {
      ROOTS.push( this );
    } else {
      parent.addChild( this );
    }
  }

  // process hierarchy
  public function addChild( p : Process ) : Void {
    if ( p.parent == null ) {
      ROOTS.remove( p );
    } else {
      p.parent.children.remove( p );
    }

    p.parent = this;
    children.push( p );
  }

  public function moveChildToRootProcesses( p : Process ) : Void {
    assert( isChild( p ) );

    p.parent = null;
    children.remove( p );
    ROOTS.push( p );
  }

  public function destroyChild( p : Process ) : Void {
    assert ( isChild( p ) );

    p.destroy( );
  }

  public function destroyAllChildren( ) : Void {
    for ( child in children ) {
      child.destroyAllChildren( );
      child.destroy( );
    }
  }

  inline function isChild( p : Process ) : Bool {
    var isParent = (p.parent == this);
    var hasChild = children.contains( p );

    if ( isParent != hasChild ) {
      throw new ProcessException ( "Inconsistent process hierarchy: \n" +
        "Is " + this.toString() + " parent of " + p.toString() + ": " + isParent
        + "\n" +
        "Is " + p.toString() + " child of " + this.toString() + ": " + hasChild
       );
    }

    return isParent;
  }

  // Managing and querying process state
  inline function canRun( ) : Bool {
    return !paused && !destroyed;
  }

  public inline function pause( ) : Void {
    paused = true;
  }

  public inline function resume( ) : Void {
    paused = false;
  }

  public inline function togglePause( ) : Void {
    paused ? resume() : pause();
  }

  public inline function destroy( ) : Void {
    destroyed = true;
  }

  // Rendering.  See Note [Rendering hierarchy]
  public function show( plan : Int ) : Void {
    if ( parent != null ) {
      parent.showChild( this, plan );
    } else {
      Main.ME.s2d.add( layers, plan );
    }
  }

  public function showChild( p : Process, plan : Int ) : Void {
    assert( isChild( p ) );

    layers.add( p.layers, plan );
  }

  public function hide( ) : Void {
    if ( parent != null ) {
      parent.hideChild( this );
    } else {
      Main.ME.s2d.removeChild( layers );
    }
  }

  public function hideChild( p : Process ) : Void {
    assert( isChild( p ) );

    layers.removeChild( p.layers );
  }

  public function isRendered( ) : Bool {
    if ( parent != null ) {
      return parent.layers.getChildIndex( layers ) != -1;
    } else {
      return Main.ME.s2d.getChildIndex( layers ) != -1;
    }
  }

  public function isChildRendered( p : Process ) : Bool {
    assert( isChild( p ) );

    return layers.getChildIndex( p.layers ) != -1;
  }

  // Utility functions
  public inline function toString( ) : String {
    return "pid_" + pid;
  }

  // Per-process update and event functions
  public function update( )      {}
  public function fixedUpdate( ) {}
  public function postUpdate( )  {}
  public function onResize( )    {}
  public function onDispose( )   {}

  // See Note [Process loop]
  public static function updateAll( tmod : Float ) : Void {
    Process.TMOD = tmod;

    for ( p in ROOTS ) {
      doUpdate( p );
    }

    for ( p in ROOTS ) {
      doFixedUpdate( p );
    }

    for ( p in ROOTS ) {
      doPostUpdate( p );
    }

    ROOTS = garbageCollector( ROOTS );
  }

  static function doUpdate( p : Process ) : Void {
    if ( !p.canRun( ) ) {
      return;
    }

    p.update( );

    if ( p.canRun( ) ) {
      for ( child in p.children ) {
        doUpdate( child );
      }
    }
  }

  static function doFixedUpdate( p : Process ) : Void {
    if ( !p.canRun( ) ) {
      return;
    }

    // https://gafferongames.com/post/fix_your_timestep/
    p.fixedUpdateFrames += Process.TMOD;
    while ( p.fixedUpdateFrames >= Const.FIXED_FPS_RATIO ) {
      p.fixedUpdateFrames -= Const.FIXED_FPS_RATIO;
      if ( p.canRun( ) ) {
        p.fixedUpdate( );
      }
    }

    if ( p.canRun( ) ) {
      for ( child in p.children ) {
        doFixedUpdate( child );
      }
    }
  }

  static function doPostUpdate( p : Process ) : Void {
    if ( !p.canRun( ) ) {
      return;
    }

    p.postUpdate( );

    if( !p.destroyed ) {
      for ( child in p.children ) {
        doPostUpdate( child );
      }
    }
  }

  static function garbageCollector( ps : Array<Process> ) : Array<Process> {
    var psGC = [];

    for ( p in ps ) {
      if( p.destroyed ) {
        doDispose( p );
      } else {
        psGC.push( p );
        p.children = garbageCollector( p.children );
      }
    }

    return psGC;
  }

  static function doDispose( p : Process ) : Void {
    for( p in p.children ) {
      doDispose( p );
    }

    p.onDispose();

    if ( p.parent != null ) {
      p.parent.layers.removeChild( p.layers );
      p.parent.children.remove( p );
    } else {
      ROOTS.remove( p );
      Main.ME.s2d.removeChild( p.layers );
    }

    p.parent = null;
    // by this point all the children should have removed themselves
    assert( p.children.length    == 0 );
    assert( p.layers.numChildren == 0 );
    p.children = null;
    p.layers   = null;
  }

  public static function resizeAll( ) : Void {
    for ( p in ROOTS ) {
      doResize( p );
    }
  }

  static function doResize( p : Process ) : Void {
    if ( !p.destroyed ) {
      p.onResize( );
      for ( child in p.children )
        doResize( child );
    }
  }
}
