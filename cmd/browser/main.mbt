///|
/// JWW Viewer - Browser Entry Point
/// Initializes the viewer application

// Sample SVG content for demo
fn demo_svg() -> String {
  let sb = StringBuilder::new()
  sb.write_string("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
  sb.write_string(
    "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 400 300\" width=\"400\" height=\"300\">",
  )
  sb.write_string(
    "<rect x=\"0\" y=\"0\" width=\"400\" height=\"300\" fill=\"white\"/>",
  )
  // Sample grid
  sb.write_string("<g stroke=\"#e0e0e0\" stroke-width=\"1\">")
  for y = 0; y < 300; y = y + 50 {
    sb.write_string(
      "<line x1=\"0\" y1=\"" +
      y.to_string() +
      "\" x2=\"400\" y2=\"" +
      y.to_string() +
      "\"/>",
    )
  }
  for x = 0; x < 400; x = x + 50 {
    sb.write_string(
      "<line x1=\"" +
      x.to_string() +
      "\" y1=\"0\" x2=\"" +
      x.to_string() +
      "\" y2=\"300\"/>",
    )
  }
  sb.write_string("</g>")
  // Sample circle
  sb.write_string(
    "<circle cx=\"200\" cy=\"150\" r=\"50\" fill=\"none\" stroke=\"#2563eb\" stroke-width=\"2\"/>",
  )
  sb.write_string("<circle cx=\"200\" cy=\"150\" r=\"5\" fill=\"#2563eb\"/>")
  // Sample text
  sb.write_string(
    "<text x=\"200\" y=\"250\" text-anchor=\"middle\" font-size=\"14\" fill=\"#666\">JWW Viewer Demo</text>",
  )
  sb.write_string("</svg>")
  sb.to_string()
}

// Get DOM element

///|
extern "js" fn document_get_element_by_id(id : String) -> @js.Any =
  #| document.getElementById(...)

// Set inner HTML

///|
extern "js" fn element_set_inner_html(element : @js.Any, html : String) -> Unit =
  #| (el, html) => el.innerHTML = html

// Console log

///|
extern "js" fn console_log(msg : String) -> Unit =
  #| console.log(...)

// Main entry point

///|
fn main {
  let app_state = @ui.AppState::new()
  let svg_content = demo_svg()

  // Render initial HTML
  let html = @ui.render_app_html(app_state, svg_content)

  // Get app element and set HTML
  let app_element = document_get_element_by_id("app")
  element_set_inner_html(app_element, html)

  // Log initialization
  console_log("JWW Viewer initialized")
}
