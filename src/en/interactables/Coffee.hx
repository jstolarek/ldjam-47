package en.interactables;

class Coffee extends Interactable {

    static var LOGGER = HexLog.getLogger( );

    public function new( posX : Int, posY: Int, player: Player ) {
        super( posX, posY, "coffee", player );
    }

    override function interact( ) {
        LOGGER.debug( "Have a tasty coffee!!" );
    }

}
