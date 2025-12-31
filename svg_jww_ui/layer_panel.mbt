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
  let opacity = if layer.visible { "1.0" } else { "0.5" }
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("jww-layer-item")),
      ("data-layer-id", @luna.attr_static(layer.layer_id.to_string())),
      (
        "style",
        @luna.attr_static(
          "display: flex; align-items: center; gap: 8px; padding: 4px 8px; cursor: pointer; opacity: " +
          opacity,
        ),
      ),
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
          (
            "style",
            @luna.attr_static(
              "width: 20px; height: 20px; border: none; background: transparent; cursor: pointer; font-size: 14px;",
            ),
          ),
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
          (
            "style",
            @luna.attr_static(
              "width: 20px; height: 20px; border: none; background: transparent; cursor: pointer; font-size: 14px;",
            ),
          ),
        ],
        [@luna.text(lock_icon)],
      ),
      // Layer name
      @luna.h(
        "span",
        [
          ("class", @luna.attr_static("jww-layer-name")),
          ("style", @luna.attr_static("flex: 1; font-size: 13px;")),
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
  let layers = state_sig.get().layers
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("jww-layer-panel")),
      (
        "style",
        @luna.attr_static(
          "border: 1px solid #ccc; border-radius: 4px; overflow: hidden;",
        ),
      ),
    ],
    [
      // Header
      @luna.h(
        "div",
        [
          ("class", @luna.attr_static("jww-layer-panel-header")),
          (
            "style",
            @luna.attr_static(
              "padding: 8px 12px; background: #f5f5f5; border-bottom: 1px solid #ccc; font-weight: bold; font-size: 14px;",
            ),
          ),
        ],
        [@luna.text("Layers")],
      ),
      // Layer list
      @luna.h(
        "div",
        [
          ("class", @luna.attr_static("jww-layer-list")),
          ("style", @luna.attr_static("max-height: 300px; overflow-y: auto;")),
        ],
        layers.map(fn(layer) {
          render_layer_item(
            layer, on_toggle_visibility, on_toggle_lock, on_select_layer,
          )
        }),
      ),
      // Layer count footer
      @luna.h(
        "div",
        [
          ("class", @luna.attr_static("jww-layer-panel-footer")),
          (
            "style",
            @luna.attr_static(
              "padding: 6px 12px; background: #f5f5f5; border-top: 1px solid #ccc; font-size: 12px; color: #666;",
            ),
          ),
        ],
        [
          @luna.text_dyn(fn() {
            let layers = state_sig.get().layers
            layers.length().to_string() + " layers"
          }),
        ],
      ),
    ],
  )
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
      (
        "style",
        @luna.attr_static("border: 1px solid #ccc; border-radius: 4px;"),
      ),
    ],
    [
      // Collapsible header
      @luna.h(
        "div",
        [
          ("class", @luna.attr_static("jww-layer-panel-toggle")),
          (
            "style",
            @luna.attr_static(
              "padding: 8px 12px; background: #f5f5f5; cursor: pointer; display: flex; justify-content: space-between; align-items: center;",
            ),
          ),
          ("onClick", @luna.attr_handler(on_toggle_panel)),
        ],
        [
          @luna.h(
            "span",
            [
              (
                "style",
                @luna.attr_static("font-weight: bold; font-size: 14px;"),
              ),
            ],
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
