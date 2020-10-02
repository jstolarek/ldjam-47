// Aseprite sprite sheet import
// ============================
//
// Imports a sprite sheet exported from Aseprite and converts it to an
// animation.  A sprite sheet must be saved in a format supported by heaps
// resource loader and accompanied by a JSON file with frame data in "Array"
// format describing the sheet contents.  See Note [Frame storage formats] for
// details.  Heaps engine and resource manager must both be initialised prior to
// loading a sprite sheet.
//
// Tested with Aseprite 1.2.25 on Linux
//
// (c) Jan Stolarek 2020, MIT License

package assets;

// Note [Frame storage formats]
// ============================
//
// Aseprite exports frame information in one of two formats:
//
//   1. Hash format
//
//      "frames": {
//         "hero_1.png" : { ... },
//         "hero_2.png" : { ... }
//       }
//
//   2. Array format:
//
//      "frames": [
//         { "filename" : "hero_1.png", ... },
//         { "filename" : "hero_2.png", ... }
//       ]
//
// The former format is ill-conceived: the order of frames matters but the order
// of fields in a JSON file does not.  This leads to frames being put in a
// random order when loading from a file in Hash format.  This format is
// therefore unsupported.  Use Array format instead.
//
// The method of detecting Hash format is target-dependent and somewhat hacky.
// On Hashlink target we use reflection to check whether the "frames" field is
// internally represented as an array.  If it isn't then we are dealing with a
// Hash format.  On JavaScript target the frame information is always stored
// internally as if it was in Hash format - for an Array format keys are
// integers starting from 0.  We therefore check the presence of "filename"
// field in frame description.  If it's missing this means the file is in Hash
// format.


// Note [Optional Aseprite JSON fields]
// ====================================
//
// Several fields in the JSON file are optional (frameTags, layers, slices).  If
// these fields are missing they are initialised to empty arrays.  Attempting to
// initialise an already present field raises an exception.


// Note [Aseprite JSON data conversions]
// =====================================
//
// Several fields are parsed from strings to more specific data types:
//
//  * "animDirection" and "blendMode" fields are turned into enumerations
//  * "scale" is turned into a Float


// Note [Frame interpolation]
// ==========================
//
// Each frame exported from Aseprite has an assigned duration expressed in
// milliseconds (100ms seems to be the default for newly created animations).
// However, heaps operates in terms of frames per second, not frame durations.
// By default heaps assumes animations are 15 frames per second -- see
// h2d.Anim.new and do not confuse this value with a default refresh rate of
// 60FPS defined in hxd.Timer.wantedFPS.  When loading a sprite sheet we need to
// convert its animation frames to match the animation rate expected by heaps.
// This means duplicating or dropping frames, as necessary.  (If you're dropping
// frames this means your animation was prepared at a higher framerate than is
// being used - ask yourself whether this is really OK.)  Note that choosing
// frame durations in Aseprite that are not a multiple of heaps animation frame
// duration will lead to frames not being multiplied uniformly.  This might
// result in animation stuttering.  To help mitigate the problem gameWheel
// assumes a default animation speed of 20FPS, which leads to one frame lasting
// 50ms.  This allows to create animations in Aseprite with frames lasting 100ms
// (each frame will then be duplicated) or 50ms (each frame will be used exactly
// once).


// Note [Unsupported Aseprite features]
// ====================================
//
// While this library takes care to correctly parse and load a JSON file
// produced by Aseprite many, if not most, fields are actually unused.  Most
// notably tag, layers, and slices information is ignored, which further leads
// to some information nested inside these data structures to be unsupported:
//
//   * (direction : AnimDirection) inside TagDesc is ignored
//
//   * scale fields are ignored
//
//   * blendMode inside LayerDesc is converted into an internal enum BlendMode.
//     There is a h2d.BlendMode enum in heaps but there is little overlap
//     between blend modes offered by heaps and those offered by Aseprite.
//
//   * color inside SliceDesc is stored as a String but it should have a
//     different representation in order to become useful
//
// Finally, "rotated" field in FrameDesc is not used.  All of these missing
// features are due to lack of need on my side.  Also, the ignored fields are
// not validated for correctness, except for conversions to enum types
// AnimDirection and BlendMode.


typedef FrameDesc =
  { filename         : String
  , frame            : Rect
  , rotated          : Bool
  , trimmed          : Bool
  , spriteSourceSize : Rect
  , sourceSize       : Size
  , duration         : Int
  }

enum AnimDirection {
  FORWARD ;
  REVERSE ;
  PINGPONG;
}

typedef TagDesc =
  { name      : String
  , from      : Int
  , to        : Int
  , direction : AnimDirection
  }

enum BlendMode {
  NORMAL      ;
  DARKEN      ;
  MULTIPLY    ;
  COLOR_BURN  ;
  LIGHTEN     ;
  SCREEN      ;
  COLOR_DODGE ;
  ADDITION    ;
  OVERLAY     ;
  SOFT_LIGHT  ;
  HARD_LIGHT  ;
  DIFFERENCE  ;
  EXCLUSION   ;
  SUBTRACT    ;
  DIVIDE      ;
  HUE         ;
  SATURATION  ;
  COLOR       ;
  LUMINOSITY  ;
}

typedef LayerDesc =
  { name      : String
  , opacity   : Int
  , blendMode : BlendMode
  }

typedef SliceKeyDesc =
  { frame  : Int
  , bounds : Rect
  , center : Rect
  , pivot  : Point
  }

typedef SliceDesc =
  { name  : String
  , color : String
  , data  : String
  , keys  : Array<SliceKeyDesc>
  }

typedef MetaDesc =
  { app       : String
  , version   : String
  , image     : String
  , format    : String
  , size      : Size
  , scale     : Float
    // See Note [Unsupported Aseprite features]
  , frameTags : Array<TagDesc>
  , layers    : Array<LayerDesc>
  , slices    : Array<SliceDesc>
  }

typedef SheetDesc =
  { frames : Array<FrameDesc>
  , meta   : MetaDesc
  }

class AsepriteParseException extends haxe.Exception {}

class Aseprite {
  static var LOGGER = HexLog.getLogger();

  function new( ) { }

  // Creates a h2d.Anim object and appends it to a parent, or creates new parent
  // if none supplied.  Frame tags are not supported, so all frames are placed
  // in a single animation.
  public static function loadSpriteSheet( filepath : String
                                        , ?parent  : h2d.Object ) : h2d.Object {
    LOGGER.info( "Loading sprite sheet " + filepath );
    var jsonFile  = filepath + ".json";
    var sheetDesc = loadSheetDesc( jsonFile );

    if ( sheetDesc.meta.frameTags != null ) {
      LOGGER.warn( "Creating heaps animation from an Aseprite sheet that " +
                   "contains tags" );
    }

    var sheetDir  = haxe.io.Path.directory( jsonFile );
    var imageFile = haxe.io.Path.join( [ sheetDir, sheetDesc.meta.image ] );
    var sheet     = hxd.Res.loader.load( imageFile ).toTile();
    var animSize  = sheetDesc.meta.size;
    var frames    = new Array<h2d.Tile>();

    // reconstruct animation frames from a sprite sheet
    for ( f in sheetDesc.frames ) {
      frames.push( sheet.sub( f.frame.x, f.frame.y, f.frame.w, f.frame.h,
                              f.spriteSourceSize.x, f.spriteSourceSize.y ) );
    }

    // duplicate/drop animation frames to match the desired animation speed
    var durations = sheetDesc.frames.map( function (f) return f.duration );
    var interpolatedDurations = interpolateFrames( durations
                                                 , Const.ANIM_SPEED );
    var interpolatedFrames    = new Array<h2d.Tile>();
    for ( i in interpolatedDurations ) {
      interpolatedFrames.push( frames[ i ] );
    }

    if ( parent == null ) {
      parent = new h2d.Object( );
    }

    var anim = new h2d.Anim( interpolatedFrames, Const.ANIM_SPEED, parent );
    anim.scaleX = sheetDesc.meta.scale;
    anim.scaleY = sheetDesc.meta.scale;

    return parent;
  }

  // Loads several state animations from a single Aseprite-exported sprite
  // sheet.  A state parser must be supplied to convert from strings in a file
  // to Int (preferably: an absract enum with Int as an underlying type).
  // Returned map is then stored inside an Animation to supply available state
  // animations.
  public static function loadStateAnimation( filepath    : String
                                           , stateParser : String -> Int )
      : Map<Int, Animation.StateAnim> {
    LOGGER.info( "Loading sprite sheet " + filepath );
    var jsonFile   = filepath + ".json";
    var sheetDesc  = loadSheetDesc( jsonFile );
    var sheetDir   = haxe.io.Path.directory( jsonFile );
    var imageFile  = haxe.io.Path.join( [ sheetDir, sheetDesc.meta.image ] );
    var sheet      = hxd.Res.loader.load( imageFile ).toTile();
    var animSize   = sheetDesc.meta.size;

    var animation = new Map<Int, Animation.StateAnim>( );

    // See Note [Unsupported Aseprite features]
    for ( animTag in sheetDesc.meta.frameTags ) {
      LOGGER.debug( "Loading animation tag: " + animTag.name );

      var frames     = new Array<h2d.Tile>( );
      var framesDesc = new Array<Animation.FrameDesc>( );
      var animFrames = sheetDesc.frames.slice( animTag.from, animTag.to + 1 );

      // reconstruct animation frames from a sprite sheet
      for ( f in animFrames ) {
        frames.push( sheet.sub( f.frame.x, f.frame.y, f.frame.w, f.frame.h,
                                f.spriteSourceSize.x, f.spriteSourceSize.y ) );
        framesDesc.push( { x            : f.spriteSourceSize.x
                         , y            : f.spriteSourceSize.y
                         , width        : f.spriteSourceSize.w
                         , height       : f.spriteSourceSize.h
                         , sourceWidth  : f.sourceSize.w
                         , sourceHeight : f.sourceSize.h } );
      }

      // duplicate/drop animation frames to match the desired animation speed
      var durations = animFrames.map( function (f) return f.duration );
      var interpolatedDurations = interpolateFrames( durations
                                                   , Const.ANIM_SPEED );

      var stateAnim        = new Animation.StateAnim( );
      stateAnim.frames     = new Array<h2d.Tile>();
      stateAnim.framesDesc = new Array<Animation.FrameDesc>( );
      for ( i in interpolatedDurations ) {
        stateAnim.frames.push( frames[ i ] );
        stateAnim.framesDesc.push( framesDesc[ i ] );
      }

      animation.set( stateParser( animTag.name ), stateAnim );
    }

    return animation;
  }

  // See Note [Frame interpolation]
  static function interpolateFrames( durations : Array<Int>
                                   , speed     : Int        ) : Array<Int> {
    var interpolatedFrames = new Array<Int>();
    var frameDuration      = 1000.0 / speed;            // milliseconds
    var currentFrame       = 0;
    var frameCount         = durations.length;
    var elapsedTime        = 0.0;                       // milliseconds
    var frameTime          = durations[ currentFrame ]; // milliseconds

    while ( currentFrame < frameCount ) {
      elapsedTime += frameDuration;
      interpolatedFrames.push( currentFrame );
      while ( elapsedTime >= frameTime && currentFrame < frameCount ) {
        frameTime += durations[ currentFrame ];
        currentFrame++;
      }
    }

    return interpolatedFrames;
  }

  static function loadSheetDesc( jsonFilename : String ) : SheetDesc {
    var jsonString            = hxd.Res.loader.load( jsonFilename ).toText();
    var sheetDesc : SheetDesc = haxe.Json.parse( jsonString );

    // See Note [Optional Aseprite JSON fields]
    // See Note [Aseprite JSON data conversions]
    if ( hasFrameTags( sheetDesc ) ) {
      parseAnimDirection( sheetDesc.meta.frameTags, jsonFilename );
    } else {
      initFrameTags( sheetDesc );
    }

    if ( hasLayers( sheetDesc ) ) {
      parseBlendMode( sheetDesc.meta.layers, jsonFilename );
    } else {
      initLayers( sheetDesc );
    }

    if ( !hasSlices( sheetDesc ) ) {
      initSlices( sheetDesc );
    }

    parseScale( sheetDesc.meta );
    validateSheetDesc( sheetDesc, jsonFilename );

    return sheetDesc;
  }

  static function parseAnimDirection( frameTags    : Array<TagDesc>
                                    , jsonFilename : String ) : Void {
    for ( tagDesc in frameTags ) {
      var direction = Reflect.field( tagDesc, "direction" );
      tagDesc.direction =
        switch ( direction ) {
          case "forward"  : FORWARD;
          case "reverse"  : REVERSE;
          case "pingpong" : PINGPONG;
          default : throw new AsepriteParseException
                      ( "Unrecognised direction \"" + direction + "\" in file "
                      + jsonFilename );
      }
    }
  }

  static function parseBlendMode( layers       : Array<LayerDesc>
                                , jsonFilename : String ) : Void {
    for ( layerDesc in layers ) {
      var blendMode = Reflect.field( layerDesc, "blendMode" );
      layerDesc.blendMode =
        switch ( blendMode ) {
          case "normal"      : NORMAL      ;
          case "darken"      : DARKEN      ;
          case "multiply"    : MULTIPLY    ;
          case "color_burn"  : COLOR_BURN  ;
          case "lighten"     : LIGHTEN     ;
          case "screen"      : SCREEN      ;
          case "color_dodge" : COLOR_DODGE ;
          case "addition"    : ADDITION    ;
          case "overlay"     : OVERLAY     ;
          case "soft_light"  : SOFT_LIGHT  ;
          case "hard_light"  : HARD_LIGHT  ;
          case "difference"  : DIFFERENCE  ;
          case "exclusion"   : EXCLUSION   ;
          case "subtract"    : SUBTRACT    ;
          case "divide"      : DIVIDE      ;
          case "hue"         : HUE         ;
          case "saturation"  : SATURATION  ;
          case "color"       : COLOR       ;
          case "luminosity"  : LUMINOSITY  ;
          default : throw new AsepriteParseException
                      ( "Unrecognised blendMode \"" + blendMode + "\" in file "
                      + jsonFilename );
        }
    }
  }

  static function parseScale( meta : MetaDesc ) : Void {
    meta.scale = Std.parseFloat( Reflect.field( meta, "scale" ) );
  }

  static function hasFrameTags( sheetDesc : SheetDesc ) : Bool {
    return sheetDesc.meta.frameTags != null;
  }

  static function hasLayers( sheetDesc : SheetDesc ) : Bool {
    return sheetDesc.meta.layers != null;
  }

  static function hasSlices( sheetDesc : SheetDesc ) : Bool {
    return sheetDesc.meta.slices != null;
  }

  static function initFrameTags( sheetDesc : SheetDesc ) : Void {
    assert ( !hasFrameTags( sheetDesc ) );
    sheetDesc.meta.frameTags = new Array<TagDesc>();
  }

  static function initLayers( sheetDesc : SheetDesc ) : Void {
    assert ( !hasLayers( sheetDesc ) );
    sheetDesc.meta.layers = new Array<LayerDesc>();
  }

  static function initSlices( sheetDesc : SheetDesc ) : Void {
    assert ( !hasSlices( sheetDesc ) );
    sheetDesc.meta.slices = new Array<SliceDesc>();
  }

  // Validates basic correctness of data in a sprite sheet
  static function validateSheetDesc( sheetDesc    : SheetDesc
                                   , jsonFilename : String ) : Void {

    // See Note [Frame storage formats]
    var maybeFrames = Reflect.field( sheetDesc, "frames" );
#if ( hl )
    if ( !Reflect.hasField( maybeFrames, "array" ) ) {
      throw new AsepriteParseException( "Frame data stored in Hash format in "
        + "file \"" + jsonFilename + "\". Export to Array format instead." );
    }
#elseif ( js )
    for ( key in Reflect.fields( maybeFrames ) ) {
      var frame = Reflect.field( maybeFrames, key );
      if ( frame.filename == null ) { // if the filename is missing this is Hash
        throw new AsepriteParseException( "Frame data stored in Hash format in "
          + "file \"" + jsonFilename + "\".  Export to Array format instead" );
      }
    }
#end

    var frames : Array<FrameDesc> = sheetDesc.frames;

    if ( frames.length == 0 ) {
      throw new AsepriteParseException( "No frames in file " + jsonFilename );
    }

    var expectedSourceSize = frames[0].sourceSize;

    for ( frame in frames ) {
      var spriteSourceSize = frame.spriteSourceSize;

      if ( frame.sourceSize.h != expectedSourceSize.h ||
           frame.sourceSize.w != expectedSourceSize.w ) {
        throw new AsepriteParseException( "Inconsistent size of frame \""
          + frame.filename + "\" in file " + jsonFilename );
      }

      if ( spriteSourceSize.x + spriteSourceSize.w > expectedSourceSize.w ) {
        throw new AsepriteParseException( "To large width for frame \""
          + frame.filename + "\" in file " + jsonFilename );
      }

      if ( spriteSourceSize.y + spriteSourceSize.h > expectedSourceSize.h ) {
        throw new AsepriteParseException( "To large height for frame \""
          + frame.filename + "\" in file " + jsonFilename );
      }

      if ( frame.frame.w != frame.spriteSourceSize.w ||
           frame.frame.h != frame.spriteSourceSize.h ) {
        throw new AsepriteParseException( "Inconsistent sizes for frame \""
          + frame.filename + "\" in file " + jsonFilename );
      }
    }
  }
}
