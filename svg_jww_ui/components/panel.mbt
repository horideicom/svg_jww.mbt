///|
/// Panel Component - Unified panel component

///|
/// Panel configuration
pub struct PanelConfig {
  title : String
}

///|
/// Create a panel config (factory function)
pub fn make_panel_config(title : String) -> PanelConfig {
  { title, }
}

///|
/// Render a unified panel component
pub fn render_panel(
  config : PanelConfig,
  content : @luna.Node[Unit, String],
  footer : @luna.Node[Unit, String]?,
) -> @luna.Node[Unit, String] {
  let base_children = [
    @luna.h("div", [("class", @luna.attr_static(@styles.panel_header()))], [
      @luna.text(config.title),
    ]),
    @luna.h("div", [("class", @luna.attr_static(@styles.panel_content()))], [
      content,
    ]),
  ]
  let children = match footer {
    Some(f) => {
      let footer_div = @luna.h(
        "div",
        [("class", @luna.attr_static(@styles.panel_footer()))],
        [f],
      )
      [base_children[0], base_children[1], footer_div]
    }
    None => base_children
  }
  @luna.h(
    "div",
    [("class", @luna.attr_static(@styles.panel_container()))],
    children,
  )
}
