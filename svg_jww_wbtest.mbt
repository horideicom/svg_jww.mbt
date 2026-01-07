///|
test "svg_line_element" {
  let attrs = [
    attr("x1", "10"),
    attr("y1", "20"),
    attr("x2", "100"),
    attr("y2", "200"),
  ]
  let line_elem = svg_line(attrs)
  let result = to_string(line_elem)
  inspect(result, content="<line x1=\"10\" y1=\"20\" x2=\"100\" y2=\"200\" />")
}

///|
test "svg_circle_element" {
  let attrs = [attr("cx", "50"), attr("cy", "50"), attr("r", "25")]
  let circle_elem = circle(attrs)
  let result = to_string(circle_elem)
  inspect(result, content="<circle cx=\"50\" cy=\"50\" r=\"25\" />")
}

///|
test "svg_group_with_children" {
  let line1 = svg_line([
    attr("x1", "0"),
    attr("y1", "0"),
    attr("x2", "100"),
    attr("y2", "100"),
  ])
  let line2 = svg_line([
    attr("x1", "100"),
    attr("y1", "0"),
    attr("x2", "0"),
    attr("y2", "100"),
  ])
  let group = g([class_attr("lines")], [line1, line2])
  let result = to_string(group)
  inspect(
    result,
    content="<g class=\"lines\"><line x1=\"0\" y1=\"0\" x2=\"100\" y2=\"100\" /><line x1=\"100\" y1=\"0\" x2=\"0\" y2=\"100\" /></g>",
  )
}

///|
test "svg_text_element" {
  let text_elem = text_elem([attr("x", "10"), attr("y", "20")], "Hello SVG")
  let result = to_string(text_elem)
  inspect(result, content="<text x=\"10\" y=\"20\">Hello SVG</text>")
}

///|
test "svg_root_element" {
  let circle_elem = circle([attr("cx", "50"), attr("cy", "50"), attr("r", "25")])
  let svg_elem = svg(
    [
      attr("width", "100"),
      attr("height", "100"),
      attr("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [circle_elem],
  )
  let result = to_string(svg_elem)
  inspect(
    result,
    content="<svg width=\"100\" height=\"100\" xmlns=\"http://www.w3.org/2000/svg\"><circle cx=\"50\" cy=\"50\" r=\"25\" /></svg>",
  )
}

///|
test "xml_escaping" {
  let text_elem = text_elem([], "Hello <world> & friends")
  let result = to_string(text_elem)
  inspect(result, content="<text>Hello &lt;world&gt; &amp; friends</text>")
}

///|
test "bounding_box_expand" {
  let bbox = BoundingBox::new()
  // Initial state: min=max=0 for both x and y
  // expand(10.0, 20.0): min stays 0, max becomes (10, 20)
  let bbox1 = bbox.expand(10.0, 20.0)
  // expand(30.0, 40.0): min stays 0, max becomes (30, 40)
  let bbox2 = bbox1.expand(30.0, 40.0)
  // expand(5.0, 10.0): x=5 is not < 0, y=10 is not < 0, so min stays 0
  let bbox3 = bbox2.expand(5.0, 10.0)
  inspect(bbox3.min_x, content="0")
  inspect(bbox3.min_y, content="0")
  inspect(bbox3.max_x, content="30")
  inspect(bbox3.max_y, content="40")
}

///|
test "bounding_box_dimensions" {
  let bbox = BoundingBox::new().expand(0.0, 0.0).expand(100.0, 50.0)
  inspect(bbox.width(), content="100")
  inspect(bbox.height(), content="50")
}

///|
test "color_conversion" {
  inspect(to_svg_color(0), content="#ffffff")
  inspect(to_svg_color(1), content="#000000")
  inspect(to_svg_color(2), content="#ff0000")
  inspect(to_svg_color(4), content="#0000ff")
  inspect(to_svg_color(99), content="#000000") // Unknown color defaults to black
}

///|
test "rgb_color_conversion" {
  inspect(to_rgb_color(255, 0, 0), content="#ff0000")
  inspect(to_rgb_color(0, 255, 0), content="#00ff00")
  inspect(to_rgb_color(0, 0, 255), content="#0000ff")
}

///|
test "stroke_width_conversion" {
  inspect(to_svg_stroke_width(1), content="1")
  inspect(to_svg_stroke_width(5), content="5")
  inspect(to_svg_stroke_width(0), content="1") // Zero defaults to 1
  inspect(to_svg_stroke_width(-1), content="1") // Negative defaults to 1
}

///|
test "render_options_transform" {
  // Create options - using with_size then checking transform methods
  let size_opts = RenderOptions::with_size(800.0, 600.0)
  inspect(size_opts.transform_x(100.0), content="100") // scale is 1.0 by default
  // transform_y now uses (bounds_max_y - y) * scale + offset_y + padding
  // with_size sets bounds_max_y = height = 600, padding = 0
  // So transform_y(0) = (600 - 0) * 1 + 0 + 0 = 600
  inspect(size_opts.transform_y(0.0), content="600")
  let scale_opts = RenderOptions::with_scale(2.0)
  inspect(scale_opts.transform_x(100.0), content="200") // scale is 2.0
  // transform_y(0) = (600 - 0) * 2 + 0 + 0 = 1200
  inspect(scale_opts.transform_y(0.0), content="1200")
}

///|
test "pen_style_to_line_type" {
  // 0 = 実線扱い
  inspect(pen_style_to_line_type(0), content="Solid")
  // 1 = 実線
  inspect(pen_style_to_line_type(1), content="Solid")
  // 2 = 点線1
  inspect(pen_style_to_line_type(2), content="Custom([1, 2])")
  // 3 = 点線2
  inspect(pen_style_to_line_type(3), content="Custom([2, 2])")
  // 4 = 一点鎖線1
  inspect(pen_style_to_line_type(4), content="Custom([8, 3, 1, 3])")
  // 5 = 一点鎖線2
  inspect(pen_style_to_line_type(5), content="Custom([12, 3, 2, 3])")
  // 6 = 二点鎖線1
  inspect(pen_style_to_line_type(6), content="Custom([8, 3, 1, 3, 1, 3])")
  // 7 = 二点鎖線2
  inspect(pen_style_to_line_type(7), content="Custom([12, 3, 2, 3, 2, 3])")
  // 8 = 補助線
  inspect(pen_style_to_line_type(8), content="Custom([1, 4])")
  // 未知の値は実線
  inspect(pen_style_to_line_type(99), content="Solid")
}

///|
test "line_type_dasharray" {
  let scale = 1.0
  // Solid returns None
  inspect(line_type_to_dasharray(LineType::Solid, scale), content="None")
  // Custom pattern
  let custom = LineType::Custom([5.0, 3.0])
  inspect(line_type_to_dasharray(custom, scale), content="Some((\"stroke-dasharray\", \"5,3\"))")
  // With scale
  let custom2 = LineType::Custom([5.0, 3.0])
  inspect(line_type_to_dasharray(custom2, 2.0), content="Some((\"stroke-dasharray\", \"10,6\"))")
}

///|
test "attribute_builders" {
  inspect(attr("id", "test"), content="(\"id\", \"test\")")
  inspect(attr_double("x", 10.5), content="(\"x\", \"10.5\")")
  inspect(attr_int("width", 100), content="(\"width\", \"100\")")
  inspect(fill_attr("#ff0000"), content="(\"fill\", \"#ff0000\")")
  inspect(stroke_attr("#0000ff"), content="(\"stroke\", \"#0000ff\")")
  inspect(fill_none(), content="(\"fill\", \"none\")")
  inspect(class_attr("my-class"), content="(\"class\", \"my-class\")")
}

///|
test "render_line_basic" {
  let line = JwwLine::{
    base: EntityBase::new(),
    x1: 0.0,
    y1: 0.0,
    x2: 100.0,
    y2: 100.0,
  }
  let opts = RenderOptions::with_size(200.0, 200.0)
  let result = render_line(line, opts)
  let svg_str = to_string(result)
  // Y coordinates are flipped: 200-0=200, 200-100=100
  inspect(
    svg_str,
    content=(
      #|<line x1="0" y1="200" x2="100" y2="100" stroke="#000000" stroke-width="1" fill="none" />
    ),
  )
}

///|
test "render_arc_full_circle" {
  let arc = JwwArc::{
    base: EntityBase::new(),
    cx: 100.0,
    cy: 100.0,
    radius: 50.0,
    start_angle: 0.0,
    end_angle: 6.28318,
    is_full: true,
  }
  let opts = RenderOptions::with_size(200.0, 200.0)
  let result = render_arc(arc, opts)
  let svg_str = to_string(result)
  inspect(
    svg_str,
    content=(
      #|<circle cx="100" cy="100" r="50" stroke="#000000" stroke-width="1" fill="none" />
    ),
  )
}

///|
test "arc_radii_flatness" {
  let (rx, ry) = arc_radii(10.0, 0.5)
  inspect(rx, content="10")
  inspect(ry, content="5")
}

///|
test "ellipse_point_axis_aligned" {
  let (x, y) = ellipse_point(
    0.0,
    0.0,
    10.0,
    5.0,
    0.0,
    1.5707963267948966,
  )
  assert_true(x.abs() < 0.01)
  assert_true((y - 5.0).abs() < 0.01)
}

///|
test "ellipse_extents_no_tilt" {
  let (x_ext, y_ext) = ellipse_extents(10.0, 5.0, 0.0)
  assert_true((x_ext - 10.0).abs() < 0.01)
  assert_true((y_ext - 5.0).abs() < 0.01)
}

///|
test "tilt_to_svg_degrees" {
  inspect(tilt_to_svg_degrees(1.5707963267948966), content="90")
}

///|
test "render_point" {
  let point = JwwPoint::{
    base: EntityBase::new(),
    x: 50.0,
    y: 50.0,
    point_type: 1,
  }
  let opts = RenderOptions::with_size(100.0, 100.0)
  let result = render_point(point, opts)
  let svg_str = to_string(result)
  inspect(
    svg_str,
    content=(
      #|<circle cx="50" cy="50" r="1" fill="#000000" />
    ),
  )
}

///|
test "render_polyline_open" {
  let poly = JwwPolyline::{
    base: EntityBase::new(),
    points: [(0.0, 0.0), (50.0, 50.0), (100.0, 0.0)],
    is_closed: false,
  }
  let opts = RenderOptions::with_size(100.0, 100.0)
  let result = render_polyline(poly, opts)
  let svg_str = to_string(result)
  inspect(
    svg_str,
    content=(
      #|<polyline points="0,100 50,50 100,100" stroke="#000000" stroke-width="1" fill="none" />
    ),
  )
}

///|
test "render_polyline_closed" {
  let poly = JwwPolyline::{
    base: EntityBase::new(),
    points: [(0.0, 0.0), (50.0, 50.0), (100.0, 0.0)],
    is_closed: true,
  }
  let opts = RenderOptions::with_size(100.0, 100.0)
  let result = render_polyline(poly, opts)
  let svg_str = to_string(result)
  inspect(
    svg_str,
    content=(
      #|<polygon points="0,100 50,50 100,100" stroke="#000000" stroke-width="1" fill="none" />
    ),
  )
}

///|
test "render_text_with_rotation" {
  let text = JwwText::{
    base: EntityBase::new(),
    x: 50.0,
    y: 50.0,
    text: "Hello",
    size: 12.0,
    angle: 45.0,
    font_name: "Arial",
  }
  let opts = RenderOptions::with_size(100.0, 100.0)
  let result = render_text(text, opts)
  let svg_str = to_string(result)
  inspect(
    svg_str,
    content=(
      #|<text x="50" y="50" fill="#000000" font-size="12" font-family="sans-serif" style="transform-origin: 50px 50px; transform: rotate(-45deg);">Hello</text>
    ),
  )
  inspect(
    svg_str,
    content=(
      #|<text x="50" y="50" fill="#000000" font-size="12" font-family="sans-serif" style="transform-origin: 50px 50px; transform: rotate(-45deg);">Hello</text>
    ),
  )
}

///|
test "render_solid_fill" {
  let solid = JwwSolid::{
    base: EntityBase::new(),
    x1: 0.0,
    y1: 0.0,
    x2: 100.0,
    y2: 0.0,
    x3: 100.0,
    y3: 100.0,
    x4: 0.0,
    y4: 100.0,
    color: 2, // red
  }
  let opts = RenderOptions::with_size(100.0, 100.0)
  let result = render_solid(solid, opts)
  let svg_str = to_string(result)
  inspect(
    svg_str,
    content=(
      #|<polygon points="0,100 100,100 100,0 0,0" fill="#ff0000" stroke="none" />
    ),
  )
  inspect(
    svg_str,
    content=(
      #|<polygon points="0,100 100,100 100,0 0,0" fill="#ff0000" stroke="none" />
    ),
  )
}

///|
test "render_block_placeholder" {
  let block = JwwBlock::{
    base: EntityBase::new(),
    x: 50.0,
    y: 50.0,
    scale_x: 1.0,
    scale_y: 1.0,
    angle: 0.0,
    block_name: "test_block",
  }
  let opts = RenderOptions::with_size(100.0, 100.0)
  let result = render_block(block, opts)
  let svg_str = to_string(result)
  inspect(
    svg_str,
    content=(
      #|<rect x="40" y="40" width="20" height="20" stroke="#000000" fill="none" stroke-width="1" style="stroke-dasharray: 2,2" />
    ),
  )
  inspect(
    svg_str,
    content=(
      #|<rect x="40" y="40" width="20" height="20" stroke="#000000" fill="none" stroke-width="1" style="stroke-dasharray: 2,2" />
    ),
  )
}

///|
test "render_document_simple" {
  let doc = JwwDocument::{
    version: "7.00",
    memo: "",
    version_number: 700,
    paper_size: 2U,
    drawing_width: 100.0,
    drawing_height: 100.0,
    entities: [
      JwwEntity::LineEnt(JwwLine::{
        base: EntityBase::new(),
        x1: 0.0,
        y1: 0.0,
        x2: 100.0,
        y2: 100.0,
      }),
    ],
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
  let opts = RenderOptions::with_size(200.0, 200.0)
  let result = render_document(doc, opts)
  let svg_str = to_string(result)
  inspect(
    svg_str,
    content=(
      #|<svg viewBox="0 0 100 100" width="200" height="200" xmlns="http://www.w3.org/2000/svg" style="background-color: #ffffff;"><line x1="0" y1="200" x2="100" y2="100" stroke="#000000" stroke-width="1" fill="none" /></svg>
    ),
  )
  inspect(
    svg_str,
    content=(
      #|<svg viewBox="0 0 100 100" width="200" height="200" xmlns="http://www.w3.org/2000/svg" style="background-color: #ffffff;"><line x1="0" y1="200" x2="100" y2="100" stroke="#000000" stroke-width="1" fill="none" /></svg>
    ),
  )
  inspect(
    svg_str,
    content=(
      #|<svg viewBox="0 0 100 100" width="200" height="200" xmlns="http://www.w3.org/2000/svg" style="background-color: #ffffff;"><line x1="0" y1="200" x2="100" y2="100" stroke="#000000" stroke-width="1" fill="none" /></svg>
    ),
  )
}

///|
test "calculate_document_bounds" {
  let doc = JwwDocument::{
    version: "7.00",
    memo: "",
    version_number: 700,
    paper_size: 2U,
    drawing_width: 100.0,
    drawing_height: 100.0,
    entities: [
      JwwEntity::LineEnt(JwwLine::{
        base: EntityBase::new(),
        x1: 10.0,
        y1: 20.0,
        x2: 100.0,
        y2: 200.0,
      }),
      JwwEntity::PointEnt(JwwPoint::{
        base: EntityBase::new(),
        x: 50.0,
        y: 50.0,
        point_type: 1,
      }),
    ],
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
  let bounds = calculate_document_bounds(doc)
  inspect(bounds.min_x, content="0")
  inspect(bounds.min_y, content="0")
  inspect(bounds.max_x, content="100")
  inspect(bounds.max_y, content="200")
}

///|
test "entity_bounds_line" {
  let line = JwwEntity::LineEnt(JwwLine::{
    base: EntityBase::new(),
    x1: 10.0,
    y1: 20.0,
    x2: 100.0,
    y2: 200.0,
  })
  let bounds = entity_bounds(line)
  inspect(bounds.min_x, content="0")
  inspect(bounds.min_y, content="0")
  inspect(bounds.max_x, content="100")
  inspect(bounds.max_y, content="200")
}

///|
test "entity_bounds_arc" {
  let arc = JwwEntity::ArcEnt(JwwArc::{
    base: EntityBase::new(),
    cx: 100.0,
    cy: 100.0,
    radius: 50.0,
    start_angle: 0.0,
    end_angle: 6.28318,
    is_full: true,
  })
  let bounds = entity_bounds(arc)
  inspect(bounds.min_x, content="0")
  inspect(bounds.min_y, content="0")
  inspect(bounds.max_x, content="150")
  inspect(bounds.max_y, content="150")
}

///|
test "math_trig_functions" {
  // Test cos_d and sin_d with known values
  let cos_0 = cos_d(0.0)
  inspect(cos_0, content="1")
  let cos_pi = cos_d(3.141592653589793)
  // cos(pi) should be close to -1
  let cos_pi_err = (cos_pi + 1.0).abs()
  inspect(cos_pi_err < 1.0e-12, content="true")
  let sin_half_pi = sin_d(1.570796326794897)
  let sin_half_pi_err = (sin_half_pi - 1.0).abs()
  inspect(sin_half_pi_err < 1.0e-12, content="true")
}

// === Property-Based Testing with QuickCheck ===

///|
type Gen[T] = @quickcheck.Gen[T]

///|
/// Generate a random double value using int_bound and converting to double
fn gen_double() -> Gen[Double] {
  @quickcheck.int_bound(2000).fmap(fn(i) { i.to_double() - 1000.0 })
}

///|
/// Generate a random positive double value in range [0, 1000]
fn gen_positive_double() -> Gen[Double] {
  @quickcheck.int_bound(1000).fmap(fn(i) { i.to_double() })
}

///|
/// Generate a random scale value in range [0.1, 100]
fn gen_scale() -> Gen[Double] {
  @quickcheck.int_bound(1000).fmap(fn(i) {
    let val = i.to_double() / 10.0
    if val < 0.1 {
      0.1
    } else {
      val
    }
  })
}

///|
/// Property: Transform::transform_x satisfies the formula x * scale + offset_x
test "transform_x_formula" {
  let prop = @quickcheck.liftA3(
    fn(scale : Double, offset : Double, x : Double) {
      let t = Transform::{
        scale,
        offset_x: offset,
        offset_y: 0.0,
        flip_y: false,
      }
      let result = t.transform_x(x)
      let expected = x * scale + offset
      (result - expected).abs() < 0.0001
    },
    gen_scale(),
    gen_double(),
    gen_double(),
  )
  @quickcheck.quick_check(prop)
}

///|
/// Property: Transform::transform_x is linear when offset is zero
test "transform_x_linearity" {
  let prop = @quickcheck.liftA3(
    fn(scale : Double, x : Double, k : Double) {
      let t = Transform::{ scale, offset_x: 0.0, offset_y: 0.0, flip_y: false }
      let left = t.transform_x(x * k)
      let right = t.transform_x(x) * k
      (left - right).abs() < 0.0001
    },
    gen_scale(),
    gen_double(),
    gen_double(),
  )
  @quickcheck.quick_check(prop)
}

///|
/// Property: Transform::transform_y with flip_y=true inverts Y coordinate
test "transform_y_flip_inverts" {
  let prop = @quickcheck.liftA4(
    fn(scale : Double, offset : Double, y : Double, height : Double) {
      let h = if height < 1.0 { 100.0 } else { height }
      let t = Transform::{
        scale,
        offset_x: 0.0,
        offset_y: offset,
        flip_y: true,
      }
      let result = t.transform_y(y, h)
      let expected = h - y * scale + offset
      (result - expected).abs() < 0.0001
    },
    gen_scale(),
    gen_double(),
    gen_double(),
    gen_positive_double(),
  )
  @quickcheck.quick_check(prop)
}

///|
/// Property: Transform::transform_y without flip_y preserves Y direction
test "transform_y_no_flip_preserves" {
  let prop = @quickcheck.liftA3(
    fn(scale : Double, offset : Double, y : Double) {
      let t = Transform::{
        scale,
        offset_x: 0.0,
        offset_y: offset,
        flip_y: false,
      }
      let result = t.transform_y(y, 100.0)
      let expected = y * scale + offset
      (result - expected).abs() < 0.0001
    },
    gen_scale(),
    gen_double(),
    gen_double(),
  )
  @quickcheck.quick_check(prop)
}

///|
/// Property: RenderOptions::transform_x satisfies the formula x * scale + offset_x
test "render_options_transform_x_formula" {
  let prop = @quickcheck.liftA3(
    fn(scale : Double, offset : Double, x : Double) {
      let opts = { ..RenderOptions::new(), scale, offset_x: offset }
      let result = opts.transform_x(x)
      let expected = x * scale + offset
      (result - expected).abs() < 0.0001
    },
    gen_scale(),
    gen_double(),
    gen_double(),
  )
  @quickcheck.quick_check(prop)
}

///|
/// Property: RenderOptions::transform_y flips Y coordinate
/// New formula: (bounds_max_y - y) * scale + offset_y + padding
test "render_options_transform_y_flips" {
  let prop = @quickcheck.liftA4(
    fn(bounds_max_y : Double, scale : Double, offset : Double, y : Double) {
      let bmy = if bounds_max_y < 1.0 { 100.0 } else { bounds_max_y }
      let opts = {
        ..RenderOptions::new(),
        bounds_max_y: bmy,
        scale,
        offset_y: offset,
        padding: 0.0,
      }
      let result = opts.transform_y(y)
      let expected = (bmy - y) * scale + offset
      (result - expected).abs() < 0.0001
    },
    gen_positive_double(),
    gen_scale(),
    gen_double(),
    gen_double(),
  )
  @quickcheck.quick_check(prop)
}
