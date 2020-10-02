package gw.res;

import utest.Assert;

class AsepriteTest extends utest.Test {

  public function testInterpolateFrames1() {
    // input data
    var durations     = [ 50, 50 ];
    var speed         = 20;
    // expected results
    var expectedFrames = [ 0, 1 ];
    // test logic
    var actualFrames =
      @:privateAccess Aseprite.interpolateFrames( durations, speed );
    Assert.same( expectedFrames, actualFrames );
  }

  public function testInterpolateFrames2() {
    // input data
    var durations     = [ 50, 50 ];
    var speed         = 10;
    // expected results
    var expectedFrames = [ 0 ];
    // test logic
    var actualFrames =
      @:privateAccess Aseprite.interpolateFrames( durations, speed );
    Assert.same( expectedFrames, actualFrames );
  }

  public function testInterpolateFrames3() {
    // input data
    var durations     = [ 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90, 90 ];
    var speed         = 20;
    // expected results
    var expectedFrames = [ 0,  0,  1,  1,  2,  2,  3,  3,  4,  5,  5,
                           6,  6,  7,  7,  8,  8,  9, 10, 10, 11, 11 ];
    // test logic
    var actualFrames =
      @:privateAccess Aseprite.interpolateFrames( durations, speed );
    Assert.same( expectedFrames, actualFrames );
  }

  public function testInterpolateFrames4() {
    // input data
    var durations     = [ 50 ];
    var speed         = 10;
    // expected results
    var expectedFrames = [ 0 ];
    // test logic
    var actualFrames =
      @:privateAccess Aseprite.interpolateFrames( durations, speed );
    Assert.same( expectedFrames, actualFrames );
  }

  public function testInterpolateFrames5() {
    // input data
    var durations     = [ 50 ];
    var speed         = 10;
    // expected results
    var expectedFrames = [ 0 ];
    // test logic
    var actualFrames =
      @:privateAccess Aseprite.interpolateFrames( durations, speed );
    Assert.same( expectedFrames, actualFrames );
  }

  public function testInterpolateFrames6() {
    // input data
    var durations     = [ 50, 50, 50, 50, 50, 50, 50, 50, 50, 50 ];
    var speed         = 10;
    // expected results
    var expectedFrames = [ 0, 2, 4, 6, 8 ];
    // test logic
    var actualFrames =
      @:privateAccess Aseprite.interpolateFrames( durations, speed );
    Assert.same( expectedFrames, actualFrames );
  }

  public function testInterpolateFrames7() {
    // input data
    var durations     = [ 50, 50, 50, 50, 50, 50, 50, 50, 50, 50 ];
    var speed         = 20;
    // expected results
    var expectedFrames = [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 ];
    // test logic
    var actualFrames =
      @:privateAccess Aseprite.interpolateFrames( durations, speed );
    Assert.same( expectedFrames, actualFrames );
  }
}
