import { render_app_html } from 'svg-jww-viewer-mbt';

// Sample SVG content for demo
function demoSVG() {
  return `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 300" width="400" height="300">
  <rect x="0" y="0" width="400" height="300" fill="white"/>
  <g stroke="#e0e0e0" stroke-width="1">
    <line x1="0" y1="0" x2="400" y2="0"/>
    <line x1="0" y1="50" x2="400" y2="50"/>
    <line x1="0" y1="100" x2="400" y2="100"/>
    <line x1="0" y1="150" x2="400" y2="150"/>
    <line x1="0" y1="200" x2="400" y2="200"/>
    <line x1="0" y1="250" x2="400" y2="250"/>
    <line x1="0" y1="0" x2="0" y2="300"/>
    <line x1="50" y1="0" x2="50" y2="300"/>
    <line x1="100" y1="0" x2="100" y2="300"/>
    <line x1="150" y1="0" x2="150" y2="300"/>
    <line x1="200" y1="0" x2="200" y2="300"/>
    <line x1="250" y1="0" x2="250" y2="300"/>
    <line x1="300" y1="0" x2="300" y2="300"/>
    <line x1="350" y1="0" x2="350" y2="300"/>
    <line x1="400" y1="0" x2="400" y2="300"/>
  </g>
  <circle cx="200" cy="150" r="50" fill="none" stroke="#2563eb" stroke-width="2"/>
  <circle cx="200" cy="150" r="5" fill="#2563eb"/>
  <text x="200" y="250" text-anchor="middle" font-size="14" fill="#666">SVG JWW Viewer Demo</text>
</svg>`;
}

// Create default AppState (matches MoonBit AppState::new())
function createDefaultAppState() {
  return {
    viewport: {
      scale: 1.0,
      offset_x: 0.0,
      offset_y: 0.0,
      width: 800.0,
      height: 600.0,
    },
    layers: [
      { layer_id: 0, name: "Layer 0", visible: true, locked: false },
      { layer_id: 1, name: "Layer 1", visible: true, locked: false },
      { layer_id: 2, name: "Layer 2", visible: true, locked: false },
    ],
    selection: {
      selected_ids: [],
      hovered_id: "",
    },
    background_color: "#ffffff",
    show_grid: false,
    show_ruler: false,
  };
}

// Initialize app
const app = document.getElementById('app');
if (app) {
  const appState = createDefaultAppState();
  const svgContent = demoSVG();
  app.innerHTML = render_app_html(appState, svgContent);
  console.log('SVG JWW Viewer initialized');
}
