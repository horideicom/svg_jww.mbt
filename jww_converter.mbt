///|
/// JWW to SVG converter
/// Converts JWW binary data to SVG with metadata

// Type aliases for jww_parser types
type ParserDocument = @jww_parser_core.Document

///|
type ParserEntity = @jww_parser_core.Entity

///|
type ParserLine = @jww_parser_core.Line

///|
type ParserArc = @jww_parser_core.Arc

///|
type ParserPoint = @jww_parser_core.Point

///|
type ParserText = @jww_parser_core.Text

///|
type ParserSolid = @jww_parser_core.Solid

///|
type ParserBlock = @jww_parser_core.Block

///|
type ParserImage = @jww_parser_core.Image

///|
/// Print settings
pub struct PrintSettings {
  origin_x : Double
  origin_y : Double
  scale : Double
  rotation_setting : Int
}

///|
/// JWW parse result for JavaScript
pub struct ParsedDocument {
  svg : String
  bounds : Bounds
  layers : Array[LayerInfo]
  entity_counts : EntityCounts
  version : String
  paper_size : Int
  memo : String
  print_settings : PrintSettings
}

///|
/// Document bounds
pub struct Bounds {
  min_x : Double
  min_y : Double
  max_x : Double
  max_y : Double
}

///|
/// Layer information
pub struct LayerInfo {
  id : Int
  name : String
  entity_count : Int
  visible : Bool
}

///|
/// Entity counts by type
pub struct EntityCounts {
  lines : Int
  arcs : Int
  texts : Int
  points : Int
  solids : Int
  blocks : Int
  images : Int
}

///|
/// Debug overlay options
pub struct DebugOptions {
  show_bounds : Bool
  show_axes : Bool
  show_print_area : Bool
}

///|
pub fn DebugOptions::new(
  show_bounds : Bool,
  show_axes : Bool,
  show_print_area : Bool,
) -> DebugOptions {
  { show_bounds, show_axes, show_print_area }
}

///|
fn build_parsed_document(
  doc : ParserDocument,
  svg : String,
  bounds : Bounds,
  layers : Array[LayerInfo],
  counts : EntityCounts,
) -> ParsedDocument {
  // Extract print settings from parser document
  let ps = doc.print_settings
  let print_settings : PrintSettings = {
    origin_x: ps.origin_x,
    origin_y: ps.origin_y,
    scale: ps.scale,
    rotation_setting: ps.rotation_setting.reinterpret_as_int(),
  }
  {
    svg,
    bounds,
    layers,
    entity_counts: counts,
    version: doc.version.to_string(),
    paper_size: doc.paper_size.reinterpret_as_int(),
    memo: doc.memo,
    print_settings,
  }
}

///|
/// Parse JWW binary data and return document with SVG and metadata
pub fn jww_parse(data : Bytes) -> ParsedDocument {
  let doc = @jww_parser_core.parse(data~)
  let (svg, bounds, layers, counts) = render_jww_document(doc)
  build_parsed_document(doc, svg, bounds, layers, counts)
}

///|
/// Parse JWW binary data and return document with SVG and metadata (debug overlays)
pub fn jww_parse_debug(data : Bytes, debug : DebugOptions) -> ParsedDocument {
  let doc = @jww_parser_core.parse(data~)
  let (svg, bounds, layers, counts) = render_jww_document_with_debug(doc, debug)
  build_parsed_document(doc, svg, bounds, layers, counts)
}

///|
/// Parse JWW binary data and return SVG string only
pub fn jww_to_svg(data : Bytes) -> String {
  jww_parse(data).svg
}

///|
/// Render JWW document to SVG with metadata
fn render_jww_document(
  doc : ParserDocument,
) -> (String, Bounds, Array[LayerInfo], EntityCounts) {
  let debug : DebugOptions = {
    show_bounds: false,
    show_axes: false,
    show_print_area: false,
  }
  render_jww_document_with_debug(doc, debug)
}

///|
/// Render JWW document to SVG with metadata and debug overlays
fn render_jww_document_with_debug(
  doc : ParserDocument,
  debug : DebugOptions,
) -> (String, Bounds, Array[LayerInfo], EntityCounts) {
  // Count entities
  let mut counts : EntityCounts = {
    lines: 0,
    arcs: 0,
    texts: 0,
    points: 0,
    solids: 0,
    blocks: 0,
    images: 0,
  }

  // Count entities by type
  for entity in doc.entities {
    match entity {
      ParserEntity::Line(_) =>
        counts = {
          lines: counts.lines + 1,
          arcs: counts.arcs,
          texts: counts.texts,
          points: counts.points,
          solids: counts.solids,
          blocks: counts.blocks,
          images: counts.images,
        }
      ParserEntity::Arc(_) =>
        counts = {
          lines: counts.lines,
          arcs: counts.arcs + 1,
          texts: counts.texts,
          points: counts.points,
          solids: counts.solids,
          blocks: counts.blocks,
          images: counts.images,
        }
      ParserEntity::Text(_) =>
        counts = {
          lines: counts.lines,
          arcs: counts.arcs,
          texts: counts.texts + 1,
          points: counts.points,
          solids: counts.solids,
          blocks: counts.blocks,
          images: counts.images,
        }
      ParserEntity::Point(_) =>
        counts = {
          lines: counts.lines,
          arcs: counts.arcs,
          texts: counts.texts,
          points: counts.points + 1,
          solids: counts.solids,
          blocks: counts.blocks,
          images: counts.images,
        }
      ParserEntity::Solid(_) =>
        counts = {
          lines: counts.lines,
          arcs: counts.arcs,
          texts: counts.texts,
          points: counts.points,
          solids: counts.solids + 1,
          blocks: counts.blocks,
          images: counts.images,
        }
      ParserEntity::Block(_) =>
        counts = {
          lines: counts.lines,
          arcs: counts.arcs,
          texts: counts.texts,
          points: counts.points,
          solids: counts.solids,
          blocks: counts.blocks + 1,
          images: counts.images,
        }
      ParserEntity::Image(_) =>
        counts = {
          lines: counts.lines,
          arcs: counts.arcs,
          texts: counts.texts,
          points: counts.points,
          solids: counts.solids,
          blocks: counts.blocks,
          images: counts.images + 1,
        }
      ParserEntity::ArcSolid(_) =>
        counts = {
          lines: counts.lines,
          arcs: counts.arcs,
          texts: counts.texts,
          points: counts.points,
          solids: counts.solids + 1,
          blocks: counts.blocks,
          images: counts.images,
        }
    }
  }

  // Calculate bounds
  let bounds = calculate_bounds(doc)

  // Build layer info
  let layers = build_layer_info(doc)

  // Create render options
  let padding = 20.0
  let width = bounds.max_x - bounds.min_x + padding * 2.0
  let height = bounds.max_y - bounds.min_y + padding * 2.0
  let opts = RenderOptions::with_bounds(width, height, bounds.max_y, padding)

  // Render SVG
  let svg_elem = render_svg_conv_debug(doc, opts, bounds, padding, debug)
  (to_string(svg_elem), bounds, layers, counts)
}

///|
/// Check if coordinate is valid (not NaN, not Inf, and within reasonable range)
/// CAD drawings typically use mm, so 10^9 mm = 1000 km is a reasonable max
fn is_valid_coord(v : Double) -> Bool {
  let max_coord = 1.0e9
  v == v && v.abs() < max_coord // v == v is false for NaN
}

///|
/// Update bounds with a valid coordinate
fn update_bounds(
  min_x : Double,
  min_y : Double,
  max_x : Double,
  max_y : Double,
  x : Double,
  y : Double,
  initialized : Bool,
) -> (Double, Double, Double, Double, Bool) {
  if is_valid_coord(x) && is_valid_coord(y) {
    if initialized {
      let new_min_x = if x < min_x { x } else { min_x }
      let new_min_y = if y < min_y { y } else { min_y }
      let new_max_x = if x > max_x { x } else { max_x }
      let new_max_y = if y > max_y { y } else { max_y }
      (new_min_x, new_min_y, new_max_x, new_max_y, true)
    } else {
      // First valid coordinate initializes the bounds
      (x, y, x, y, true)
    }
  } else {
    (min_x, min_y, max_x, max_y, initialized)
  }
}

///|
/// Calculate document bounds from entities
fn calculate_bounds(doc : ParserDocument) -> Bounds {
  let mut min_x = 0.0
  let mut min_y = 0.0
  let mut max_x = 400.0
  let mut max_y = 300.0
  let mut initialized = false
  for entity in doc.entities {
    match entity {
      ParserEntity::Line(l) => {
        let (nx, ny, xx, xy, init) = update_bounds(
          min_x, min_y, max_x, max_y, l.start_x, l.start_y, initialized,
        )
        min_x = nx
        min_y = ny
        max_x = xx
        max_y = xy
        initialized = init
        let (nx2, ny2, xx2, xy2, init2) = update_bounds(
          min_x, min_y, max_x, max_y, l.end_x, l.end_y, initialized,
        )
        min_x = nx2
        min_y = ny2
        max_x = xx2
        max_y = xy2
        initialized = init2
      }
      ParserEntity::Arc(a) => {
        if is_valid_coord(a.center_x) &&
          is_valid_coord(a.center_y) &&
          is_valid_coord(a.radius) &&
          is_valid_coord(a.flatness) &&
          is_valid_coord(a.tilt_angle) &&
          a.radius > 0.0 {
          let (rx, ry) = arc_radii(a.radius, a.flatness)
          let (x_ext, y_ext) = ellipse_extents(rx, ry, a.tilt_angle)
          let (nx, ny, xx, xy, init) = update_bounds(
            min_x,
            min_y,
            max_x,
            max_y,
            a.center_x - x_ext,
            a.center_y - y_ext,
            initialized,
          )
          min_x = nx
          min_y = ny
          max_x = xx
          max_y = xy
          initialized = init
          let (nx2, ny2, xx2, xy2, init2) = update_bounds(
            min_x,
            min_y,
            max_x,
            max_y,
            a.center_x + x_ext,
            a.center_y + y_ext,
            initialized,
          )
          min_x = nx2
          min_y = ny2
          max_x = xx2
          max_y = xy2
          initialized = init2
        }
      }
      ParserEntity::Text(t) => {
        let (nx, ny, xx, xy, init) = update_bounds(
          min_x, min_y, max_x, max_y, t.start_x, t.start_y, initialized,
        )
        min_x = nx
        min_y = ny
        max_x = xx
        max_y = xy
        initialized = init
        let (nx2, ny2, xx2, xy2, init2) = update_bounds(
          min_x, min_y, max_x, max_y, t.end_x, t.end_y, initialized,
        )
        min_x = nx2
        min_y = ny2
        max_x = xx2
        max_y = xy2
        initialized = init2
      }
      ParserEntity::Point(p) => {
        let (nx, ny, xx, xy, init) = update_bounds(
          min_x, min_y, max_x, max_y, p.x, p.y, initialized,
        )
        min_x = nx
        min_y = ny
        max_x = xx
        max_y = xy
        initialized = init
      }
      ParserEntity::Solid(s) => {
        let points = [
          (s.point1_x, s.point1_y),
          (s.point2_x, s.point2_y),
          (s.point3_x, s.point3_y),
          (s.point4_x, s.point4_y),
        ]
        for pt in points {
          let (px, py) = pt
          let (nx, ny, xx, xy, init) = update_bounds(
            min_x, min_y, max_x, max_y, px, py, initialized,
          )
          min_x = nx
          min_y = ny
          max_x = xx
          max_y = xy
          initialized = init
        }
      }
      ParserEntity::Block(b) => {
        if is_valid_coord(b.ref_x) && is_valid_coord(b.ref_y) {
          let r = 10.0
          let (nx, ny, xx, xy, init) = update_bounds(
            min_x, min_y, max_x, max_y, b.ref_x - r, b.ref_y - r, initialized,
          )
          min_x = nx
          min_y = ny
          max_x = xx
          max_y = xy
          initialized = init
          let (nx2, ny2, xx2, xy2, init2) = update_bounds(
            min_x, min_y, max_x, max_y, b.ref_x + r, b.ref_y + r, initialized,
          )
          min_x = nx2
          min_y = ny2
          max_x = xx2
          max_y = xy2
          initialized = init2
        }
      }
      ParserEntity::Image(i) => {
        if is_valid_coord(i.x) &&
          is_valid_coord(i.y) &&
          is_valid_coord(i.width) &&
          is_valid_coord(i.height) {
          let (nx, ny, xx, xy, init) = update_bounds(
            min_x, min_y, max_x, max_y, i.x, i.y, initialized,
          )
          min_x = nx
          min_y = ny
          max_x = xx
          max_y = xy
          initialized = init
          let (nx2, ny2, xx2, xy2, init2) = update_bounds(
            min_x, min_y, max_x, max_y, i.x + i.width, i.y + i.height, initialized,
          )
          min_x = nx2
          min_y = ny2
          max_x = xx2
          max_y = xy2
          initialized = init2
        }
      }
      ParserEntity::ArcSolid(_) => ()
    }
  }
  if initialized {
    { min_x, min_y, max_x, max_y }
  } else {
    { min_x: 0.0, min_y: 0.0, max_x: 400.0, max_y: 300.0 }
  }
}

///|
/// Build layer info array
fn build_layer_info(doc : ParserDocument) -> Array[LayerInfo] {
  // Check if layer_groups exists and has elements
  if doc.layer_groups.length() == 0 {
    []
  } else {
    let max_groups = doc.layer_groups.length().min(16)

    // Build layer info using array concatenation
    let mut all_layers = []
    for g_idx in 0..<max_groups {
      let lg = doc.layer_groups[g_idx]
      let max_layers = lg.layers.length().min(16)
      for l_idx in 0..<max_layers {
        let l = lg.layers[l_idx]
        let layer_id = g_idx * 16 + l_idx
        let name = if l.name == "" {
          "L" + layer_id.to_string()
        } else {
          l.name
        }
        let visible = l.state != 0
        let layer_info = { id: layer_id, name, entity_count: 0, visible }
        all_layers = all_layers + [layer_info]
      }
    }
    all_layers
  }
}

///|
/// Render document to SVG element
fn render_svg_conv(
  doc : ParserDocument,
  opts : RenderOptions,
  bounds : Bounds,
  padding : Double,
) -> SvgElement {
  // Build SVG elements by layer
  let max_groups = doc.layer_groups.length().min(16)
  let mut layer_elements = []
  for g_idx in 0..<max_groups {
    let lg = doc.layer_groups[g_idx]
    let max_layers = lg.layers.length().min(16)
    for l_idx in 0..<max_layers {
      let layer_id = g_idx * 16 + l_idx

      // Filter entities for this layer
      let mut entity_elems = []
      for entity in doc.entities {
        if get_entity_layer_conv(entity) == layer_id {
          let elem = render_entity_conv(entity, opts)
          entity_elems = entity_elems + [elem]
        }
      }
      if entity_elems.length() > 0 {
        let g_elem = g(
          [
            attr("id", "layer-" + layer_id.to_string()),
            attr("class", "jww-layer"),
            attr("data-layer", layer_id.to_string()),
          ],
          entity_elems,
        )
        layer_elements = layer_elements + [g_elem]
      }
    }
  }

  // Background rect (SVG座標系: Y=0が上端)
  let bg_rect = rect([
    attr_double("x", bounds.min_x - padding),
    attr_double("y", 0.0),
    attr_double("width", opts.width),
    attr_double("height", opts.height),
    fill_attr("#ffffff"),
  ])

  // Build children array
  let mut children = [bg_rect]
  for elem in layer_elements {
    children = children + [elem]
  }

  // Build SVG (viewBoxもSVG座標系に合わせる)
  svg(
    [
      attr("xmlns", "http://www.w3.org/2000/svg"),
      attr(
        "viewBox",
        (bounds.min_x - padding).to_string() +
        " " +
        "0" + // SVG座標系の上端
        " " +
        opts.width.to_string() +
        " " +
        opts.height.to_string(),
      ),
    ],
    children,
  )
}

///|
fn render_svg_conv_debug(
  doc : ParserDocument,
  opts : RenderOptions,
  bounds : Bounds,
  padding : Double,
  debug : DebugOptions,
) -> SvgElement {
  let base_svg = render_svg_conv(doc, opts, bounds, padding)
  let overlays = build_debug_overlays(doc, opts, bounds, padding, debug)
  if overlays.length() == 0 {
    base_svg
  } else {
    let overlay_group = g(
      [class_attr("jww-debug-overlay"), style_attr("pointer-events: none;")],
      overlays,
    )
    append_svg_children(base_svg, [overlay_group])
  }
}

///|
fn append_svg_children(
  elem : SvgElement,
  extra : Array[SvgElement],
) -> SvgElement {
  match elem {
    SvgElement::ElementNode(data) => {
      let children = data.children + extra
      SvgElement::ElementNode({
        tag: data.tag,
        attributes: data.attributes,
        children,
        self_closing: data.self_closing,
      })
    }
    _ => elem
  }
}

///|
fn build_debug_overlays(
  doc : ParserDocument,
  opts : RenderOptions,
  bounds : Bounds,
  padding : Double,
  debug : DebugOptions,
) -> Array[SvgElement] {
  let mut overlays = []
  if debug.show_bounds {
    overlays = overlays + [render_debug_bounds(bounds, opts)]
  }
  if debug.show_axes {
    overlays = overlays + [render_debug_axes(bounds, opts, padding)]
  }
  if debug.show_print_area {
    overlays = overlays + [render_debug_print_area(doc, opts)]
  }
  overlays
}

///|
fn render_debug_bounds(bounds : Bounds, opts : RenderOptions) -> SvgElement {
  let width = bounds.max_x - bounds.min_x
  let height = bounds.max_y - bounds.min_y
  let x = bounds.min_x
  let y = opts.transform_y(bounds.max_y)
  let rect_elem = rect([
    attr_double("x", x),
    attr_double("y", y),
    attr_double("width", width),
    attr_double("height", height),
    stroke_attr("#f97316"),
    fill_none(),
    stroke_width_double(1.0),
    style_attr("stroke-dasharray: 6,4;"),
  ])
  let label = text_elem(
    [
      attr_double("x", x + 4.0),
      attr_double("y", y + 12.0),
      attr("font-size", "12"),
      fill_attr("#f97316"),
    ],
    "bounds",
  )
  g([class_attr("jww-debug-bounds")], [rect_elem, label])
}

///|
fn render_debug_axes(
  bounds : Bounds,
  opts : RenderOptions,
  padding : Double,
) -> SvgElement {
  let x_min = bounds.min_x - padding
  let x_max = x_min + opts.width
  let y_axis = opts.transform_y(0.0)
  let axis_style = style_attr("stroke-dasharray: 4,4;")
  let x_axis = svg_line([
    attr_double("x1", 0.0),
    attr_double("y1", 0.0),
    attr_double("x2", 0.0),
    attr_double("y2", opts.height),
    stroke_attr("#22c55e"),
    stroke_width_double(0.8),
    axis_style,
  ])
  let y_axis_line = svg_line([
    attr_double("x1", x_min),
    attr_double("y1", y_axis),
    attr_double("x2", x_max),
    attr_double("y2", y_axis),
    stroke_attr("#3b82f6"),
    stroke_width_double(0.8),
    axis_style,
  ])
  let x_label = text_elem(
    [
      attr_double("x", 4.0),
      attr_double("y", 12.0),
      attr("font-size", "10"),
      fill_attr("#22c55e"),
    ],
    "X=0",
  )
  let y_label = text_elem(
    [
      attr_double("x", x_min + 4.0),
      attr_double("y", y_axis + 12.0),
      attr("font-size", "10"),
      fill_attr("#3b82f6"),
    ],
    "Y=0",
  )
  g([class_attr("jww-debug-axes")], [x_axis, y_axis_line, x_label, y_label])
}

///|
fn render_debug_print_area(
  doc : ParserDocument,
  opts : RenderOptions,
) -> SvgElement {
  let ps = doc.print_settings
  let (paper_width, paper_height) = debug_paper_size_to_mm(doc.paper_size)
  let scale_factor = if ps.scale > 0.0 { ps.scale } else { 1.0 }
  let scaled_width = paper_width / scale_factor
  let scaled_height = paper_height / scale_factor
  let (final_width, final_height) = if debug_should_rotate_90(
      ps.rotation_setting,
    ) {
    (scaled_height, scaled_width)
  } else {
    (scaled_width, scaled_height)
  }
  let (adjusted_x, adjusted_y) = debug_adjust_origin_for_rotation(
    ps.origin_x,
    ps.origin_y,
    final_width,
    final_height,
    ps.rotation_setting,
  )
  let x = adjusted_x
  let y = opts.transform_y(adjusted_y)
  let width = opts.transform_distance(final_width)
  let height = opts.transform_distance(final_height)
  let base_attrs = [
    attr_double("x", x),
    attr_double("y", y),
    attr_double("width", width),
    attr_double("height", height),
    stroke_attr("#ef4444"),
    fill_none(),
    stroke_width_double(1.0),
    style_attr("stroke-dasharray: 5,5;"),
  ]
  let attrs = if debug_should_rotate_90(ps.rotation_setting) {
    let center_x = x + width / 2.0
    let center_y = y + height / 2.0
    let transform_attr = attr(
      "transform",
      "rotate(90, " + center_x.to_string() + ", " + center_y.to_string() + ")",
    )
    [
      attr_double("x", x),
      attr_double("y", y),
      attr_double("width", width),
      attr_double("height", height),
      stroke_attr("#ef4444"),
      fill_none(),
      stroke_width_double(1.0),
      style_attr("stroke-dasharray: 5,5;"),
      transform_attr,
    ]
  } else {
    base_attrs
  }
  rect(attrs)
}

///|
fn debug_paper_size_to_mm(paper_size : UInt) -> (Double, Double) {
  match paper_size {
    0U => (1189.0, 841.0) // A0
    1U => (841.0, 594.0) // A1
    2U => (594.0, 420.0) // A2
    3U => (420.0, 297.0) // A3
    4U => (297.0, 210.0) // A4
    8U => (1682.0, 1189.0) // 2A
    9U => (2378.0, 1682.0) // 3A
    _ => (297.0, 210.0) // default: A4
  }
}

///|
fn debug_should_rotate_90(rotation_setting : UInt) -> Bool {
  rotation_setting >= 1U && rotation_setting <= 5U
}

///|
fn debug_adjust_origin_for_rotation(
  origin_x : Double,
  origin_y : Double,
  width : Double,
  height : Double,
  rotation_setting : UInt,
) -> (Double, Double) {
  match rotation_setting {
    0U => (origin_x, origin_y)
    1U => (origin_x, origin_y)
    2U => (origin_x - width, origin_y)
    3U => (origin_x, origin_y - height)
    4U => (origin_x - width, origin_y - height)
    5U => (origin_x - width / 2.0, origin_y - height / 2.0)
    6U => (origin_x, origin_y - height / 2.0)
    7U => (origin_x - width / 2.0, origin_y - height)
    8U => (origin_x - width, origin_y - height / 2.0)
    9U => (origin_x - width / 2.0, origin_y)
    _ => (origin_x, origin_y)
  }
}

///|
/// Get entity layer ID (0-15)
fn get_entity_layer_conv(entity : ParserEntity) -> Int {
  match entity {
    ParserEntity::Line(l) => l.base.layer.to_int()
    ParserEntity::Arc(a) => a.base.layer.to_int()
    ParserEntity::Text(t) => t.base.layer.to_int()
    ParserEntity::Point(p) => p.base.layer.to_int()
    ParserEntity::Solid(s) => s.base.layer.to_int()
    ParserEntity::Block(b) => b.base.layer.to_int()
    ParserEntity::Image(i) => i.base.layer.to_int()
    ParserEntity::ArcSolid(a) => a.base.layer.to_int()
  }
}

///|
/// Render a single entity to SVG element
fn render_entity_conv(
  entity : ParserEntity,
  opts : RenderOptions,
) -> SvgElement {
  match entity {
    ParserEntity::Line(l) => render_line_conv(l, opts)
    ParserEntity::Arc(a) => render_arc_conv(a, opts)
    ParserEntity::Point(p) => render_point_conv(p, opts)
    ParserEntity::Text(t) => render_text_conv(t, opts)
    ParserEntity::Solid(s) => render_solid_conv(s, opts)
    ParserEntity::Block(b) => render_block_conv(b, opts)
    ParserEntity::Image(i) => render_image_conv(i, opts)
    ParserEntity::ArcSolid(a) => render_arc_solid_conv(a, opts)
  }
}

///|
/// Helper function to get stroke width with minimum value
fn stroke_width_min(pen_width : UInt16) -> Double {
  let pw = pen_width.to_int()
  let base = if pw <= 0 { 1 } else { pw }
  let w = base * 50 / 100
  if w < 50 {
    50.0
  } else {
    w.to_double()
  }
}

///|
/// Derive ellipse radii from JWW arc parameters
fn arc_radii(radius : Double, flatness : Double) -> (Double, Double) {
  let rx = radius.abs()
  let f = flatness.abs()
  let ry = if f <= 0.0 { rx } else { rx * f }
  (rx, ry)
}

///|
/// Compute a point on a tilted ellipse (JWW coordinate system)
fn ellipse_point(
  cx : Double,
  cy : Double,
  rx : Double,
  ry : Double,
  tilt : Double,
  angle : Double,
) -> (Double, Double) {
  let cos_a = cos_d(angle)
  let sin_a = sin_d(angle)
  let cos_t = cos_d(tilt)
  let sin_t = sin_d(tilt)
  let x = cx + rx * cos_a * cos_t - ry * sin_a * sin_t
  let y = cy + rx * cos_a * sin_t + ry * sin_a * cos_t
  (x, y)
}

///|
/// Convert tilt angle (radians) to SVG rotation degrees
fn tilt_to_svg_degrees(tilt : Double) -> Double {
  let rad_to_deg = 180.0 / 3.141592653589793
  tilt * rad_to_deg
}

///|
/// Axis-aligned extents of a rotated ellipse
fn ellipse_extents(rx : Double, ry : Double, tilt : Double) -> (Double, Double) {
  let cos_t = cos_d(tilt)
  let sin_t = sin_d(tilt)
  let rx_cos = rx * cos_t
  let rx_sin = rx * sin_t
  let ry_cos = ry * cos_t
  let ry_sin = ry * sin_t
  let x_extent = (rx_cos * rx_cos + ry_sin * ry_sin).sqrt()
  let y_extent = (rx_sin * rx_sin + ry_cos * ry_cos).sqrt()
  (x_extent, y_extent)
}

///|
/// Render line entity
fn render_line_conv(l : ParserLine, opts : RenderOptions) -> SvgElement {
  let stroke_w = stroke_width_min(l.base.pen_width)
  let line_type = pen_style_to_line_type(l.base.pen_style.to_int())
  let scale = stroke_w / 100.0
  let base_attrs = [
    attr_double("x1", l.start_x),
    attr_double("y1", opts.transform_y(l.start_y)),
    attr_double("x2", l.end_x),
    attr_double("y2", opts.transform_y(l.end_y)),
    stroke_attr(to_svg_color(l.base.pen_color.to_int())),
    stroke_width_double(scale),
    fill_none(),
  ]
  match line_type_to_dasharray(line_type, scale) {
    Some(dash_attr) => svg_line(base_attrs + [dash_attr])
    None => svg_line(base_attrs)
  }
}

///|
/// Render arc entity
fn render_arc_conv(a : ParserArc, opts : RenderOptions) -> SvgElement {
  let cx = a.center_x
  let cy = opts.transform_y(a.center_y)
  let (rx, ry) = arc_radii(a.radius, a.flatness)
  let rotation = tilt_to_svg_degrees(a.tilt_angle)
  let color = to_svg_color(a.base.pen_color.to_int())
  let stroke_w = stroke_width_min(a.base.pen_width)
  let line_type = pen_style_to_line_type(a.base.pen_style.to_int())
  let scale = stroke_w / 100.0
  if a.is_full_circle {
    if a.flatness == 1.0 {
      let base_attrs = [
        attr_double("cx", cx),
        attr_double("cy", cy),
        attr_double("r", rx),
        fill_none(),
        stroke_attr(color),
        stroke_width_double(scale),
      ]
      match line_type_to_dasharray(line_type, scale) {
        Some(dash_attr) => circle(base_attrs + [dash_attr])
        None => circle(base_attrs)
      }
    } else {
      let base_attrs = [
        attr_double("cx", cx),
        attr_double("cy", cy),
        attr_double("rx", rx),
        attr_double("ry", ry),
        fill_none(),
        stroke_attr(color),
        stroke_width_double(scale),
      ]
      let ellipse_attrs = if a.tilt_angle != 0.0 {
        base_attrs +
        [
          attr(
            "transform",
            "rotate(" +
            rotation.to_string() +
            " " +
            cx.to_string() +
            " " +
            cy.to_string() +
            ")",
          ),
        ]
      } else {
        base_attrs
      }
      match line_type_to_dasharray(line_type, scale) {
        Some(dash_attr) => ellipse(ellipse_attrs + [dash_attr])
        None => ellipse(ellipse_attrs)
      }
    }
  } else {
    let start_angle = a.start_angle
    let end_angle = start_angle + a.arc_angle
    let (x1_raw, y1_raw) = ellipse_point(
      a.center_x,
      a.center_y,
      rx,
      ry,
      a.tilt_angle,
      start_angle,
    )
    let (x2_raw, y2_raw) = ellipse_point(
      a.center_x,
      a.center_y,
      rx,
      ry,
      a.tilt_angle,
      end_angle,
    )
    let x1 = x1_raw
    let y1 = opts.transform_y(y1_raw)
    let x2 = x2_raw
    let y2 = opts.transform_y(y2_raw)
    let large_arc = if a.arc_angle.abs() > 3.14159 { 1 } else { 0 }
    let sweep = if a.arc_angle > 0.0 { 0 } else { 1 }
    let path_d = "M " +
      x1.to_string() +
      " " +
      y1.to_string() +
      " A " +
      rx.to_string() +
      " " +
      ry.to_string() +
      " " +
      rotation.to_string() +
      " " +
      large_arc.to_string() +
      " " +
      sweep.to_string() +
      " " +
      x2.to_string() +
      " " +
      y2.to_string()
    let base_attrs = [
      attr("d", path_d),
      fill_none(),
      stroke_attr(color),
      stroke_width_double(scale),
    ]
    match line_type_to_dasharray(line_type, scale) {
      Some(dash_attr) => path(base_attrs + [dash_attr])
      None => path(base_attrs)
    }
  }
}

///|
/// Render point entity
fn render_point_conv(p : ParserPoint, opts : RenderOptions) -> SvgElement {
  circle([
    attr_double("cx", p.x),
    attr_double("cy", opts.transform_y(p.y)),
    attr_double("r", 2.0),
    fill_attr(to_svg_color(p.base.pen_color.to_int())),
  ])
}

///|
/// Render text entity with rotation support
fn render_text_conv(t : ParserText, opts : RenderOptions) -> SvgElement {
  let x = t.start_x
  let y = opts.transform_y(t.start_y)
  let font_size = t.size_y.abs()
  let color = to_svg_color(t.base.pen_color.to_int())
  let angle = t.angle
  let transform = "transform-origin: " +
    x.to_string() +
    "px " +
    y.to_string() +
    "px; transform: rotate(" +
    (-angle).to_string() +
    "deg);"
  text_elem(
    [
      attr_double("x", x),
      attr_double("y", y),
      attr("fill", color),
      attr_double("font-size", font_size),
      attr("data-base-size", font_size.to_string()),
      attr("font-family", "sans-serif"),
      attr("class", "jww-text"),
      style_attr(transform),
    ],
    t.content,
  )
}

///|
/// Render solid (filled polygon) entity
fn render_solid_conv(s : ParserSolid, opts : RenderOptions) -> SvgElement {
  let points = s.point1_x.to_string() +
    "," +
    opts.transform_y(s.point1_y).to_string() +
    " " +
    s.point2_x.to_string() +
    "," +
    opts.transform_y(s.point2_y).to_string() +
    " " +
    s.point3_x.to_string() +
    "," +
    opts.transform_y(s.point3_y).to_string() +
    " " +
    s.point4_x.to_string() +
    "," +
    opts.transform_y(s.point4_y).to_string()
  polygon([
    attr("points", points),
    fill_attr(to_svg_color(s.base.pen_color.to_int())),
    stroke_none(),
  ])
}

///|
/// Render arc solid entity (filled arc/circle)
fn render_arc_solid_conv(a : @jww_parser_core.ArcSolid, opts : RenderOptions) -> SvgElement {
  let cx = a.center_x
  let cy = opts.transform_y(a.center_y)
  let (rx, ry) = arc_radii(a.radius, a.flatness)
  let rotation = tilt_to_svg_degrees(a.tilt_angle)
  let color = to_svg_color(a.base.pen_color.to_int())
  // For full circle solid, render as filled circle
  if a.arc_angle.abs() >= 6.28 {
    if a.flatness == 1.0 {
      circle([
        attr_double("cx", cx),
        attr_double("cy", cy),
        attr_double("r", rx),
        fill_attr(color),
        stroke_none(),
      ])
    } else {
      let base_attrs = [
        attr_double("cx", cx),
        attr_double("cy", cy),
        attr_double("rx", rx),
        attr_double("ry", ry),
        fill_attr(color),
        stroke_none(),
      ]
      let ellipse_attrs = if a.tilt_angle != 0.0 {
        base_attrs +
        [
          attr(
            "transform",
            "rotate(" +
            rotation.to_string() +
            " " +
            cx.to_string() +
            " " +
            cy.to_string() +
            ")",
          ),
        ]
      } else {
        base_attrs
      }
      ellipse(ellipse_attrs)
    }
  } else {
    // For arc solid, render as filled path
    let start_angle = a.start_angle
    let end_angle = start_angle + a.arc_angle
    let (x1_raw, y1_raw) = ellipse_point(
      a.center_x,
      a.center_y,
      rx,
      ry,
      a.tilt_angle,
      start_angle,
    )
    let (x2_raw, y2_raw) = ellipse_point(
      a.center_x,
      a.center_y,
      rx,
      ry,
      a.tilt_angle,
      end_angle,
    )
    let x1 = x1_raw
    let y1 = opts.transform_y(y1_raw)
    let x2 = x2_raw
    let y2 = opts.transform_y(y2_raw)
    let large_arc = if a.arc_angle.abs() > 3.14159 { 1 } else { 0 }
    let sweep = if a.arc_angle > 0.0 { 0 } else { 1 }
    let path_d = "M " + cx.to_string() + " " + cy.to_string() +
      " L " + x1.to_string() + " " + y1.to_string() +
      " A " + rx.to_string() + " " + ry.to_string() +
      " " + rotation.to_string() + " " + large_arc.to_string() +
      " " + sweep.to_string() +
      " " + x2.to_string() + " " + y2.to_string() + " Z"
    path([
      attr("d", path_d),
      fill_attr(color),
      stroke_none(),
    ])
  }
}

///|
/// Render block entity
fn render_block_conv(b : ParserBlock, opts : RenderOptions) -> SvgElement {
  text_elem(
    [
      attr_double("x", b.ref_x),
      attr_double("y", opts.transform_y(b.ref_y)),
      attr("fill", "#999"),
      attr("font-size", "10"),
      style_attr("opacity: 0.5;"),
    ],
    "[Block " + b.def_number.to_string() + "]",
  )
}

///|
/// Render image entity
fn render_image_conv(i : ParserImage, opts : RenderOptions) -> SvgElement {
  let x = i.x
  let y = opts.transform_y(i.y)
  let base_attrs = [
    attr_double("x", x),
    attr_double("y", y),
    attr_double("width", i.width),
    attr_double("height", i.height),
    attr("href", i.image_path),
    attr("class", "jww-image"),
    attr("data-image-path", i.image_path),
    attr("data-status", "loading"),
  ]
  let final_attrs = if i.rotation != 0.0 {
    base_attrs +
    [
      attr(
        "transform",
        "rotate(" +
        i.rotation.to_string() +
        " " +
        x.to_string() +
        " " +
        y.to_string() +
        ")",
      ),
    ]
  } else {
    base_attrs
  }
  image_elem(final_attrs)
}
