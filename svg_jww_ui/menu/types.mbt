///|
/// Menu Types - MenuItem type definitions

///|
/// Menu item kind
pub enum MenuItemKind {
  Button
  Toggle(Bool)
  Separator
  Spacer
  Display
}

///|
/// Menu item definition
pub struct MenuItem {
  id : String
  label : String
  tooltip : String
  kind : MenuItemKind
}

///|
/// Create a button menu item
pub fn button(
  id~ : String,
  label~ : String,
  tooltip? : String = "",
) -> MenuItem {
  { id, label, tooltip, kind: Button }
}

///|
/// Create a toggle menu item
pub fn toggle(
  id~ : String,
  label~ : String,
  active~ : Bool,
  tooltip? : String = "",
) -> MenuItem {
  { id, label, tooltip, kind: Toggle(active) }
}

///|
/// Create a separator menu item
pub fn separator() -> MenuItem {
  { id: "", label: "", tooltip: "", kind: Separator }
}

///|
/// Create a spacer menu item
pub fn spacer() -> MenuItem {
  { id: "", label: "", tooltip: "", kind: Spacer }
}

///|
/// Create a display menu item
pub fn display(id~ : String, label~ : String) -> MenuItem {
  { id, label, tooltip: "", kind: Display }
}

///|
/// Find handler by id in array
pub fn find_handler(
  id : String,
  handlers : Array[(String, @luna.EventHandler[Unit])],
) -> @luna.EventHandler[Unit] {
  let mut result = @luna.handler(fn(_x) { () })
  for pair in handlers {
    let (key, handler) = pair
    if key == id {
      result = handler
      break
    }
  }
  result
}
