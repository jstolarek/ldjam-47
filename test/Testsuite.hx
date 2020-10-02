#if ( !( hl || js ) )
#error "Error: you must use either Hashlink (hl) or JavaScript (js) tagret"
#end

class Testsuite {
  public static function main( ) {
    utest.UTest.run(
      [ new gw.res.AsepriteTest()
      ]
    );
  }
}
