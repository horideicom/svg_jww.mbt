///|
/// Layer Panel Component - Displays and controls layer visibility

///|
/// Render single layer item
fn render_layer_item(
  layer : LayerState,
  on_toggle_visibility : @luna.EventHandler[Unit],
  on_toggle_lock : @luna.EventHandler[Unit],
  on_select : @luna.EventHandler[Unit],
) -> @luna.Node[Unit] {
  let visibility_icon = if layer.visible { "👁" } else { "○" }
  let lock_icon = if layer.locked { "🔒" } else { "🔓" }
  let opacity_value = if layer.visible { "1.0" } else { "0.5" }
  let opacity_style = @css.styles([("opacity", opacity_value)])
  let item_style = @css.combine([@styles.layer_item(), opacity_style])
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("jww-layer-item")),
      ("data-layer-id", @luna.attr_static(layer.layer_id.to_string())),
      ("class", @luna.attr_static(item_style)),
      ("onClick", @luna.attr_handler(on_select)),
    ],
    [
      // Visibility toggle
      @luna.h(
        "button",
        [
          ("class", @luna.attr_static("jww-layer-visibility")),
          ("title", @luna.attr_static("Toggle Visibility")),
          ("onClick", @luna.attr_handler(on_toggle_visibility)),
          ("class", @luna.attr_static(@styles.icon_button())),
        ],
        [@luna.text(visibility_icon)],
      ),
      // Lock toggle
      @luna.h(
        "button",
        [
          ("class", @luna.attr_static("jww-layer-lock")),
          ("title", @luna.attr_static("Toggle Lock")),
          ("onClick", @luna.attr_handler(on_toggle_lock)),
          ("class", @luna.attr_static(@styles.icon_button())),
        ],
        [@luna.text(lock_icon)],
      ),
      // Layer name
      @luna.h(
        "span",
        [
          ("class", @luna.attr_static("jww-layer-name")),
          ("class", @luna.attr_static(@styles.layer_name())),
        ],
        [@luna.text(layer.name)],
      ),
    ],
  )
}

///|
/// Render layer panel
pub fn render_layer_panel(
  state_sig : @signal.Signal[AppState],
  on_toggle_visibility : @luna.EventHandler[Unit],
  on_toggle_lock : @luna.EventHandler[Unit],
  on_select_layer : @luna.EventHandler[Unit],
) -> @luna.Node[Unit] {
  let config = @panel.make_panel_config("Layers")
  let layers = state_sig.get().layers
  let layer_list = @luna.h(
    "div",
    [
      ("class", @luna.attr_static("jww-layer-list")),
      ("class", @luna.attr_static(@styles.layer_list())),
    ],
    layers.map(fn(layer) {
      render_layer_item(
        layer, on_toggle_visibility, on_toggle_lock, on_select_layer,
      )
    }),
  )
  let footer = @luna.text_dyn(fn() {
    let layers = state_sig.get().layers
    layers.length().to_string() + " layers"
  })
  @panel.render_panel(config, layer_list, Some(footer))
}

///|
/// Render layer panel with collapsible toggle
pub fn render_collapsible_layer_panel(
  state_sig : @signal.Signal[AppState],
  on_toggle_visibility : @luna.EventHandler[Unit],
  on_toggle_lock : @luna.EventHandler[Unit],
  on_select_layer : @luna.EventHandler[Unit],
  on_toggle_panel : @luna.EventHandler[Unit],
) -> @luna.Node[Unit] {
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("jww-layer-panel-wrapper")),
      ("class", @luna.attr_static(@styles.panel_container())),
    ],
    [
      // Collapsible header
      @luna.h(
        "div",
        [
          ("class", @luna.attr_static("jww-layer-panel-toggle")),
          ("class", @luna.attr_static(@styles.panel_header())),
          (
            "style",
            @luna.attr_static(
              "cursor: pointer; display: flex; justify-content: space-between; align-items: center;",
            ),
          ),
          ("onClick", @luna.attr_handler(on_toggle_panel)),
        ],
        [
          @luna.h(
            "span",
            [("class", @luna.attr_static(@styles.panel_header()))],
            [@luna.text("Layers")],
          ),
          @luna.h("span", [("style", @luna.attr_static("font-size: 12px;"))], [
            @luna.text("▼"),
          ]), // Always expanded for now
        ],
      ),
      // Content (always shown for now)
      @luna.h("div", [], [
        render_layer_panel(
          state_sig, on_toggle_visibility, on_toggle_lock, on_select_layer,
        ),
      ]),
    ],
  )
}
