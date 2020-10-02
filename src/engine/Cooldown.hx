// Cooldowns and delayed actions
// =============================
//
// Cooldown class allows to register a cooldown of a given length, expressed in
// either miliseconds or frames.  Available cooldown values have to be expressed
// by an enum type and `Cooldown` class has to be parameterized by that type.
// Each created cooldown can have an optional callback that, if present, is
// executed when the cooldown time ends.
//
// (c) Jan Stolarek 2020, MIT License

package engine;

// Note [Valid cooldown keys]
// ==========================
//
// Keys are tested for equality using `==`.  This means only value types like
// Int, String, or enums will behave correctly.

private class CooldownInstance<T> {
  public var key      : T;
  public var duration : Float;
  public var callback : Void -> Void;

  public function new( key : T, duration : Float, ?callback : Void -> Void ) {
    this.key      = key;
    this.duration = duration;
    this.callback = callback;
  }
}

class Cooldown<T> {
  var cooldowns : Array<CooldownInstance<T>>;

  var baseFPS( default, null ) : Float;

  public function new( ?baseFPS = Const.WANTED_FPS ) {
    this.baseFPS = baseFPS;
    reset( );
  }

  // Remove all cooldowns
  public inline function reset( ) : Void {
    cooldowns = [];
  }

  // Check whether a given cooldown is set.  See Note [Valid cooldown keys]
  public inline function has( key : T ) : Bool {
    return Lambda.exists( cooldowns, function (cooldown)
        { return (key == cooldown.key); }
      );
  }

  // Set a cooldown lasting given number of frames.  If a given cooldown exists
  // remove it first.
  public function setF( key         : T
                      , frames      : Float
                      , ?onComplete : Void -> Void ) : Void {
    this.unset( key );
    cooldowns.push( new CooldownInstance( key, frames, onComplete ) );
  }

  // Set a cooldown lasting given number of miliseconds.  If a given cooldown
  // exists remove it first.
  public inline function setMs( key         : T
                              , ms          : Float
                              , ?onComplete : Void -> Void ) : Void {
    this.setF( key, Utils.msToFrames( ms, baseFPS ), onComplete );
  }

  // Check whether a given cooldown is set.  Of not, then set that cooldown
  // lasting given number of frames.
  public function hasSetF( key         : T
                         , frames      : Float
                         , ?onComplete : Void -> Void ) : Bool {
    if ( has( key ) ) {
      return true;
    } else {
      setF( key, frames, onComplete );
      return false;
    }
  }

  // Check whether a given cooldown is set.  Of not, then set that cooldown
  // lasting given number of miliseconds.
  public function hasSetMs( key         : T
                          , ms          : Float
                          , ?onComplete : Void -> Void ) : Bool {
    if ( has( key ) ) {
      return true;
    } else {
      setMs( key, ms, onComplete );
      return false;
    }
  }

  // Unset a given cooldown
  public inline function unset( key : T ) : Void {
    cooldowns = Lambda.filter( cooldowns, function (cooldown)
        { return ( key != cooldown.key ); }
     );
  }

  // Advance all cooldowns by a time amount specified in tmod.  Execute
  // callbacks for cooldowns that end.
  public function update( tmod : Float ) : Void {
    if ( cooldowns.length == 0 ) {
      return;
    }

    var updatedCooldowns = [];

    for ( cooldown in cooldowns ) {
      cooldown.duration -= tmod;
      if ( cooldown.duration > 0 ) {
        updatedCooldowns.push( cooldown );
      } else {
        if ( cooldown.callback != null ) {
          cooldown.callback( );
        }
      }
    }

    cooldowns = updatedCooldowns;
  }
}
