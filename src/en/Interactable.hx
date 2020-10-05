// Interactables
// ========
//
// Docs here
//
// (c) Jan Stolarek 2020, MIT License

package en;

class InteractableException extends haxe.Exception {}

enum abstract InteractableState(Int) from Int to Int {
    var IDLE;
    var CAN_INTERACT;
    var INTERACTION_PERFORMED;

    public static inline var length : Int = 3;

    @:to
    public function toString( ) : String {
      switch ( this ) {
        case IDLE : return "idle";
        case CAN_INTERACT : return "can_interact";
        case INTERACTION_PERFORMED : return "interaction_performed";
        default   :
          throw new InteractableException( "Unrecognised interactable state: " + this );
      }
    }

    @:from
    public static function fromString( str : String ) : InteractableState {
      switch ( str ) {
        case "idle" : return IDLE;
        case "can_interact" : return CAN_INTERACT;
        case "interaction_performed" : return INTERACTION_PERFORMED;
        default   :
          throw new InteractableException( "Unrecognised interactable state: " + str );
      }
    }
  }

class Interactable extends Entity<InteractableState, String> implements Resetable  {
    public var spriteSheetName = "key";

    public var interactRadius = 2.0;
    public var canInteract = false;
    public var interactionPerformed = false; //can be triggered once
    static var LOGGER = HexLog.getLogger( );
           var player : Player;

    public function new( posX : Int, posY: Int, spriteName: String, pl: Player ) {
        super( );

        cx = posX;
        cy = posY;
        spriteSheetName = spriteName;
        player = pl;

        animation.stateAnims =
            Aseprite.loadStateAnimation( spriteSheetName, InteractableState.fromString );

//        animation.pivot = new Animation.Pivot( 0.5, 0.5, true );

        animation.registerStateAnimation( CAN_INTERACT, 2, function ( ) {
            return canInteract;
        } );
        animation.registerStateAnimation( INTERACTION_PERFORMED, 1, function ( ) {
            return interactionPerformed;
        } );
        animation.registerStateAnimation( IDLE, 0, function ( ) {
            return true;
        } );

    }

    override function fixedUpdate( ) {
        //setDebugLabel(  "(" + Std.string( Math.floor( x ) ) +
        //                "," + Std.string( Math.floor( y ) ) + ") " + interactionPerformed , 0x66dd99 );
        canInteract = checkCanInteract();
        if (interactionPerformed) return;
        if (canInteract && player.isAction( ATTACK )) {
            interact( );
            interactionPerformed = true;
        }
    }

    function checkCanInteract( ) {
        var dist = Math.sqrt(Math.pow(player.cx - cx, 2) + Math.pow(player.cy - cy, 2));
        var newCanInteract = ( dist < interactRadius ? true : false ) && !interactionPerformed;
        if( canInteract != newCanInteract ) {
  //          LOGGER.debug( "Interactable status for item " + spriteSheetName + " changed to: " + newCanInteract );
        }
        return newCanInteract;
    }

    function interact( ) {
//        LOGGER.debug( "Interacting with base object!" );
        // do stuff here
    }

    public function resetObject() : Void {
        interactionPerformed = false;
    }
}
