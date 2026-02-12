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
  on_toggle_grid : @luna.EventHandler[Unit],
  on_toggle_ruler : @luna.EventHandler[Unit],
  on_toggle_print_area : @luna.EventHandler[Unit],
) -> @luna.Node[Unit, String] {
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
            on_toggle_grid, on_toggle_ruler, on_toggle_print_area,
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
  on_toggle_grid : @luna.EventHandler[Unit],
  on_toggle_ruler : @luna.EventHandler[Unit],
  on_toggle_print_area : @luna.EventHandler[Unit],
) -> @luna.Node[Unit, String] {
  // Build handlers array
  let handlers = [
    ("zoom_in", on_zoom_in),
    ("zoom_out", on_zoom_out),
    ("fit", on_fit),
    ("reset", on_reset),
    ("toggle_grid", on_toggle_grid),
    ("toggle_ruler", on_toggle_ruler),
    ("toggle_print_area", on_toggle_print_area),
  ]

  // Get menu items with current scale and toggle states
  let state = state_sig.get()
  let scale_percent = (state.viewport.scale * 100.0).to_int()
  let items = @menu.toolbar_items_with_toggles(
    scale_percent,
    state.show_grid,
    state.show_ruler,
    state.show_print_area,
  )

  // Render toolbar menu
  @menu.render_toolbar_menu(items, handlers)
}

///|
/// Info panel showing document info (refactored to use panel component)
pub fn render_info_panel(
  state_sig : @signal.Signal[AppState],
) -> @luna.Node[Unit, String] {
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
      // Document section
      render_section_header("Document"),
      @luna.h("div", [], [
        @luna.text("Version:"),
        @luna.text_dyn(fn() {
          match state_sig.get().document_info {
            Some(info) => info.version
            None => "-"
          }
        }),
      ]),
      @luna.h("div", [], [
        @luna.text("Paper:"),
        @luna.text_dyn(fn() {
          match state_sig.get().document_info {
            Some(info) => info.paper_size
            None => "-"
          }
        }),
      ]),
      @luna.h("div", [], [
        @luna.text("Size:"),
        @luna.text_dyn(fn() {
          match state_sig.get().document_info {
            Some(info) => {
              let w = info.drawing_width.to_int().to_string()
              let h = info.drawing_height.to_int().to_string()
              if w == "0" && h == "0" {
                "-"
              } else {
                w + "x" + h
              }
            }
            None => "-"
          }
        }),
      ]),
      @luna.h("div", [], [
        @luna.text("Memo:"),
        @luna.text_dyn(fn() {
          match state_sig.get().document_info {
            Some(info) => if info.memo == "" { "-" } else { info.memo }
            None => "-"
          }
        }),
      ]),
      // Viewport section
      render_section_header("Viewport"),
      @luna.h("div", [], [
        @luna.text("Size:"),
        @luna.text_dyn(fn() {
          let vp = state_sig.get().viewport
          vp.width.to_int().to_string() + "x" + vp.height.to_int().to_string()
        }),
      ]),
      @luna.h("div", [], [
        @luna.text("Scale:"),
        @luna.text_dyn(fn() {
          let vp = state_sig.get().viewport
          (vp.scale * 100.0).to_int().to_string() + "%"
        }),
      ]),
      // Entities section
      render_section_header("Entities"),
      @luna.h("div", [], [
        @luna.text("Lines:"),
        @luna.text_dyn(fn() {
          match state_sig.get().document_info {
            Some(info) => info.line_count.to_string()
            None => "-"
          }
        }),
      ]),
      @luna.h("div", [], [
        @luna.text("Arcs:"),
        @luna.text_dyn(fn() {
          match state_sig.get().document_info {
            Some(info) => info.arc_count.to_string()
            None => "-"
          }
        }),
      ]),
      @luna.h("div", [], [
        @luna.text("Points:"),
        @luna.text_dyn(fn() {
          match state_sig.get().document_info {
            Some(info) => info.point_count.to_string()
            None => "-"
          }
        }),
      ]),
      @luna.h("div", [], [
        @luna.text("Texts:"),
        @luna.text_dyn(fn() {
          match state_sig.get().document_info {
            Some(info) => info.text_count.to_string()
            None => "-"
          }
        }),
      ]),
      @luna.h("div", [], [
        @luna.text("Solids:"),
        @luna.text_dyn(fn() {
          match state_sig.get().document_info {
            Some(info) => info.solid_count.to_string()
            None => "-"
          }
        }),
      ]),
      @luna.h("div", [], [
        @luna.text("Blocks:"),
        @luna.text_dyn(fn() {
          match state_sig.get().document_info {
            Some(info) => info.block_count.to_string()
            None => "-"
          }
        }),
      ]),
      @luna.h("div", [], [
        @luna.text("Polylines:"),
        @luna.text_dyn(fn() {
          match state_sig.get().document_info {
            Some(info) => info.polyline_count.to_string()
            None => "-"
          }
        }),
      ]),
      @luna.h("div", [], [
        @luna.text("Images:"),
        @luna.text_dyn(fn() {
          match state_sig.get().document_info {
            Some(info) => info.image_count.to_string()
            None => "-"
          }
        }),
      ]),
      // Print Settings section
      render_section_header("Print Settings"),
      @luna.h("div", [], [
        @luna.text("Origin:"),
        @luna.text_dyn(fn() {
          match state_sig.get().document_info {
            Some(info) => {
              let x = info.print_origin_x.to_int().to_string()
              let y = info.print_origin_y.to_int().to_string()
              "(" + x + ", " + y + ")"
            }
            None => "-"
          }
        }),
      ]),
      @luna.h("div", [], [
        @luna.text("Scale:"),
        @luna.text_dyn(fn() {
          match state_sig.get().document_info {
            Some(info) => info.print_scale.to_string()
            None => "-"
          }
        }),
      ]),
      @luna.h("div", [], [
        @luna.text("Rotation:"),
        @luna.text_dyn(fn() {
          match state_sig.get().document_info {
            Some(info) => info.print_rotation.to_string()
            None => "-"
          }
        }),
      ]),
      // Layers section
      render_section_header("Layers"),
      @luna.h("div", [], [
        @luna.text("Groups:"),
        @luna.text_dyn(fn() {
          match state_sig.get().document_info {
            Some(info) => info.layer_group_count.to_string()
            None => "-"
          }
        }),
      ]),
      @luna.h("div", [], [
        @luna.text("Layers:"),
        @luna.text_dyn(fn() {
          match state_sig.get().document_info {
            Some(info) => info.layer_count.to_string()
            None => "-"
          }
        }),
      ]),
      @luna.h("div", [], [
        @luna.text("Embed imgs:"),
        @luna.text_dyn(fn() {
          match state_sig.get().document_info {
            Some(info) => info.embedded_image_count.to_string()
            None => "-"
          }
        }),
      ]),
    ],
  )
  let footer = @luna.text_dyn(fn() {
    let state = state_sig.get()
    let visible = state.layers.filter(fn(l) { l.visible }).length()
    visible.to_string() + " / " + state.layers.length().to_string() + " visible"
  })
  @panel.render_panel(config, content, Some(footer))
}

///|
/// Render a section header in the info panel
fn render_section_header(title : String) -> @luna.Node[Unit, String] {
  @luna.h(
    "div",
    [
      (
        "style",
        @luna.attr_static(
          "margin-top: 8px; margin-bottom: 2px; font-weight: bold; color: #333; font-size: 11px; text-transform: uppercase; border-bottom: 1px solid #ddd; padding-bottom: 2px;",
        ),
      ),
    ],
    [@luna.text(title)],
  )
}

///|
/// Render full page HTML for SSR
pub fn render_app_html(app_state : AppState, svg_content : String) -> String {
  let state_sig = @signal.signal(app_state)
  let svg_sig = @signal.signal(svg_content)

  // Create noop event handler for SSR
  let noop = @luna.handler(fn(_x) { () })
  let vnode = render_app(
    state_sig, svg_sig, noop, noop, noop, noop, noop, noop, noop, noop, noop, noop,
    noop, noop,
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
