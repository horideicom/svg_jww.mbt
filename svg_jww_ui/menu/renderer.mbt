///|
/// Menu Renderer - Render menu items to VNode

///|
/// Render a single menu item
pub fn render_menu_item(
  item : MenuItem,
  handlers : Array[(String, @luna.EventHandler[Unit])],
) -> @luna.Node[Unit, String] {
  match item.kind {
    Button => {
      let handler = find_handler(item.id, handlers)
      @luna.h(
        "button",
        [
          ("class", @luna.attr_static(@styles.button())),
          ("title", @luna.attr_static(item.tooltip)),
          ("onClick", @luna.attr_handler(handler)),
        ],
        [@luna.text(item.label)],
      )
    }
    Toggle(active) => {
      let handler = find_handler(item.id, handlers)
      let base = @styles.button()
      let active_style = @css.styles([
        ("background", "#0066cc"),
        ("color", "white"),
      ])
      let style = if active { @css.combine([base, active_style]) } else { base }
      @luna.h(
        "button",
        [
          ("class", @luna.attr_static(style)),
          ("title", @luna.attr_static(item.tooltip)),
          ("onClick", @luna.attr_handler(handler)),
        ],
        [@luna.text(item.label)],
      )
    }
    Separator =>
      @luna.h("span", [("class", @luna.attr_static(@styles.separator()))], [
        @luna.text("|"),
      ])
    Spacer =>
      @luna.h("div", [("class", @luna.attr_static(@styles.spacer()))], [])
    Display => {
      let style = if item.id == "logo" {
        @styles.toolbar_title()
      } else {
        @styles.info_text()
      }
      @luna.h("span", [("class", @luna.attr_static(style))], [
        @luna.text(item.label),
      ])
    }
  }
}

///|
/// Render toolbar menu from items
pub fn render_toolbar_menu(
  items : Array[MenuItem],
  handlers : Array[(String, @luna.EventHandler[Unit])],
) -> @luna.Node[Unit, String] {
  @luna.h(
    "div",
    [("class", @luna.attr_static(@styles.toolbar()))],
    items.map(fn(item) { render_menu_item(item, handlers) }),
  )
}
