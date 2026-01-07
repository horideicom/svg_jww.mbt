///|
/// SVG JWW Renderer Demo
/// Demonstrates basic SVG rendering capabilities
fn main {
  println("=== SVG JWW Renderer Demo ===")
  println("")

  // Test 1: Simple SVG creation
  println("Test 1: Simple SVG with circle")
  let circle = @lib.circle([
    @lib.attr("cx", "50"),
    @lib.attr("cy", "50"),
    @lib.attr("r", "25"),
    @lib.attr("fill", "red"),
  ])
  let svg_elem = @lib.svg(
    [
      @lib.attr("width", "100"),
      @lib.attr("height", "100"),
      @lib.attr("xmlns", "http://www.w3.org/2000/svg"),
    ],
    [circle],
  )
  let svg_string = @lib.to_string(svg_elem)
  println(svg_string)
  println("")

  // Test 2: Line rendering
  println("Test 2: Line element")
  let line = @lib.svg_line([
    @lib.attr("x1", "0"),
    @lib.attr("y1", "0"),
    @lib.attr("x2", "100"),
    @lib.attr("y2", "100"),
    @lib.stroke_attr("#000000"),
    @lib.stroke_width_attr("2"),
    @lib.fill_none(),
  ])
  println(@lib.to_string(line))
  println("")

  // Test 3: Group with multiple elements
  println("Test 3: Group with multiple shapes")
  let circle1 = @lib.circle([
    @lib.attr("cx", "30"),
    @lib.attr("cy", "30"),
    @lib.attr("r", "20"),
    @lib.fill_attr("blue"),
  ])
  let circle2 = @lib.circle([
    @lib.attr("cx", "70"),
    @lib.attr("cy", "30"),
    @lib.attr("r", "20"),
    @lib.fill_attr("green"),
  ])
  let circle3 = @lib.circle([
    @lib.attr("cx", "50"),
    @lib.attr("cy", "70"),
    @lib.attr("r", "20"),
    @lib.fill_attr("yellow"),
  ])
  let group = @lib.g([@lib.class_attr("venn")], [circle1, circle2, circle3])
  println(@lib.to_string(group))
  println("")

  // Test 4: Text with rotation
  println("Test 4: Text with rotation")
  let text_45 = @lib.text_elem(
    [
      @lib.attr("x", "50"),
      @lib.attr("y", "50"),
      @lib.attr("fill", "black"),
      @lib.attr("font-size", "16"),
      @lib.style_attr("transform-origin: 50px 50px; transform: rotate(-45deg);"),
    ],
    "Rotated -45°",
  )
  println(@lib.to_string(text_45))
  let text_90 = @lib.text_elem(
    [
      @lib.attr("x", "50"),
      @lib.attr("y", "70"),
      @lib.attr("fill", "blue"),
      @lib.attr("font-size", "16"),
      @lib.style_attr("transform-origin: 50px 70px; transform: rotate(-90deg);"),
    ],
    "Rotated -90°",
  )
  println(@lib.to_string(text_90))
  let text_180 = @lib.text_elem(
    [
      @lib.attr("x", "50"),
      @lib.attr("y", "90"),
      @lib.attr("fill", "green"),
      @lib.attr("font-size", "16"),
      @lib.style_attr(
        "transform-origin: 50px 90px; transform: rotate(-180deg);",
      ),
    ],
    "Rotated -180°",
  )
  println(@lib.to_string(text_180))
  println("")

  // Test 5: Polygon
  println("Test 5: Polygon")
  let polygon = @lib.polygon([
    @lib.attr("points", "50,10 90,90 10,90"),
    @lib.fill_attr("orange"),
    @lib.stroke_attr("black"),
    @lib.stroke_width_attr("2"),
  ])
  println(@lib.to_string(polygon))
  println("")

  // Test 6: Polyline
  println("Test 6: Polyline")
  let polyline = @lib.polyline([
    @lib.attr("points", "10,50 30,20 50,50 70,20 90,50"),
    @lib.stroke_attr("purple"),
    @lib.stroke_width_attr("3"),
    @lib.fill_none(),
  ])
  println(@lib.to_string(polyline))
  println("")

  // Test 7: Render options demonstration
  println("Test 7: Coordinate transformation")
  let opts = @lib.RenderOptions::with_size(800.0, 600.0)
  let x = opts.transform_x(100.0)
  let y = opts.transform_y(100.0)
  println("Original: (100, 100)")
  println(
    "Transformed with 800x600 canvas: (" +
    x.to_string() +
    ", " +
    y.to_string() +
    ")",
  )
  println("")

  // Test 8: Color conversion
  println("Test 8: Color conversion")
  println("Pen color 0 (default): " + @lib.to_svg_color(0))
  println("Pen color 1 (cyan): " + @lib.to_svg_color(1))
  println("Pen color 2 (white): " + @lib.to_svg_color(2))
  println("Pen color 4 (yellow): " + @lib.to_svg_color(4))
  println("Pen color 6 (blue): " + @lib.to_svg_color(6))
  println("")

  // Test 9: BoundingBox
  println("Test 9: BoundingBox operations")
  let bbox = @lib.BoundingBox::new()
  let bbox2 = bbox.expand(10.0, 20.0).expand(100.0, 150.0)
  println("After expanding to (10,20) and (100,150):")
  println("  width: " + bbox2.width().to_string())
  println("  height: " + bbox2.height().to_string())
  println("")
  println("=== Demo Complete ===")
}
