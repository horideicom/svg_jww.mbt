///|
/// Renderers for JWW entities to SVG
pub fn render_entity(entity : JwwEntity, opts : RenderOptions) -> SvgElement {
  match entity {
    JwwEntity::LineEnt(line) => render_line(line, opts)
    JwwEntity::ArcEnt(arc) => render_arc(arc, opts)
    JwwEntity::PointEnt(point) => render_point(point, opts)
    JwwEntity::TextEnt(text) => render_text(text, opts)
    JwwEntity::SolidEnt(solid) => render_solid(solid, opts)
    JwwEntity::BlockEnt(block) => render_block(block, opts)
    JwwEntity::PolylineEnt(poly) => render_polyline(poly, opts)
    JwwEntity::ImageEnt(img) => render_image(img, opts)
  }
}

///|
/// Render a line entity
pub fn render_line(line : JwwLine, opts : RenderOptions) -> SvgElement {
  let x1 = opts.transform_x(line.x1)
  let y1 = opts.transform_y(line.y1)
  let x2 = opts.transform_x(line.x2)
  let y2 = opts.transform_y(line.y2)
  let color = to_svg_color(line.base.pen_color)
  let width = to_svg_stroke_width(line.base.pen_width)
  let attrs = [
    attr("x1", x1.to_string()),
    attr("y1", y1.to_string()),
    attr("x2", x2.to_string()),
    attr("y2", y2.to_string()),
    stroke_attr(color),
    stroke_width_attr(width),
    fill_none(),
  ]
  svg_line(attrs)
}

///|
/// Render an arc/circle entity
pub fn render_arc(arc : JwwArc, opts : RenderOptions) -> SvgElement {
  let cx = opts.transform_x(arc.cx)
  let cy = opts.transform_y(arc.cy)
  let r = opts.transform_distance(arc.radius)
  let color = to_svg_color(arc.base.pen_color)
  let width = to_svg_stroke_width(arc.base.pen_width)
  if arc.is_full {
    // Full circle
    let attrs = [
      attr("cx", cx.to_string()),
      attr("cy", cy.to_string()),
      attr("r", r.to_string()),
      stroke_attr(color),
      stroke_width_attr(width),
      fill_none(),
    ]
    circle(attrs)
  } else {
    // Arc using path
    let start_x = cx + r * cos_d(arc.start_angle)
    let start_y = cy + r * sin_d(arc.start_angle)
    let end_x = cx + r * cos_d(arc.end_angle)
    let end_y = cy + r * sin_d(arc.end_angle)
    let large_arc = if arc.end_angle - arc.start_angle > 3.14159 {
      1
    } else {
      0
    }
    let path_d = "M " +
      start_x.to_string() +
      "," +
      start_y.to_string() +
      " A " +
      r.to_string() +
      "," +
      r.to_string() +
      " 0 " +
      large_arc.to_string() +
      ",1 " +
      end_x.to_string() +
      "," +
      end_y.to_string()
    let attrs = [
      attr("d", path_d),
      stroke_attr(color),
      stroke_width_attr(width),
      fill_none(),
    ]
    path(attrs)
  }
}

///|
/// Render a point entity
pub fn render_point(point : JwwPoint, opts : RenderOptions) -> SvgElement {
  let x = opts.transform_x(point.x)
  let y = opts.transform_y(point.y)
  let color = to_svg_color(point.base.pen_color)
  let size = opts.transform_distance(2.0) // 2mm default point size
  let attrs = [
    attr("cx", x.to_string()),
    attr("cy", y.to_string()),
    attr("r", (size / 2.0).to_string()),
    fill_attr(color),
  ]
  circle(attrs)
}

///|
/// Render a text entity
pub fn render_text(text : JwwText, opts : RenderOptions) -> SvgElement {
  let x = opts.transform_x(text.x)
  let y = opts.transform_y(text.y)
  let font_size = opts.transform_distance(text.size)
  let color = to_svg_color(text.base.pen_color)
  let attrs = [
    attr("x", x.to_string()),
    attr("y", y.to_string()),
    attr("fill", color),
    attr("font-size", font_size.to_string()),
    attr("font-family", "sans-serif"),
    style_attr(
      "transform-origin: " +
      x.to_string() +
      "px " +
      y.to_string() +
      "px; transform: rotate(" +
      (-text.angle).to_string() +
      "deg);",
    ),
  ]
  text_elem(attrs, text.text)
}

///|
/// Render a solid fill entity
pub fn render_solid(solid : JwwSolid, opts : RenderOptions) -> SvgElement {
  let x1 = opts.transform_x(solid.x1)
  let y1 = opts.transform_y(solid.y1)
  let x2 = opts.transform_x(solid.x2)
  let y2 = opts.transform_y(solid.y2)
  let x3 = opts.transform_x(solid.x3)
  let y3 = opts.transform_y(solid.y3)
  let x4 = opts.transform_x(solid.x4)
  let y4 = opts.transform_y(solid.y4)
  let color = to_svg_color(solid.color)
  let points = x1.to_string() +
    "," +
    y1.to_string() +
    " " +
    x2.to_string() +
    "," +
    y2.to_string() +
    " " +
    x3.to_string() +
    "," +
    y3.to_string() +
    " " +
    x4.to_string() +
    "," +
    y4.to_string()
  let attrs = [attr("points", points), fill_attr(color), stroke_none()]
  polygon(attrs)
}

///|
/// Render a block reference
pub fn render_block(block : JwwBlock, opts : RenderOptions) -> SvgElement {
  let x = opts.transform_x(block.x)
  let y = opts.transform_y(block.y)
  // Block reference - for now, render a placeholder
  let color = to_svg_color(block.base.pen_color)
  let size = 20.0 // placeholder size
  let attrs = [
    attr("x", (x - size / 2.0).to_string()),
    attr("y", (y - size / 2.0).to_string()),
    attr("width", size.to_string()),
    attr("height", size.to_string()),
    stroke_attr(color),
    fill_none(),
    attr("stroke-width", "1"),
    style_attr("stroke-dasharray: 2,2"),
  ]
  rect(attrs)
}

///|
/// Render a polyline
pub fn render_polyline(poly : JwwPolyline, opts : RenderOptions) -> SvgElement {
  let points_str = poly.points
    .map(fn(p) {
      let (px, py) = p
      let x = opts.transform_x(px)
      let y = opts.transform_y(py)
      x.to_string() + "," + y.to_string()
    })
    .join(" ")
  let color = to_svg_color(poly.base.pen_color)
  let width = to_svg_stroke_width(poly.base.pen_width)
  if poly.is_closed {
    let attrs = [
      attr("points", points_str),
      stroke_attr(color),
      stroke_width_attr(width),
      fill_none(),
    ]
    polygon(attrs)
  } else {
    let attrs = [
      attr("points", points_str),
      stroke_attr(color),
      stroke_width_attr(width),
      fill_none(),
    ]
    polyline(attrs)
  }
}

///|
/// Render an image entity
pub fn render_image(img : JwwImage, opts : RenderOptions) -> SvgElement {
  let x = opts.transform_x(img.x)
  let y = opts.transform_y(img.y)
  let width = opts.transform_distance(img.width)
  let height = opts.transform_distance(img.height)
  let attrs = [
    attr("x", x.to_string()),
    attr("y", y.to_string()),
    attr("width", width.to_string()),
    attr("height", height.to_string()),
    attr("href", img.image_path),
    style_attr(
      "transform-origin: " +
      x.to_string() +
      "px " +
      y.to_string() +
      "px; transform: rotate(" +
      (-img.rotation).to_string() +
      "deg);",
    ),
  ]
  image_elem(attrs)
}

///|
/// Render print area visualization
pub fn render_print_area(
  doc : JwwDocument,
  opts : RenderOptions,
) -> SvgElement {
  let x = opts.transform_x(doc.print_settings.origin_x)
  let y = opts.transform_y(doc.print_settings.origin_y)
  // Use drawing width/height for print area size
  let width = opts.transform_distance(doc.drawing_width)
  let height = opts.transform_distance(doc.drawing_height)
  let attrs = [
    attr("x", x.to_string()),
    attr("y", y.to_string()),
    attr("width", width.to_string()),
    attr("height", height.to_string()),
    stroke_attr("#ff0000"),
    fill_none(),
    attr("stroke-width", "1"),
    style_attr("stroke-dasharray: 5,5;"),
  ]
  rect(attrs)
}

///|
/// Render an entire document
pub fn render_document(doc : JwwDocument, opts : RenderOptions) -> SvgElement {
  // Calculate document bounds
  let bounds = calculate_document_bounds(doc)
  // Create viewBox string
  let view_box = bounds.min_x.to_string() +
    " " +
    bounds.min_y.to_string() +
    " " +
    bounds.width().to_string() +
    " " +
    bounds.height().to_string()
  // Render all entities
  let entities_svg = doc.entities.map(fn(e) { render_entity(e, opts) })
  // Add print area if enabled
  let print_area_svg = if opts.show_print_area {
    [render_print_area(doc, opts)]
  } else {
    []
  }
  let all_children = entities_svg.concat(print_area_svg)
  // Root SVG element
  let attrs = [
    attr("viewBox", view_box),
    attr("width", opts.width.to_string()),
    attr("height", opts.height.to_string()),
    attr("xmlns", "http://www.w3.org/2000/svg"),
    style_attr("background-color: " + opts.background_color + ";"),
  ]
  svg(attrs, all_children)
}

///|
/// Calculate bounding box for all entities in document
pub fn calculate_document_bounds(doc : JwwDocument) -> BoundingBox {
  let init = BoundingBox::new()
  doc.entities
  .map(fn(e) { entity_bounds(e) })
  .fold(init~, fn(bbox, b) {
    BoundingBox::{
      min_x: if bbox.min_x < b.min_x {
        bbox.min_x
      } else {
        b.min_x
      },
      min_y: if bbox.min_y < b.min_y {
        bbox.min_y
      } else {
        b.min_y
      },
      max_x: if bbox.max_x > b.max_x {
        bbox.max_x
      } else {
        b.max_x
      },
      max_y: if bbox.max_y > b.max_y {
        bbox.max_y
      } else {
        b.max_y
      },
    }
  })
}

///|
/// Get bounding box for an entity
pub fn entity_bounds(entity : JwwEntity) -> BoundingBox {
  match entity {
    JwwEntity::LineEnt(line) =>
      BoundingBox::new().expand(line.x1, line.y1).expand(line.x2, line.y2)
    JwwEntity::ArcEnt(arc) =>
      BoundingBox::new()
      .expand(arc.cx - arc.radius, arc.cy - arc.radius)
      .expand(arc.cx + arc.radius, arc.cy + arc.radius)
    JwwEntity::PointEnt(point) => BoundingBox::new().expand(point.x, point.y)
    JwwEntity::TextEnt(text) => BoundingBox::new().expand(text.x, text.y)
    JwwEntity::SolidEnt(solid) =>
      BoundingBox::new()
      .expand(solid.x1, solid.y1)
      .expand(solid.x2, solid.y2)
      .expand(solid.x3, solid.y3)
      .expand(solid.x4, solid.y4)
    JwwEntity::BlockEnt(block) => BoundingBox::new().expand(block.x, block.y)
    JwwEntity::PolylineEnt(poly) => {
      let init = BoundingBox::new()
      poly.points.fold(init~, fn(bbox, p) {
        let (px, py) = p
        bbox.expand(px, py)
      })
    }
    JwwEntity::ImageEnt(img) =>
      BoundingBox::new().expand(img.x, img.y).expand(img.x + img.width, img.y + img.height)
  }
}
