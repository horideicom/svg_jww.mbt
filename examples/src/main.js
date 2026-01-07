// Main entry point for JWW viewer example

import { jww_parse } from '../../dist/svg_jww.js';
import { CoordinateTransform, JWWViewer } from './viewer.js';
import { renderFloatingPanel, setupLayerToggles, setupMobilePanelToggle, setupPanelDrag } from './panel.js';
import { setTheme, currentTheme } from './theme.js';
import { setupImageLoadDetection, renderImageList } from './image.js';

// Current JWW data state
let currentJwwData = null;
let currentFileName = null;

async function loadJWWFile(file) {
  try {
    const buffer = await file.arrayBuffer();
    const uint8Array = new Uint8Array(buffer);

    let parsed;
    try {
      parsed = jww_parse(uint8Array);
    } catch (e) {
      console.error('Error in jww_parse:', e);
      console.error('Stack:', e.stack);

      // Check if it's a panic from the parser
      if (e.message === '' && e.name === 'Error') {
        throw new Error('JWWファイルのパースに失敗しました。このファイルはサポートされていない形式か、jww_parserパッケージにバグがある可能性があります。\n\nエラー詳細: Parser panic (likely out-of-bounds access in jww_parser)');
      }
      throw new Error('JWWファイルのパースに失敗しました: ' + e.message);
    }

    // Check if parsed has required properties
    if (!parsed) {
      throw new Error('jww_parse returned undefined');
    }
    if (!parsed.svg) {
      throw new Error('parsed.svg is undefined');
    }
    if (!parsed.bounds) {
      throw new Error('parsed.bounds is undefined');
    }
    if (!parsed.layers) {
      throw new Error('parsed.layers is undefined');
    }

    // Store current data for theme switching and print
    currentJwwData = parsed;
    currentFileName = file.name;

    // Use the SVG directly from mbt
    const svgContent = parsed.svg;

    // Get bounds from parsed document
    const bounds = {
      minX: parsed.bounds.min_x,
      minY: parsed.bounds.min_y,
      maxX: parsed.bounds.max_x,
      maxY: parsed.bounds.max_y
    };

    // Create coordinate transform (JWW Y-up to SVG Y-down)
    const coordTransform = new CoordinateTransform(bounds);

    // Get layer groups from parsed document
    const layerGroups = parsed.layers.map(layer => ({
      id: layer.id,
      name: layer.name,
      entities: [],
      visible: layer.visible
    }));

    const app = document.getElementById('app');

    // Render canvas with SVG
    app.innerHTML = `
      <div id="jww-canvas" style="width: 100%; height: 100vh; position: relative; overflow: hidden; background: #000000;">
        ${svgContent}
      </div>
    `;

    // Check if SVG was rendered
    const svg = app.querySelector('svg');
    if (svg) {
      svg.style.width = '100%';
      svg.style.height = '100%';
    } else {
      console.error('SVG not found!');
    }

    // Add the panel and setup viewer
    setTimeout(() => {
      const panelHTML = renderFloatingPanel(layerGroups, currentJwwData);
      const canvas = document.getElementById('jww-canvas');
      if (canvas) {
        canvas.insertAdjacentHTML('beforeend', panelHTML);

        // Create viewer with function to get current JWW data
        const viewer = new JWWViewer(canvas, svg, bounds, coordTransform, layerGroups, () => currentJwwData);

        // Setup all controls
        setupControls(viewer);
        setupLayerToggles(viewer);
        setupMobilePanelToggle();
        setupPanelDrag();
        setupThemeControl();
        setupTextControl(viewer);
        setupDisplayControl(viewer);
        setupImageControl();
        setupPrintControl(viewer);

        // Setup image load detection
        setupImageLoadDetection();

        // Initial fit
        setTimeout(() => viewer.fit(), 100);
      }
    }, 100);

  } catch (error) {
    console.error('Error loading JWW file:', error);
    alert('Error loading JWW file: ' + error.message);
  }
}

function setupControls(viewer) {
  const zoomIn = document.getElementById('jww-zoom-in');
  const zoomOut = document.getElementById('jww-zoom-out');
  const fit = document.getElementById('jww-fit');
  const reset = document.getElementById('jww-reset');
  if (zoomIn) zoomIn.onclick = () => viewer.zoomIn();
  if (zoomOut) zoomOut.onclick = () => viewer.zoomOut();
  if (fit) fit.onclick = () => viewer.fit();
  if (reset) reset.onclick = () => viewer.reset();
}

function setupThemeControl() {
  const themeSelect = document.getElementById('jww-theme-select');
  if (themeSelect) {
    themeSelect.addEventListener('change', (e) => {
      setTheme(e.target.value);
    });
  }
}

function setupTextControl(viewer) {
  const textEnabled = document.getElementById('jww-text-enabled');
  const resetText = document.getElementById('jww-reset-text');
  const fontSizeSlider = document.getElementById('jww-font-size');

  if (textEnabled) {
    textEnabled.addEventListener('change', (e) => {
      viewer.setTextEnabled(e.target.checked);
    });
  }

  if (resetText) {
    resetText.onclick = () => {
      viewer.resetTextPositions();
    };
  }

  if (fontSizeSlider) {
    fontSizeSlider.addEventListener('input', (e) => {
      viewer.setFontSize(parseFloat(e.target.value));
    });
  }
}

function setupDisplayControl(viewer) {
  const gridBtn = document.getElementById('jww-toggle-grid');
  const rulerBtn = document.getElementById('jww-toggle-ruler');
  const printAreaBtn = document.getElementById('jww-toggle-print-area');

  if (gridBtn) {
    gridBtn.onclick = () => viewer.toggleGrid();
  }
  if (rulerBtn) {
    rulerBtn.onclick = () => viewer.toggleRuler();
  }
  if (printAreaBtn) {
    printAreaBtn.onclick = () => viewer.togglePrintArea();
  }
}

function setupImageControl() {
  // Image list is handled by image.js module
}

function setupPrintControl(viewer) {
  const printBtn = document.getElementById('jww-print');
  if (printBtn) {
    printBtn.onclick = () => viewer.print();
  }
}

function init() {
  const app = document.getElementById('app');

  // Create file input element first (hidden)
  const fileInput = document.createElement('input');
  fileInput.type = 'file';
  fileInput.id = 'fileInput';
  fileInput.accept = '.jww';
  fileInput.style.display = 'none';
  document.body.appendChild(fileInput);

  // Show simple file picker UI
  app.innerHTML = `
    <div style="width: 100%; height: 100vh; display: flex; flex-direction: column; align-items: center; justify-content: center; background: #f5f5f5;">
      <div style="text-align: center;">
        <h1 style="margin-bottom: 20px; color: #333;">SVG JWW Viewer</h1>
        <button id="selectFileBtn" style="
          padding: 12px 24px;
          font-size: 16px;
          cursor: pointer;
          background: #2563eb;
          color: white;
          border: none;
          border-radius: 4px;
        ">Select JWW File</button>
        <p style="margin-top: 20px; color: #999;">Or drag and drop a .jww file here</p>
      </div>
    </div>
  `;

  // Setup file input change handler
  fileInput.addEventListener('change', (e) => {
    const file = e.target.files[0];
    if (file) {
      loadJWWFile(file);
    }
  });

  // Setup button click handler
  document.getElementById('selectFileBtn').addEventListener('click', () => {
    fileInput.click();
  });

  // Setup drag and drop
  document.body.addEventListener('dragover', (e) => {
    e.preventDefault();
    e.dataTransfer.dropEffect = 'copy';
  });

  document.body.addEventListener('drop', (e) => {
    e.preventDefault();
    const file = e.dataTransfer.files[0];
    if (file && (file.name.endsWith('.jww') || file.name.endsWith('.JWW'))) {
      loadJWWFile(file);
    }
  });
}

// Initialize on DOM ready
init();
