///|
/// Main App Component - JWW SVG Viewer Application

///|
/// Render the complete JWW viewer application
pub fn render_app(
  state_sig : @signal.Signal[AppState],
  svg_content_sig : @signal.Signal[String],
  on_zoom_in : @luna.EventHandler[Unit],
  on_zoom_out : @luna.EventHandler[Unit],
  on_fit : @luna.EventHandler[Unit],
  on_reset : @luna.EventHandler[Unit],
  on_pan : @luna.EventHandler[Unit],
  on_toggle_layer_visibility : @luna.EventHandler[Unit],
  on_toggle_layer_lock : @luna.EventHandler[Unit],
  on_select_layer : @luna.EventHandler[Unit],
  on_toggle_layer_panel : @luna.EventHandler[Unit],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("jww-viewer-app")),
      (
        "style",
        @luna.attr_dynamic(fn() {
          let state = state_sig.get()
          "display: flex; height: 100vh; background-color: " +
          state.background_color +
          ";"
        }),
      ),
    ],
    [
      // Main content area
      @luna.h(
        "div",
        [
          ("class", @luna.attr_static("jww-main-content")),
          (
            "style",
            @luna.attr_static("flex: 1; display: flex; flex-direction: column;"),
          ),
        ],
        [
          // Toolbar
          render_toolbar(
            state_sig, on_zoom_in, on_zoom_out, on_fit, on_reset, on_toggle_layer_panel,
          ),
          // Canvas area
          @luna.h(
            "div",
            [
              ("class", @luna.attr_static("jww-canvas-container")),
              (
                "style",
                @luna.attr_static(
                  "flex: 1; position: relative; overflow: hidden;",
                ),
              ),
            ],
            [
              render_canvas_with_controls(
                state_sig,
                svg_content_sig,
                on_pan,
                @luna.event_handler(), // TODO: wheel handler
                on_zoom_in,
                on_zoom_out,
                on_fit,
                on_reset,
              ),
            ],
          ),
        ],
      ),
      // Layer panel (sidebar)
      @luna.h(
        "div",
        [
          ("class", @luna.attr_static("jww-sidebar")),
          (
            "style",
            @luna.attr_static(
              "width: 200px; border-left: 1px solid #ccc; display: flex; flex-direction: column;",
            ),
          ),
        ],
        [
          render_collapsible_layer_panel(
            state_sig, on_toggle_layer_visibility, on_toggle_layer_lock, on_select_layer,
            on_toggle_layer_panel,
          ),
          // Info panel
          render_info_panel(state_sig),
        ],
      ),
    ],
  )
}

///|
/// Toolbar component (refactored to use menu package)
pub fn render_toolbar(
  state_sig : @signal.Signal[AppState],
  on_zoom_in : @luna.EventHandler[Unit],
  on_zoom_out : @luna.EventHandler[Unit],
  on_fit : @luna.EventHandler[Unit],
  on_reset : @luna.EventHandler[Unit],
  _on_toggle_layer_panel : @luna.EventHandler[Unit],
) -> @luna.Node[Unit] {
  // Build handlers array
  let handlers = [
    ("zoom_in", on_zoom_in),
    ("zoom_out", on_zoom_out),
    ("fit", on_fit),
    ("reset", on_reset),
  ]

  // Get menu items with current scale
  let state = state_sig.get()
  let scale_percent = (state.viewport.scale * 100.0).to_int()
  let items = @menu.toolbar_items(scale_percent)

  // Render toolbar menu
  @menu.render_toolbar_menu(items, handlers)
}

///|
/// Info panel showing document info (refactored to use panel component)
pub fn render_info_panel(
  state_sig : @signal.Signal[AppState],
) -> @luna.Node[Unit] {
  let config = @panel.make_panel_config("Document Info")
  let content = @luna.h(
    "div",
    [
      (
        "style",
        @luna.attr_static(
          "font-size: 12px; color: #666; display: flex; flex-direction: column; gap: 4px; padding: 8px 0;",
        ),
      ),
    ],
    [
      @luna.h("div", [], [
        @luna.text("Viewport:"),
        @luna.text_dyn(fn() {
          let vp = state_sig.get().viewport
          vp.width.to_string() + "x" + vp.height.to_string()
        }),
      ]),
      @luna.h("div", [], [
        @luna.text("Scale:"),
        @luna.text_dyn(fn() {
          let vp = state_sig.get().viewport
          (vp.scale * 100.0).to_int().to_string() + "%"
        }),
      ]),
      @luna.h("div", [], [
        @luna.text("Layers:"),
        @luna.text_dyn(fn() {
          let state = state_sig.get()
          let visible = state.layers.filter(fn(l) { l.visible }).length()
          visible.to_string() + " / " + state.layers.length().to_string()
        }),
      ]),
    ],
  )
  let footer = @luna.text_dyn(fn() {
    let layers = state_sig.get().layers
    layers.length().to_string() + " layers"
  })
  @panel.render_panel(config, content, Some(footer))
}

///|
/// Render full page HTML for SSR
pub fn render_app_html(app_state : AppState, svg_content : String) -> String {
  let state_sig = @signal.signal(app_state)
  let svg_sig = @signal.signal(svg_content)

  // Create noop event handler for SSR
  let noop = @luna.handler(fn(_x) { () })
  let vnode = render_app(
    state_sig, svg_sig, noop, noop, noop, noop, noop, noop, noop, noop, noop,
  )
  @render.render_to_string_with_hydration(vnode)
}

///|
/// Serialize state for hydration
pub fn serialize_state(state : AppState) -> String {
  let vp = state.viewport
  let sb = StringBuilder::new()
  sb.write_string("{\"viewport\":{\"scale\":")
  sb.write_string(vp.scale.to_string())
  sb.write_string(",\"offset_x\":")
  sb.write_string(vp.offset_x.to_string())
  sb.write_string(",\"offset_y\":")
  sb.write_string(vp.offset_y.to_string())
  sb.write_string(",\"width\":")
  sb.write_string(vp.width.to_string())
  sb.write_string(",")
  sb.write_string("\"height\":")
  sb.write_string(vp.height.to_string())
  sb.write_string("}}")
  sb.to_string()
}
