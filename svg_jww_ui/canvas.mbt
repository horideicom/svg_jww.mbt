///|
/// Canvas Component - Displays SVG content with pan/zoom support

///|
/// Render canvas with SVG content
/// Takes signals for app state and document SVG string
pub fn render_canvas(
  state_sig : @signal.Signal[AppState],
  svg_content_sig : @signal.Signal[String],
  on_pan : @luna.EventHandler[Unit],
  on_wheel : @luna.EventHandler[Unit],
) -> @luna.Node[Unit, String] {
  let svg_content = svg_content_sig.get()
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("jww-canvas")),
      ("style", @luna.attr_static("position: relative; overflow: hidden;")),
    ],
    [
      // SVG container with transform
      @luna.h(
        "div",
        [
          ("class", @luna.attr_static("jww-canvas-content")),
          (
            "style",
            @luna.attr_dynamic(fn() {
              let vp = state_sig.get().viewport
              "transform: translate(" +
              vp.offset_x.to_string() +
              "px, " +
              vp.offset_y.to_string() +
              "px) scale(" +
              vp.scale.to_string() +
              "); transform-origin: 0 0;"
            }),
          ),
          ("onWheel", @luna.attr_handler(on_wheel)),
        ],
        [
          @luna.h(
            "div",
            [
              ("class", @luna.attr_static("jww-svg-wrapper")),
              ("style", @luna.attr_static("pointer-events: none;")),
            ],
            [@luna.raw_html(svg_content)],
          ),
        ],
      ),
      // Pan overlay for mouse drag
      @luna.h(
        "div",
        [
          ("class", @luna.attr_static("jww-pan-overlay")),
          (
            "style",
            @luna.attr_static("position: absolute; inset: 0; cursor: grab;"),
          ),
          ("onMouseDown", @luna.attr_handler(on_pan)),
        ],
        [],
      ),
    ],
  )
}

///|
/// Simple SVG renderer without interactivity
/// For static display or SSR
pub fn render_static_svg(svg_content : String) -> @luna.Node[Unit, String] {
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("jww-static-svg")),
      ("style", @luna.attr_static("display: inline-block;")),
    ],
    [@luna.raw_html(svg_content)],
  )
}

///|
/// Render canvas with zoom controls overlay
pub fn render_canvas_with_controls(
  state_sig : @signal.Signal[AppState],
  svg_content_sig : @signal.Signal[String],
  on_pan : @luna.EventHandler[Unit],
  on_wheel : @luna.EventHandler[Unit],
  on_zoom_in : @luna.EventHandler[Unit],
  on_zoom_out : @luna.EventHandler[Unit],
  on_fit : @luna.EventHandler[Unit],
  on_reset : @luna.EventHandler[Unit],
) -> @luna.Node[Unit, String] {
  @luna.h(
    "div",
    [
      ("class", @luna.attr_static("jww-viewer")),
      ("style", @luna.attr_static("position: relative;")),
    ],
    [
      // Main canvas
      render_canvas(state_sig, svg_content_sig, on_pan, on_wheel),
      // Zoom controls
      @luna.h(
        "div",
        [
          ("class", @luna.attr_static("jww-zoom-controls")),
          (
            "style",
            @luna.attr_static(
              "position: absolute; bottom: 16px; right: 16px; display: flex; flex-direction: column; gap: 4px;",
            ),
          ),
        ],
        [
          @luna.h(
            "button",
            [
              ("class", @luna.attr_static("jww-zoom-btn")),
              ("title", @luna.attr_static("Zoom In")),
              ("onClick", @luna.attr_handler(on_zoom_in)),
              (
                "style",
                @luna.attr_static(
                  "width: 32px; height: 32px; border: 1px solid #ccc; background: white; cursor: pointer; border-radius: 4px;",
                ),
              ),
            ],
            [@luna.text("+")],
          ),
          @luna.h(
            "div",
            [
              ("class", @luna.attr_static("jww-zoom-level")),
              (
                "style",
                @luna.attr_static(
                  "text-align: center; font-size: 12px; color: #666; min-width: 50px;",
                ),
              ),
            ],
            [
              @luna.text_dyn(fn() {
                let vp = state_sig.get().viewport
                (vp.scale * 100.0).to_int().to_string() + "%"
              }),
            ],
          ),
          @luna.h(
            "button",
            [
              ("class", @luna.attr_static("jww-zoom-btn")),
              ("title", @luna.attr_static("Zoom Out")),
              ("onClick", @luna.attr_handler(on_zoom_out)),
              (
                "style",
                @luna.attr_static(
                  "width: 32px; height: 32px; border: 1px solid #ccc; background: white; cursor: pointer; border-radius: 4px;",
                ),
              ),
            ],
            [@luna.text("-")],
          ),
          @luna.h(
            "div",
            [("style", @luna.attr_static("height: 1px; background: #ccc;"))],
            [],
          ),
          @luna.h(
            "button",
            [
              ("class", @luna.attr_static("jww-zoom-btn")),
              ("title", @luna.attr_static("Fit to View")),
              ("onClick", @luna.attr_handler(on_fit)),
              (
                "style",
                @luna.attr_static(
                  "width: 32px; height: 32px; border: 1px solid #ccc; background: white; cursor: pointer; border-radius: 4px;",
                ),
              ),
            ],
            [@luna.text("⛶")],
          ),
          @luna.h(
            "button",
            [
              ("class", @luna.attr_static("jww-zoom-btn")),
              ("title", @luna.attr_static("Reset View")),
              ("onClick", @luna.attr_handler(on_reset)),
              (
                "style",
                @luna.attr_static(
                  "width: 32px; height: 32px; border: 1px solid #ccc; background: white; cursor: pointer; border-radius: 4px;",
                ),
              ),
            ],
            [@luna.text("⟲")],
          ),
        ],
      ),
    ],
  )
}
