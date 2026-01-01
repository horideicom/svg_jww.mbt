///|
/// svg_jww_ui - UI Components for JWW SVG Viewer
/// Uses luna for reactive UI with Signal-based state management

///|
/// Viewport state for pan and zoom
pub struct Viewport {
  scale : Double
  offset_x : Double
  offset_y : Double
  width : Double
  height : Double
}

///|
/// Create default viewport
pub fn Viewport::new() -> Viewport {
  { scale: 1.0, offset_x: 0.0, offset_y: 0.0, width: 800.0, height: 600.0 }
}

///|
/// Floating panel position and state
pub struct PanelState {
  x : Double
  y : Double
  collapsed : Bool
}

///|
/// Create default panel state (positioned at top-right)
pub fn PanelState::new() -> PanelState {
  { x: 10.0, y: 10.0, collapsed: false }
}

///|
/// Drag state for panel movement
pub struct DragState {
  is_dragging : Bool
  start_x : Double
  start_y : Double
  panel_start_x : Double
  panel_start_y : Double
}

///|
/// Create idle drag state
pub fn DragState::new() -> DragState {
  { is_dragging: false, start_x: 0.0, start_y: 0.0, panel_start_x: 0.0, panel_start_y: 0.0 }
}

///|
/// Layer visibility state
pub struct LayerState {
  layer_id : Int
  name : String
  visible : Bool
  locked : Bool
}

///|
/// Create default layer state
pub fn LayerState::new(id : Int, name : String) -> LayerState {
  { layer_id: id, name, visible: true, locked: false }
}

///|
/// Selection state
pub struct Selection {
  selected_ids : Array[String]
  hovered_id : String
}

///|
/// Create empty selection
pub fn Selection::new() -> Selection {
  { selected_ids: [], hovered_id: "" }
}

///|
/// Application state
pub struct AppState {
  viewport : Viewport
  panel : PanelState
  drag : DragState
  layers : Array[LayerState]
  selection : Selection
  background_color : String
  show_grid : Bool
  show_ruler : Bool
}

///|
/// Create default app state
pub fn AppState::new() -> AppState {
  let layers = [
    LayerState::new(0, "Layer 0"),
    LayerState::new(1, "Layer 1"),
    LayerState::new(2, "Layer 2"),
  ]
  {
    viewport: Viewport::new(),
    panel: PanelState::new(),
    drag: DragState::new(),
    layers,
    selection: Selection::new(),
    background_color: "#ffffff",
    show_grid: false,
    show_ruler: false,
  }
}

///|
/// Zoom in by factor
pub fn Viewport::zoom_in(self : Viewport, factor : Double) -> Viewport {
  let new_scale = self.scale * factor
  // Adjust offset to zoom towards center
  let center_x = self.width / 2.0
  let center_y = self.height / 2.0
  let scale_ratio = new_scale / self.scale
  let new_offset_x = center_x - (center_x - self.offset_x) * scale_ratio
  let new_offset_y = center_y - (center_y - self.offset_y) * scale_ratio
  {
    scale: new_scale,
    offset_x: new_offset_x,
    offset_y: new_offset_y,
    width: self.width,
    height: self.height,
  }
}

///|
/// Helper function for min of two doubles
fn double_min(a : Double, b : Double) -> Double {
  if a < b {
    a
  } else {
    b
  }
}

///|
/// Helper function for max of two doubles
fn double_max(a : Double, b : Double) -> Double {
  if a > b {
    a
  } else {
    b
  }
}

///|
/// Zoom out by factor
pub fn Viewport::zoom_out(self : Viewport, factor : Double) -> Viewport {
  Viewport::zoom_in(self, 1.0 / factor)
}

///|
/// Pan viewport
pub fn Viewport::pan(self : Viewport, dx : Double, dy : Double) -> Viewport {
  {
    scale: self.scale,
    offset_x: self.offset_x + dx,
    offset_y: self.offset_y + dy,
    width: self.width,
    height: self.height,
  }
}

///|
/// Reset viewport to default
pub fn Viewport::reset(self : Viewport) -> Viewport {
  {
    scale: 1.0,
    offset_x: 0.0,
    offset_y: 0.0,
    width: self.width,
    height: self.height,
  }
}

///|
/// Fit to content (given bounds)
pub fn Viewport::fit_to(
  self : Viewport,
  content_width : Double,
  content_height : Double,
) -> Viewport {
  let padding = 20.0
  let available_width = self.width - padding * 2.0
  let available_height = self.height - padding * 2.0
  let scale_x = if content_width > 0.0 {
    available_width / content_width
  } else {
    1.0
  }
  let scale_y = if content_height > 0.0 {
    available_height / content_height
  } else {
    1.0
  }
  let min_scale = double_min(scale_x, scale_y)
  let new_scale = double_max(double_min(min_scale, 2.0), 0.1)
  {
    scale: new_scale,
    offset_x: padding,
    offset_y: padding,
    width: self.width,
    height: self.height,
  }
}

///|
/// Toggle layer visibility
pub fn LayerState::toggle(self : LayerState) -> LayerState {
  {
    layer_id: self.layer_id,
    name: self.name,
    visible: !self.visible,
    locked: self.locked,
  }
}

///|
/// Toggle layer lock
pub fn LayerState::toggle_lock(self : LayerState) -> LayerState {
  {
    layer_id: self.layer_id,
    name: self.name,
    visible: self.visible,
    locked: !self.locked,
  }
}

///|
/// Check if entity ID is selected
pub fn Selection::is_selected(self : Selection, id : String) -> Bool {
  let mut result = false
  for eid in self.selected_ids {
    if eid == id {
      result = true
      break
    }
  }
  result
}

///|
/// Add entity to selection
pub fn Selection::add(self : Selection, id : String) -> Selection {
  if self.is_selected(id) {
    self
  } else {
    // Build new array with id added
    let len = self.selected_ids.length()
    let new_ids = Array::make(len + 1, id)
    let mut i = 0
    for eid in self.selected_ids {
      new_ids[i] = eid
      i = i + 1
    }
    new_ids[len] = id
    { selected_ids: new_ids, hovered_id: self.hovered_id }
  }
}

///|
/// Remove entity from selection
pub fn Selection::remove(self : Selection, id : String) -> Selection {
  // Count non-matching elements
  let mut count = 0
  for eid in self.selected_ids {
    if eid != id {
      count = count + 1
    }
  }
  // Build new array without the id
  let new_ids = Array::make(count, "")
  let mut i = 0
  for eid in self.selected_ids {
    if eid != id {
      new_ids[i] = eid
      i = i + 1
    }
  }
  { selected_ids: new_ids, hovered_id: self.hovered_id }
}

///|
/// Clear selection
pub fn Selection::clear(self : Selection) -> Selection {
  { selected_ids: [], hovered_id: self.hovered_id }
}

///|
/// Toggle selection
pub fn Selection::toggle(self : Selection, id : String) -> Selection {
  if self.is_selected(id) {
    Selection::remove(self, id)
  } else {
    Selection::add(self, id)
  }
}

///|
/// Set hovered entity
pub fn Selection::set_hovered(self : Selection, id : String) -> Selection {
  { selected_ids: self.selected_ids, hovered_id: id }
}

///|
/// Get visible layers
pub fn AppState::visible_layers(self : AppState) -> Array[LayerState] {
  self.layers.filter(fn(l) { l.visible })
}

///|
/// Toggle panel collapsed state
pub fn PanelState::toggle(self : PanelState) -> PanelState {
  { x: self.x, y: self.y, collapsed: !self.collapsed }
}

///|
/// Start dragging panel
pub fn DragState::start(
  self : DragState,
  start_x : Double,
  start_y : Double,
  panel_x : Double,
  panel_y : Double,
) -> DragState {
  {
    is_dragging: true,
    start_x: start_x,
    start_y: start_y,
    panel_start_x: panel_x,
    panel_start_y: panel_y,
  }
}

///|
/// Update panel position during drag
pub fn DragState::update(
  self : DragState,
  current_x : Double,
  current_y : Double,
) -> (Double, Double) {
  if self.is_dragging {
    let dx = current_x - self.start_x
    let dy = current_y - self.start_y
    let new_x = self.panel_start_x + dx
    let new_y = self.panel_start_y + dy
    (new_x, new_y)
  } else {
    (0.0, 0.0)
  }
}

///|
/// Stop dragging
pub fn DragState::stop(self : DragState) -> DragState {
  {
    is_dragging: false,
    start_x: self.start_x,
    start_y: self.start_y,
    panel_start_x: self.panel_start_x,
    panel_start_y: self.panel_start_y,
  }
}
