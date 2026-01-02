///|
/// JWW data types for rendering
/// These types mirror the structure parsed from JWW files

///|
/// Base entity properties
pub struct EntityBase {
  layer : Int
  layer_group : Int
  pen_color : Int
  pen_width : Int
  pen_style : Int
  line_type : Int
}

///|
/// Line entity
pub struct JwwLine {
  base : EntityBase
  x1 : Double
  y1 : Double
  x2 : Double
  y2 : Double
}

///|
/// Arc/Circle entity
pub struct JwwArc {
  base : EntityBase
  cx : Double
  cy : Double
  radius : Double
  start_angle : Double // in radians
  end_angle : Double // in radians
  is_full : Bool // true for full circle
}

///|
/// Point entity
pub struct JwwPoint {
  base : EntityBase
  x : Double
  y : Double
  point_type : Int // JWW point marker type
}

///|
/// Text entity
pub struct JwwText {
  base : EntityBase
  x : Double
  y : Double
  text : String
  size : Double
  angle : Double // in degrees
  font_name : String
}

///|
/// Solid fill (quadrilateral)
pub struct JwwSolid {
  base : EntityBase
  x1 : Double
  y1 : Double
  x2 : Double
  y2 : Double
  x3 : Double
  y3 : Double
  x4 : Double
  y4 : Double
  color : Int
}

///|
/// Block reference
pub struct JwwBlock {
  base : EntityBase
  x : Double
  y : Double
  scale_x : Double
  scale_y : Double
  angle : Double
  block_name : String
}

///|
/// Polyline
pub struct JwwPolyline {
  base : EntityBase
  points : Array[(Double, Double)]
  is_closed : Bool
}

///|
/// Image entity
pub struct JwwImage {
  base : EntityBase
  image_path : String
  x : Double
  y : Double
  width : Double
  height : Double
  rotation : Double // in degrees
}

///|
/// Image format (detected from magic bytes)
pub enum JwwImageFormat {
  Unknown
  Jpeg
  Png
  Bmp
  Gif
}

///|
/// Embedded image data (Ver.7.00+)
pub struct JwwEmbeddedImage {
  index : UInt
  file_size : UInt
  data : Bytes
  format : JwwImageFormat
}

///|
/// Print settings
pub struct JwwPrintSettings {
  origin_x : Double
  origin_y : Double
  scale : Double
  rotation_setting : UInt
}

///|
/// Entity enum
pub enum JwwEntity {
  LineEnt(JwwLine)
  ArcEnt(JwwArc)
  PointEnt(JwwPoint)
  TextEnt(JwwText)
  SolidEnt(JwwSolid)
  BlockEnt(JwwBlock)
  PolylineEnt(JwwPolyline)
  ImageEnt(JwwImage)
}

///|
/// JWW Document
pub struct JwwDocument {
  version : String
  memo : String
  version_number : Int
  drawing_width : Double
  drawing_height : Double
  entities : Array[JwwEntity]
  layer_count : Int
  layer_group_count : Int
  print_settings : JwwPrintSettings
  embedded_images : Array[JwwEmbeddedImage]
}

///|
/// Create a default entity base
pub fn EntityBase::new() -> EntityBase {
  {
    layer: 0,
    layer_group: 0,
    pen_color: 1,
    pen_width: 1,
    pen_style: 0,
    line_type: 0,
  }
}

///|
/// Create default document
pub fn JwwDocument::new() -> JwwDocument {
  {
    version: "7.00",
    memo: "",
    version_number: 700,
    drawing_width: 0.0,
    drawing_height: 0.0,
    entities: [],
    layer_count: 16,
    layer_group_count: 16,
    print_settings: {
      origin_x: 0.0,
      origin_y: 0.0,
      scale: 1.0,
      rotation_setting: 0,
    },
    embedded_images: [],
  }
}
