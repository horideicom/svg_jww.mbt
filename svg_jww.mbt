///|
/// SVG Builder module for creating SVG elements
/// Provides types and functions to build SVG elements programmatically

///|
/// SVG element data for element nodes
pub struct SvgElementData {
  tag : String
  attributes : Array[(String, String)]
  children : Array[SvgElement]
  self_closing : Bool
}

///|
/// SVG element types
pub enum SvgElement {
  Text(String)
  ElementNode(SvgElementData)
}

///|
/// Create a new SVG element with tag and attributes
pub fn svg_element(
  tag : String,
  attributes : Array[(String, String)],
  children : Array[SvgElement],
) -> SvgElement {
  SvgElement::ElementNode({ tag, attributes, children, self_closing: false })
}

///|
/// Create a self-closing SVG element (like <line>, <circle>, etc.)
pub fn svg_self_closing(
  tag : String,
  attributes : Array[(String, String)],
) -> SvgElement {
  SvgElement::ElementNode({ tag, attributes, children: [], self_closing: true })
}

///|
/// Create an SVG root element
pub fn svg(
  attributes : Array[(String, String)],
  children : Array[SvgElement],
) -> SvgElement {
  svg_element("svg", attributes, children)
}

///|
/// Create a group element
pub fn g(
  attributes : Array[(String, String)],
  children : Array[SvgElement],
) -> SvgElement {
  svg_element("g", attributes, children)
}

///|
/// Create a line element
pub fn svg_line(attributes : Array[(String, String)]) -> SvgElement {
  svg_self_closing("line", attributes)
}

///|
/// Create a circle element
pub fn circle(attributes : Array[(String, String)]) -> SvgElement {
  svg_self_closing("circle", attributes)
}

///|
/// Create an ellipse element
pub fn ellipse(attributes : Array[(String, String)]) -> SvgElement {
  svg_self_closing("ellipse", attributes)
}

///|
/// Create a path element
pub fn path(attributes : Array[(String, String)]) -> SvgElement {
  svg_self_closing("path", attributes)
}

///|
/// Create a polygon element
pub fn polygon(attributes : Array[(String, String)]) -> SvgElement {
  svg_self_closing("polygon", attributes)
}

///|
/// Create a polyline element
pub fn polyline(attributes : Array[(String, String)]) -> SvgElement {
  svg_self_closing("polyline", attributes)
}

///|
/// Create a text element
pub fn text_elem(
  attributes : Array[(String, String)],
  content : String,
) -> SvgElement {
  SvgElement::ElementNode({
    tag: "text",
    attributes,
    children: [SvgElement::Text(content)],
    self_closing: false,
  })
}

///|
/// Create a rect element
pub fn rect(attributes : Array[(String, String)]) -> SvgElement {
  svg_self_closing("rect", attributes)
}

///|
/// Create a use element (for referencing)
pub fn use_ref(attributes : Array[(String, String)]) -> SvgElement {
  svg_self_closing("use", attributes)
}

///|
/// Create an image element
pub fn image_elem(attributes : Array[(String, String)]) -> SvgElement {
  svg_self_closing("image", attributes)
}

///|
/// Convert SVG element to string
pub fn to_string(elem : SvgElement) -> String {
  match elem {
    SvgElement::Text(s) => escape_xml(s)
    SvgElement::ElementNode(data) => {
      let attrs = if data.attributes.length() > 0 {
        " " + join_attributes(data.attributes)
      } else {
        ""
      }
      if data.self_closing {
        "<" + data.tag + attrs + " />"
      } else {
        let children_str = join_children(data.children)
        "<" + data.tag + attrs + ">" + children_str + "</" + data.tag + ">"
      }
    }
  }
}

///|
/// Join attributes into a string
fn join_attributes(attributes : Array[(String, String)]) -> String {
  attributes
  .map(fn(pair) {
    let (key, val) = pair
    key + "=\"" + escape_xml_attr(val) + "\""
  })
  .join(" ")
}

///|
/// Join children elements into a string
fn join_children(children : Array[SvgElement]) -> String {
  children.map(to_string).join("")
}

///|
/// Escape special XML characters in text content
fn escape_xml(s : String) -> String {
  s
  .replace(old="&", new="&amp;")
  .replace(old="<", new="&lt;")
  .replace(old=">", new="&gt;")
}

///|
/// Escape special XML characters in attribute values
fn escape_xml_attr(s : String) -> String {
  escape_xml(s).replace(old="\"", new="&quot;")
}

///|
/// Bounding box for calculating document extents
pub struct BoundingBox {
  min_x : Double
  min_y : Double
  max_x : Double
  max_y : Double
}

///|
pub fn BoundingBox::new() -> BoundingBox {
  { min_x: 0.0, min_y: 0.0, max_x: 0.0, max_y: 0.0 }
}

///|
pub fn BoundingBox::expand(
  self : BoundingBox,
  x : Double,
  y : Double,
) -> BoundingBox {
  {
    min_x: if x < self.min_x {
      x
    } else {
      self.min_x
    },
    min_y: if y < self.min_y {
      y
    } else {
      self.min_y
    },
    max_x: if x > self.max_x {
      x
    } else {
      self.max_x
    },
    max_y: if y > self.max_y {
      y
    } else {
      self.max_y
    },
  }
}

///|
pub fn BoundingBox::width(self : BoundingBox) -> Double {
  self.max_x - self.min_x
}

///|
pub fn BoundingBox::height(self : BoundingBox) -> Double {
  self.max_y - self.min_y
}

///|
pub fn BoundingBox::is_valid(self : BoundingBox) -> Bool {
  self.min_x < self.max_x && self.min_y < self.max_y
}

///|
/// Color utilities for converting JWW color numbers to CSS colors
pub fn to_svg_color(pen_color : Int) -> String {
  // JWW color numbers: 0=white, 1=black, 2=red, 3=green, 4=blue, 5=yellow, 6=cyan, 7=magenta, 8=gray
  match pen_color {
    0 => "#ffffff"
    1 => "#000000"
    2 => "#ff0000"
    3 => "#00ff00"
    4 => "#0000ff"
    5 => "#ffff00"
    6 => "#00ffff"
    7 => "#ff00ff"
    8 => "#808080"
    9 => "#c0c0c0"
    _ => "#000000"
  }
}

///|
/// Int to hex string helper (2 digits)
fn int_to_hex2(n : Int) -> String {
  let hex_chars = [
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f",
  ]
  let h = n / 16
  let l = n % 16
  let hs = if h >= 0 && h < 16 { hex_chars[h] } else { "0" }
  let ls = if l >= 0 && l < 16 { hex_chars[l] } else { "0" }
  hs + ls
}

///|
pub fn to_rgb_color(r : Int, g : Int, b : Int) -> String {
  "#" + int_to_hex2(r) + int_to_hex2(g) + int_to_hex2(b)
}

///|
pub fn to_rgba_color(r : Int, g : Int, b : Int, a : Double) -> String {
  let alpha = (a * 255.0).to_int()
  "#" + int_to_hex2(r) + int_to_hex2(g) + int_to_hex2(b) + int_to_hex2(alpha)
}

///|
/// Stroke width utilities
pub fn to_svg_stroke_width(pen_width : Int) -> String {
  if pen_width <= 0 {
    "1"
  } else {
    pen_width.to_string()
  }
}

///|
/// Coordinate transformation utilities
/// JWW uses Y-up coordinate system, SVG uses Y-down
pub struct Transform {
  scale : Double
  offset_x : Double
  offset_y : Double
  flip_y : Bool // Whether to flip Y axis
}

///|
pub fn Transform::new() -> Transform {
  { scale: 1.0, offset_x: 0.0, offset_y: 0.0, flip_y: true }
}

///|
pub fn Transform::with_scale(scale : Double) -> Transform {
  { scale, offset_x: 0.0, offset_y: 0.0, flip_y: true }
}

///|
pub fn Transform::transform_x(self : Transform, x : Double) -> Double {
  x * self.scale + self.offset_x
}

///|
pub fn Transform::transform_y(
  self : Transform,
  y : Double,
  height : Double,
) -> Double {
  // Flip Y axis: SVG origin is top-left, JWW origin is bottom-left
  let scaled = y * self.scale
  if self.flip_y {
    height - scaled + self.offset_y
  } else {
    scaled + self.offset_y
  }
}

///|
/// Rendering options
pub struct RenderOptions {
  scale : Double
  offset_x : Double
  offset_y : Double
  width : Double
  height : Double
  background_color : String
  stroke_width_scale : Double
  show_print_area : Bool
  bounds_max_y : Double // JWW座標系のmax_y（Y座標変換に使用）
  padding : Double // パディング値
}

///|
pub fn RenderOptions::new() -> RenderOptions {
  {
    scale: 1.0,
    offset_x: 0.0,
    offset_y: 0.0,
    width: 800.0,
    height: 600.0,
    background_color: "#ffffff",
    stroke_width_scale: 1.0,
    show_print_area: false,
    bounds_max_y: 600.0,
    padding: 0.0,
  }
}

///|
pub fn RenderOptions::with_size(
  width : Double,
  height : Double,
) -> RenderOptions {
  {
    scale: 1.0,
    offset_x: 0.0,
    offset_y: 0.0,
    width,
    height,
    background_color: "#ffffff",
    stroke_width_scale: 1.0,
    show_print_area: false,
    bounds_max_y: height,
    padding: 0.0,
  }
}

///|
pub fn RenderOptions::with_bounds(
  width : Double,
  height : Double,
  bounds_max_y : Double,
  padding : Double,
) -> RenderOptions {
  {
    scale: 1.0,
    offset_x: 0.0,
    offset_y: 0.0,
    width,
    height,
    background_color: "#ffffff",
    stroke_width_scale: 1.0,
    show_print_area: false,
    bounds_max_y,
    padding,
  }
}

///|
pub fn RenderOptions::with_scale(scale : Double) -> RenderOptions {
  {
    scale,
    offset_x: 0.0,
    offset_y: 0.0,
    width: 800.0,
    height: 600.0,
    background_color: "#ffffff",
    stroke_width_scale: 1.0,
    show_print_area: false,
    bounds_max_y: 600.0,
    padding: 0.0,
  }
}

///|
pub fn RenderOptions::transform_x(self : RenderOptions, x : Double) -> Double {
  x * self.scale + self.offset_x
}

///|
pub fn RenderOptions::transform_y(self : RenderOptions, y : Double) -> Double {
  // Flip Y: SVG is Y-down, JWW is Y-up
  // bounds_max_yを基準にY座標を反転し、paddingを加える
  (self.bounds_max_y - y) * self.scale + self.offset_y + self.padding
}

///|
pub fn RenderOptions::transform_distance(
  self : RenderOptions,
  d : Double,
) -> Double {
  d * self.scale
}

///|
/// Common SVG attribute builders
pub fn attr(key : String, value : String) -> (String, String) {
  (key, value)
}

///|
pub fn attr_double(key : String, value : Double) -> (String, String) {
  (key, value.to_string())
}

///|
pub fn attr_int(key : String, value : Int) -> (String, String) {
  (key, value.to_string())
}

///|
pub fn style_attr(style : String) -> (String, String) {
  ("style", style)
}

///|
pub fn class_attr(class_name : String) -> (String, String) {
  ("class", class_name)
}

///|
pub fn id_attr(id : String) -> (String, String) {
  ("id", id)
}

///|
pub fn fill_attr(color : String) -> (String, String) {
  ("fill", color)
}

///|
pub fn stroke_attr(color : String) -> (String, String) {
  ("stroke", color)
}

///|
pub fn stroke_width_attr(width : String) -> (String, String) {
  ("stroke-width", width)
}

///|
pub fn stroke_width_double(width : Double) -> (String, String) {
  ("stroke-width", width.to_string())
}

///|
pub fn fill_none() -> (String, String) {
  ("fill", "none")
}

///|
pub fn stroke_none() -> (String, String) {
  ("stroke", "none")
}

///|
/// Line style utilities for JWW line types
pub enum LineType {
  Solid
  Dashed
  Dotted
  DashDot
  Custom(Array[Double]) // Dash pattern in pixels
} derive(Show)

///|
/// Convert JWW pen_style value to LineType
/// pen_style: 1=実線, 2=点線1, 3=点線2, 4=一点鎖線1, 5=一点鎖線2,
///            6=二点鎖線1, 7=二点鎖線2, 8=補助線
/// 0や未知値は実線扱い
pub fn pen_style_to_line_type(pen_style : Int) -> LineType {
  match pen_style {
    0 => LineType::Solid
    1 => LineType::Solid
    2 => LineType::Custom([1.0, 2.0]) // 点線1
    3 => LineType::Custom([2.0, 2.0]) // 点線2
    4 => LineType::Custom([8.0, 3.0, 1.0, 3.0]) // 一点鎖線1
    5 => LineType::Custom([12.0, 3.0, 2.0, 3.0]) // 一点鎖線2
    6 => LineType::Custom([8.0, 3.0, 1.0, 3.0, 1.0, 3.0]) // 二点鎖線1
    7 => LineType::Custom([12.0, 3.0, 2.0, 3.0, 2.0, 3.0]) // 二点鎖線2
    8 => LineType::Custom([1.0, 4.0]) // 補助線
    _ => LineType::Solid
  }
}

///|
/// Math utilities for trigonometric functions
pub fn cos_d(x : Double) -> Double {
  @math.cos(x)
}

///|
pub fn sin_d(x : Double) -> Double {
  @math.sin(x)
}

///|
pub fn line_type_to_dasharray(
  line_type : LineType,
  scale : Double,
) -> (String, String)? {
  match line_type {
    LineType::Solid => None
    LineType::Dashed =>
      Some(
        (
          "stroke-dasharray",
          (5.0 * scale).to_string() + "," + (5.0 * scale).to_string(),
        ),
      )
    LineType::Dotted =>
      Some(
        (
          "stroke-dasharray",
          (1.0 * scale).to_string() + "," + (2.0 * scale).to_string(),
        ),
      )
    LineType::DashDot =>
      Some(
        (
          "stroke-dasharray",
          (8.0 * scale).to_string() +
          "," +
          (3.0 * scale).to_string() +
          "," +
          (1.0 * scale).to_string() +
          "," +
          (3.0 * scale).to_string(),
        ),
      )
    LineType::Custom(pattern) => {
      let scaled = pattern.map(fn(d) { (d * scale).to_string() }).join(",")
      Some(("stroke-dasharray", scaled))
    }
  }
}

///|
/// Get MIME type for image format
pub fn image_format_to_mime(format : JwwImageFormat) -> String {
  match format {
    JwwImageFormat::Jpeg => "image/jpeg"
    JwwImageFormat::Png => "image/png"
    JwwImageFormat::Bmp => "image/bmp"
    JwwImageFormat::Gif => "image/gif"
    JwwImageFormat::Unknown => "image/octet-stream"
  }
}

///|
/// Convert bytes to base64 string (placeholder - requires base64 library)
pub fn bytes_to_base64(data : Bytes) -> String {
  // TODO: Implement proper base64 encoding
  // For now, return empty string as placeholder
  ""
}

///|
/// Create data URL from embedded image data
pub fn embedded_image_to_data_url(embedded_image : JwwEmbeddedImage) -> String {
  let mime = image_format_to_mime(embedded_image.format)
  let base64 = bytes_to_base64(embedded_image.data)
  "data:" + mime + ";base64," + base64
}
