///|
/// Hydration module for svg_jww viewer
/// Provides client-side hydration for the viewer app using luna framework

///|
/// Hydrate the viewer app with event handlers
/// This function is called by the luna loader to attach event handlers
pub fn hydrate(el : @luna_dom.js_dom.Element, _state : @js.Any, _id : String) -> Unit {
  // Use island-based hydration
  @luna_dom.hydrate_island(el, _state, _id, fn(ctx) {
    // Create signals for toggle states
    let grid_sig = ctx.signal_bool("show_grid", false)
    let ruler_sig = ctx.signal_bool("show_ruler", false)
    let print_area_sig = ctx.signal_bool("show_print_area", false)

    // Bind actions from DOM (data-action-* attributes)
    ctx.bind_actions(fn(action) {
      match action {
        "toggle_grid" => { let _ = grid_sig }
        "toggle_ruler" => { let _ = ruler_sig }
        "toggle_print_area" => { let _ = print_area_sig }
        "zoom_in" => ()
        "zoom_out" => ()
        "fit" => ()
        "reset" => ()
        _ => ()
      }
    })

    // Update UI when signals change
    // Note: The actual DOM manipulation happens through the hydration system
  })
}

///|
/// Simple hydrate function for direct usage (without island context)
pub fn hydrate_simple(el : @luna_dom.js_dom.Element, _state : @js.Any) -> Unit {
  // Bind actions from DOM using client.bind_actions_from_dom
  @luna_dom.client.bind_actions_from_dom(el, fn(action) {
    // Handle actions
    let _ = action
    // Trigger re-render if needed
    // In a real implementation, this would update the DOM
  })
}
