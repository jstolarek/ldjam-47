package en.interactables;

class Key extends Interactable {

    static var LOGGER = HexLog.getLogger( );

    public function new( posX : Int, posY: Int, player: Player ) {
        super( posX, posY, "key", player );
    }

    override function interact( ) {
        LOGGER.debug( "What a nice key!" );
    }

}