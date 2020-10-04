package en.interactables;

class Coffee extends Interactable {

    static var LOGGER = HexLog.getLogger( );

    public function new( posX : Int, posY: Int, player: Player ) {
        super( posX, posY, "coffee", player );
    }

    override function interact( ) {
        LOGGER.debug( "Activating coffee boost" );
        Boot.ME.player.speed *= Const.COFFEE_SPEED_BOOST_FACTOR;
        Boot.ME.player.cooldown.setMs( "coffee", Const.COFFEE_BOOST_DURATION,
          function ( ) {
            LOGGER.debug( "Coffee boost finished" );
            Boot.ME.player.speed = Const.PLAYER_SPEED;
          } );
    }

}
