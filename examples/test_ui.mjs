import { render_app_html } from 'svg-jww-viewer';

const appState = {
  viewport: { scale: 1.0, offset_x: 0.0, offset_y: 0.0, width: 800.0, height: 600.0 },
  layers: [{ layer_id: 0, name: "Layer 0", visible: true, locked: false }],
  selection: { selected_ids: [], hovered_id: "" },
  background_color: "#ffffff",
  show_grid: false,
  show_ruler: false,
};

const svg = '<svg viewBox="0 0 400 300"><rect width="400" height="300" fill="white"/></svg>';

const html = render_app_html(appState, svg);
console.log('HTML generated:', html.length, 'chars');
console.log('Contains zoom button:', html.includes('zoom'));
console.log('Contains fit button:', html.includes('fit'));
console.log('Contains event handler:', html.includes('addEventListener'));
