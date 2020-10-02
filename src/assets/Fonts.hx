// Fonts
// =====
//
// See https://heaps.io/documentation/text.html
//
// (c) Jan Stolarek 2020, MIT License

package assets;

class Fonts {
  public static var _default : h2d.Font = null;

  public static var barlow9  : h2d.Font = null;
  public static var barlow12 : h2d.Font = null;
  public static var barlow18 : h2d.Font = null;
  public static var barlow24 : h2d.Font = null;
  public static var barlow32 : h2d.Font = null;

  static var initialized : Bool = false;

  private function new( ) { }

  public static function init( ) {
    if ( !initialized ) {
      _default = hxd.res.DefaultFont.get( );

      barlow9  = hxd.Res.fonts.barlow_condensed_medium_regular_9.toFont( );
      barlow12 = hxd.Res.fonts.barlow_condensed_medium_regular_12.toFont( );
      barlow18 = hxd.Res.fonts.barlow_condensed_medium_regular_18.toFont( );
      barlow24 = hxd.Res.fonts.barlow_condensed_medium_regular_24.toFont( );
      barlow32 = hxd.Res.fonts.barlow_condensed_medium_regular_32.toFont( );

      initialized = true;
    }
  }
}
