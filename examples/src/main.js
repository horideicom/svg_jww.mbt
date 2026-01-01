import { parse } from 'jww-parser';

// Coordinate transform: JWW (Y-up) to SVG (Y-down)
class CoordinateTransform {
  constructor(jwwBounds) {
    this.minY = jwwBounds.minY;
    this.maxY = jwwBounds.maxY;
  }

  // Transform Y coordinate from JWW (Y-up) to SVG (Y-down)
  transformY(y) {
    return this.maxY - (y - this.minY);
  }
}

// JWW Viewer - handles zoom, pan, fit
class JWWViewer {
  constructor(container, svg, bounds, coordTransform, layerGroups) {
    this.container = container;
    this.svg = svg;
    this.bounds = bounds;
    this.coordTransform = coordTransform;
    this.layerGroups = layerGroups;

    // Viewport state
    this.scale = 1.0;
    this.offsetX = 0;
    this.offsetY = 0;

    // Text font scale
    this.textScale = 1.0;

    // Text features enabled (drag + font size)
    this.textEnabled = true;

    // Original bounds for fit
    this.origMinX = bounds.minX;
    this.origMaxX = bounds.maxX;
    this.origMinY = coordTransform.transformY(bounds.maxY);
    this.origMaxY = coordTransform.transformY(bounds.minY);
    this.origWidth = bounds.maxX - bounds.minX;
    this.origHeight = bounds.maxY - bounds.minY;

    // Panning state
    this.isPanning = false;
    this.lastMouseX = 0;
    this.lastMouseY = 0;

    // Touch state for pan
    this.isTouchPanning = false;
    this.lastTouchX = 0;
    this.lastTouchY = 0;

    // Touch state for pinch zoom
    this.lastPinchDistance = 0;
    this.pinchScaleStart = 1.0;

    // Text dragging state
    this.isDraggingText = false;
    this.draggedText = null;
    this.dragStartX = 0;
    this.dragStartY = 0;
    this.textOrigX = 0;
    this.textOrigY = 0;

    this.setupEvents();
    this.setupTextDrag();
    this.updateViewBox();
  }

  setupEvents() {
    // Mouse wheel zoom - set on container to capture all wheel events
    this.container.addEventListener('wheel', (e) => {
      e.preventDefault();
      const rect = this.container.getBoundingClientRect();
      const mouseX = e.clientX - rect.left;
      const mouseY = e.clientY - rect.top;

      const zoomFactor = e.deltaY > 0 ? 0.9 : 1.1;
      this.zoomAtPoint(mouseX, mouseY, zoomFactor);
    }, { passive: false });

    // Mouse drag pan - set on SVG for direct capture
    this.svg.style.cursor = 'grab';

    this.svg.addEventListener('mousedown', (e) => {
      // Don't pan if clicking on a text element
      if (e.target.tagName === 'text' || e.target.closest && e.target.closest('text')) {
        return;
      }
      if (e.button === 0) {
        this.isPanning = true;
        this.lastMouseX = e.clientX;
        this.lastMouseY = e.clientY;
        this.svg.style.cursor = 'grabbing';
        e.preventDefault();
      }
    });

    window.addEventListener('mousemove', (e) => {
      // Handle text dragging
      if (this.isDraggingText && this.draggedText) {
        const rect = this.svg.getBoundingClientRect();
        const viewBox = this.svg.getAttribute('viewBox').split(' ').map(Number);
        const vbWidth = viewBox[2];
        const vbHeight = viewBox[3];
        const scale = vbWidth / rect.width;

        const dx = (e.clientX - this.dragStartX) * scale;
        const dy = (e.clientY - this.dragStartY) * scale;

        const newX = this.textOrigX + dx;
        const newY = this.textOrigY + dy;

        this.draggedText.setAttribute('x', newX);
        this.draggedText.setAttribute('y', newY);

        // Update transform if present
        const transform = this.draggedText.getAttribute('transform');
        if (transform && transform.includes('rotate')) {
          const rotateMatch = transform.match(/rotate\(([^)]+)\)/);
          if (rotateMatch) {
            this.draggedText.setAttribute('transform', `rotate(${rotateMatch[1]}, ${newX}, ${newY})`);
          }
        }
        return;
      }

      // Handle panning
      if (this.isPanning) {
        const dx = e.clientX - this.lastMouseX;
        const dy = e.clientY - this.lastMouseY;

        const rect = this.svg.getBoundingClientRect();
        const viewBox = this.svg.getAttribute('viewBox').split(' ').map(Number);
        const vbWidth = viewBox[2];
        const vbHeight = viewBox[3];

        // Convert pixel delta to viewBox units
        const scale = vbWidth / rect.width;
        this.offsetX -= dx * scale;
        this.offsetY -= dy * scale;

        this.lastMouseX = e.clientX;
        this.lastMouseY = e.clientY;
        this.updateViewBox();
      }
    });

    window.addEventListener('mouseup', () => {
      if (this.isDraggingText) {
        this.isDraggingText = false;
        this.draggedText = null;
      }
      if (this.isPanning) {
        this.isPanning = false;
        this.svg.style.cursor = 'grab';
      }
    });

    // Touch move handler for text dragging
    window.addEventListener('touchmove', (e) => {
      if (this.isDraggingText && this.draggedText && e.touches.length === 1) {
        const rect = this.svg.getBoundingClientRect();
        const viewBox = this.svg.getAttribute('viewBox').split(' ').map(Number);
        const vbWidth = viewBox[2];
        const vbHeight = viewBox[3];
        const scale = vbWidth / rect.width;

        const dx = (e.touches[0].clientX - this.dragStartX) * scale;
        const dy = (e.touches[0].clientY - this.dragStartY) * scale;

        const newX = this.textOrigX + dx;
        const newY = this.textOrigY + dy;

        this.draggedText.setAttribute('x', newX);
        this.draggedText.setAttribute('y', newY);

        // Update transform if present
        const transform = this.draggedText.getAttribute('transform');
        if (transform && transform.includes('rotate')) {
          const rotateMatch = transform.match(/rotate\(([^)]+)\)/);
          if (rotateMatch) {
            this.draggedText.setAttribute('transform', `rotate(${rotateMatch[1]}, ${newX}, ${newY})`);
          }
        }
      }
    }, { passive: false });

    // Touch end handler for text dragging
    window.addEventListener('touchend', () => {
      if (this.isDraggingText) {
        this.isDraggingText = false;
        this.draggedText = null;
      }
    });

    // Keyboard shortcuts
    window.addEventListener('keydown', (e) => {
      if (e.key === '+' || e.key === '=') {
        e.preventDefault();
        this.zoomIn();
      } else if (e.key === '-' || e.key === '_') {
        e.preventDefault();
        this.zoomOut();
      } else if (e.key === 'f' || e.key === 'F') {
        e.preventDefault();
        this.fit();
      } else if (e.key === 'r' || e.key === 'R') {
        if (e.ctrlKey || e.metaKey) {
          e.preventDefault();
          this.reset();
        }
      }
    });

    // Touch events for mobile devices
    if (isTouchDevice()) {
      this.setupTouchEvents();
    }
  }

  setupTouchEvents() {
    // Touch start - detect pan or pinch
    this.svg.addEventListener('touchstart', (e) => {
      if (e.touches.length === 1) {
        // Single finger - prepare for pan
        const touch = e.touches[0];
        // Check if touching on a text element
        if (e.target.tagName === 'text' || e.target.closest && e.target.closest('text')) {
          // Let text drag handle it
          return;
        }
        this.isTouchPanning = true;
        this.lastTouchX = touch.clientX;
        this.lastTouchY = touch.clientY;
      } else if (e.touches.length === 2) {
        // Two fingers - prepare for pinch zoom
        this.isTouchPanning = false;
        this.lastPinchDistance = getTouchDistance(e.touches);
        this.pinchScaleStart = this.scale;
      }
    }, { passive: false });

    // Touch move - handle pan or pinch
    this.svg.addEventListener('touchmove', (e) => {
      e.preventDefault(); // Prevent page scroll

      if (e.touches.length === 1 && this.isTouchPanning) {
        // Single finger pan
        const touch = e.touches[0];
        const dx = touch.clientX - this.lastTouchX;
        const dy = touch.clientY - this.lastTouchY;

        const rect = this.svg.getBoundingClientRect();
        const viewBox = this.svg.getAttribute('viewBox').split(' ').map(Number);
        const vbWidth = viewBox[2];
        const vbHeight = viewBox[3];

        // Convert pixel delta to viewBox units
        const scale = vbWidth / rect.width;
        this.offsetX -= dx * scale;
        this.offsetY -= dy * scale;

        this.lastTouchX = touch.clientX;
        this.lastTouchY = touch.clientY;
        this.updateViewBox();
      } else if (e.touches.length === 2) {
        // Two finger pinch zoom
        const currentDistance = getTouchDistance(e.touches);
        if (this.lastPinchDistance > 0) {
          const scaleRatio = currentDistance / this.lastPinchDistance;
          const newScale = this.pinchScaleStart * scaleRatio;

          // Clamp scale to reasonable limits
          const clampedScale = Math.max(0.1, Math.min(newScale, 10.0));

          // Calculate zoom center (midpoint between touches)
          const rect = this.svg.getBoundingClientRect();
          const touchCenterX = (e.touches[0].clientX + e.touches[1].clientX) / 2;
          const touchCenterY = (e.touches[0].clientY + e.touches[1].clientY) / 2;

          // Apply zoom centered on touch position
          this.scale = clampedScale;
          const newVbWidth = this.origWidth / this.scale;
          const newVbHeight = this.origHeight / this.scale;

          // Get current viewBox
          const viewBox = this.svg.getAttribute('viewBox').split(' ').map(Number);
          const vbX = viewBox[0];
          const vbY = viewBox[1];
          const vbWidth = viewBox[2];
          const vbHeight = viewBox[3];

          // Calculate zoom center in viewBox coordinates
          const vbCenterX = vbX + (touchCenterX / rect.width) * vbWidth;
          const vbCenterY = vbY + (touchCenterY / rect.height) * vbHeight;

          // Adjust offset to keep zoom center stationary
          const vbRatioX = (vbCenterX - vbX) / vbWidth;
          const vbRatioY = (vbCenterY - vbY) / vbHeight;

          this.offsetX = vbCenterX - newVbWidth * vbRatioX - this.origMinX;
          this.offsetY = vbCenterY - newVbHeight * vbRatioY - this.origMinY;

          this.updateViewBox();
        }
      }
    }, { passive: false });

    // Touch end - reset states
    this.svg.addEventListener('touchend', (e) => {
      if (e.touches.length === 0) {
        this.isTouchPanning = false;
        this.lastPinchDistance = 0;
      }
    });
  }

  zoomAtPoint(screenX, screenY, zoomFactor) {
    const rect = this.container.getBoundingClientRect();
    const viewBox = this.svg.getAttribute('viewBox').split(' ').map(Number);

    const vbX = viewBox[0];
    const vbY = viewBox[1];
    const vbWidth = viewBox[2];
    const vbHeight = viewBox[3];

    // Convert screen point to viewBox coordinates
    const vbMouseX = vbX + (screenX / rect.width) * vbWidth;
    const vbMouseY = vbY + (screenY / rect.height) * vbHeight;

    // Apply zoom
    this.scale *= zoomFactor;

    // Calculate new viewBox dimensions
    const newVbWidth = this.origWidth / this.scale;
    const newVbHeight = this.origHeight / this.scale;

    // Adjust offset to keep mouse point stationary
    const vbRatioX = (vbMouseX - vbX) / vbWidth;
    const vbRatioY = (vbMouseY - vbY) / vbHeight;

    this.offsetX = vbMouseX - newVbWidth * vbRatioX - this.origMinX;
    this.offsetY = vbMouseY - newVbHeight * vbRatioY - this.origMinY;

    this.updateViewBox();
  }

  updateViewBox() {
    const width = this.origWidth / this.scale;
    const height = this.origHeight / this.scale;
    const x = this.origMinX + this.offsetX;
    const y = this.origMinY + this.offsetY;

    this.svg.setAttribute('viewBox', `${x} ${y} ${width} ${height}`);
    this.updateScaleDisplay();
  }

  updateScaleDisplay() {
    const scaleDisplay = document.getElementById('jww-scale-display');
    if (scaleDisplay) {
      scaleDisplay.textContent = `${Math.round(this.scale * 100)}%`;
    }
  }

  zoomIn() {
    const rect = this.container.getBoundingClientRect();
    this.zoomAtPoint(rect.width / 2, rect.height / 2, 1.2);
  }

  zoomOut() {
    const rect = this.container.getBoundingClientRect();
    this.zoomAtPoint(rect.width / 2, rect.height / 2, 1 / 1.2);
  }

  fit() {
    // Fit to container
    const rect = this.container.getBoundingClientRect();
    const padding = 40;

    const availableWidth = rect.width - padding * 2;
    const availableHeight = rect.height - padding * 2;

    const scaleX = availableWidth / this.origWidth;
    const scaleY = availableHeight / this.origHeight;
    this.scale = Math.min(scaleX, scaleY, 1);

    this.offsetX = 0;
    this.offsetY = 0;
    this.updateViewBox();
  }

  reset() {
    this.scale = 1.0;
    this.offsetX = 0;
    this.offsetY = 0;
    this.updateViewBox();
  }

  toggleLayer(layerId) {
    const layerGroup = document.getElementById(`layer-${layerId}`);
    const checkbox = document.querySelector(`.layer-toggle[data-layer="${layerId}"]`);
    if (layerGroup && checkbox) {
      const isVisible = checkbox.checked;
      layerGroup.style.visibility = isVisible ? 'visible' : 'hidden';
    }
  }

  setFontSize(scale) {
    this.textScale = scale;
    document.querySelectorAll('text[data-base-size]').forEach(el => {
      const baseSize = parseFloat(el.dataset.baseSize);
      el.setAttribute('font-size', baseSize * scale);
    });
    this.updateFontDisplay();
  }

  updateFontDisplay() {
    const fontDisplay = document.getElementById('jww-font-display');
    if (fontDisplay) {
      fontDisplay.textContent = `${Math.round(this.textScale * 100)}%`;
    }
  }

  setupTextDrag() {
    // Enable drag for all text elements
    const texts = this.svg.querySelectorAll('text.jww-text');
    texts.forEach(textEl => {
      // Save original position for reset
      if (!textEl.dataset.origX) {
        textEl.dataset.origX = textEl.getAttribute('x') || 0;
      }
      if (!textEl.dataset.origY) {
        textEl.dataset.origY = textEl.getAttribute('y') || 0;
      }

      // Mouse events
      textEl.addEventListener('mousedown', (e) => {
        // Check if text features are enabled
        if (!this.textEnabled) return;

        e.stopPropagation();
        e.preventDefault();

        this.isDraggingText = true;
        this.draggedText = textEl;
        this.dragStartX = e.clientX;
        this.dragStartY = e.clientY;
        this.textOrigX = parseFloat(textEl.getAttribute('x')) || 0;
        this.textOrigY = parseFloat(textEl.getAttribute('y')) || 0;
      });

      // Touch events for mobile
      textEl.addEventListener('touchstart', (e) => {
        // Check if text features are enabled
        if (!this.textEnabled) return;

        if (e.touches.length === 1) {
          e.stopPropagation();
          e.preventDefault();

          this.isDraggingText = true;
          this.draggedText = textEl;
          this.dragStartX = e.touches[0].clientX;
          this.dragStartY = e.touches[0].clientY;
          this.textOrigX = parseFloat(textEl.getAttribute('x')) || 0;
          this.textOrigY = parseFloat(textEl.getAttribute('y')) || 0;
        }
      }, { passive: false });
    });
  }

  resetTextPositions() {
    const texts = this.svg.querySelectorAll('text.jww-text');
    texts.forEach(el => {
      const origX = el.dataset.origX;
      const origY = el.dataset.origY;
      if (origX !== undefined) el.setAttribute('x', origX);
      if (origY !== undefined) el.setAttribute('y', origY);
    });
  }

  setTextEnabled(enabled) {
    this.textEnabled = enabled;
    const texts = this.svg.querySelectorAll('text.jww-text');
    texts.forEach(el => {
      el.style.cursor = enabled ? 'move' : 'default';
      el.style.pointerEvents = enabled ? 'auto' : 'none';
    });

    // Reset font size when disabled
    if (!enabled) {
      this.setFontSize(1.0);
    }

    // Update slider disabled state
    const slider = document.getElementById('jww-font-size');
    if (slider) {
      slider.disabled = !enabled;
      slider.style.opacity = enabled ? '1' : '0.5';
    }
  }
}

// Get the actual entity value (handle MoonBit enum encoding)
function getEntityValue(entity) {
  for (const key of Object.keys(entity)) {
    if (key.startsWith('_')) {
      return entity[key];
    }
  }
  return entity;
}

// Determine entity type by checking which fields exist
// IMPORTANT: Check Text first since Text also has start_x/end_x
function getEntityType(value) {
  // Text first - has content field
  if (value.content !== undefined) {
    return 'Text';
  }
  // Arc - has center_x and radius
  if (value.center_x !== undefined && value.radius !== undefined) {
    return 'Arc';
  }
  // Line - has start_x/end_x but NO center_x
  if (value.start_x !== undefined && value.end_x !== undefined && value.center_x === undefined) {
    return 'Line';
  }
  // Point - has x/y but NO start_x and NO content
  if (value.x !== undefined && value.y !== undefined && value.start_x === undefined && value.content === undefined) {
    return 'Point';
  }
  // Solid - has point1_x
  if (value.point1_x !== undefined) {
    return 'Solid';
  }
  // Block - has def_number
  if (value.def_number !== undefined) {
    return 'Block';
  }
  return 'Unknown';
}

// Group entities by layer
function groupEntitiesByLayer(jwwData) {
  const layers = Array.from({ length: 16 }, (_, i) => ({
    id: i,
    name: `Layer ${i}`,
    entities: [],
    visible: true
  }));

  if (jwwData.entities && jwwData.entities.length > 0) {
    for (const entity of jwwData.entities) {
      const value = getEntityValue(entity);
      const base = value.base || {};
      const layerId = base.layer ?? 0;
      if (layers[layerId]) {
        layers[layerId].entities.push(entity);
      }
    }
  }

  return layers.filter(l => l.entities.length > 0);
}

function calculateBounds(jwwData) {
  let minX = 0, minY = 0, maxX = 400, maxY = 300;

  if (jwwData.entities && jwwData.entities.length > 0) {
    minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;

    for (const entity of jwwData.entities) {
      const bounds = getEntityBounds(entity);
      if (bounds) {
        minX = Math.min(minX, bounds.minX);
        minY = Math.min(minY, bounds.minY);
        maxX = Math.max(maxX, bounds.maxX);
        maxY = Math.max(maxY, bounds.maxY);
      }
    }

    if (minX === Infinity) {
      minX = 0, minY = 0, maxX = 400, maxY = 300;
    }
  }

  return { minX, minY, maxX, maxY };
}

function getEntityBounds(entity) {
  const value = getEntityValue(entity);

  if (value.content !== undefined) {
    // Text - use start_x/end_x for bounds
    return {
      minX: value.start_x,
      minY: value.start_y,
      maxX: value.end_x || value.start_x,
      maxY: value.end_y || value.start_y,
    };
  }
  if (value.start_x !== undefined && value.end_x !== undefined && value.center_x === undefined) {
    // Line
    return {
      minX: Math.min(value.start_x, value.end_x),
      minY: Math.min(value.start_y, value.end_y),
      maxX: Math.max(value.start_x, value.end_x),
      maxY: Math.max(value.start_y, value.end_y),
    };
  }
  if (value.center_x !== undefined && value.radius !== undefined) {
    // Arc
    const r = value.radius || 0;
    return {
      minX: value.center_x - r,
      minY: value.center_y - r,
      maxX: value.center_x + r,
      maxY: value.center_y + r,
    };
  }
  if (value.x !== undefined && value.y !== undefined && value.start_x === undefined) {
    // Point
    return {
      minX: value.x - 5,
      minY: value.y - 5,
      maxX: value.x + 5,
      maxY: value.y + 5,
    };
  }
  return null;
}

// Render SVG for JWW data
function renderJWWToSVG(jwwData) {
  console.log('Rendering JWW data, entities:', jwwData.entities?.length);

  const bounds = calculateBounds(jwwData);
  const padding = 20;
  const width = bounds.maxX - bounds.minX + padding * 2;
  const height = bounds.maxY - bounds.minY + padding * 2;

  const coordTransform = new CoordinateTransform(bounds);
  const layerGroups = groupEntitiesByLayer(jwwData);

  // Calculate transformed bounds for viewBox
  const transformedMinY = coordTransform.transformY(bounds.maxY);

  let svg = `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="${bounds.minX - padding} ${transformedMinY - padding} ${width} ${height}">
  <rect x="${bounds.minX - padding}" y="${transformedMinY - padding}" width="${width}" height="${height}" fill="white"/>
`;

  // Render each layer as a group
  for (const layer of layerGroups) {
    svg += `<g id="layer-${layer.id}" class="jww-layer" data-layer="${layer.id}">\n`;
    for (const entity of layer.entities) {
      svg += renderEntity(entity, coordTransform);
    }
    svg += `</g>\n`;
  }

  svg += `</svg>`;
  return { svgContent: svg, layerGroups, bounds, coordTransform };
}

function renderEntity(entity, coordTransform) {
  const value = getEntityValue(entity);
  const base = value.base || {};
  const color = getColor(base.pen_color);
  const strokeWidth = Math.max((base.pen_width || 1) * 0.5, 0.5);
  const type = getEntityType(value);

  switch (type) {
    case 'Line': {
      const x1 = value.start_x;
      const y1 = coordTransform.transformY(value.start_y);
      const x2 = value.end_x;
      const y2 = coordTransform.transformY(value.end_y);
      return `<line x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}" stroke="${color}" stroke-width="${strokeWidth}"/>\n`;
    }

    case 'Arc': {
      const cx = value.center_x;
      const cy = coordTransform.transformY(value.center_y);
      const r = value.radius || 0;
      if (value.is_full_circle) {
        return `<circle cx="${cx}" cy="${cy}" r="${r}" fill="none" stroke="${color}" stroke-width="${strokeWidth}"/>\n`;
      }
      const startAngleRad = value.start_angle || 0;
      const arcAngleRad = value.arc_angle || 0;

      const x1 = cx + r * Math.cos(startAngleRad);
      const y1 = cy - r * Math.sin(startAngleRad);
      const endAngleRad = startAngleRad + arcAngleRad;
      const x2 = cx + r * Math.cos(endAngleRad);
      const y2 = cy - r * Math.sin(endAngleRad);

      const largeArc = Math.abs(arcAngleRad * 180 / Math.PI) > 180 ? 1 : 0;
      const sweep = arcAngleRad > 0 ? 0 : 1;

      return `<path d="M ${x1} ${y1} A ${r} ${r} 0 ${largeArc} ${sweep} ${x2} ${y2}" fill="none" stroke="${color}" stroke-width="${strokeWidth}"/>\n`;
    }

    case 'Point': {
      const x = value.x;
      const y = coordTransform.transformY(value.y);
      return `<circle cx="${x}" cy="${y}" r="2" fill="${color}"/>\n`;
    }

    case 'Text': {
      const textContent = value.content || '';
      const x = value.start_x;
      const baseY = value.start_y || 0;
      const y = coordTransform.transformY(baseY);
      const fontSize = Math.abs(value.size_y || 10);
      const sizeX = value.size_x || fontSize;
      const angle = value.angle || 0;
      const svgAngle = -angle;
      const spacing = value.spacing || 0;

      // Calculate character width scaling
      const charWidthScale = sizeX / fontSize;

      // Calculate line height from end_y/start_y difference
      let lineHeight = fontSize * 1.2;
      if (value.end_y !== undefined && Math.abs(value.end_y - baseY) > fontSize) {
        lineHeight = Math.abs(value.end_y - baseY);
      }

      // Escape text content for SVG
      const escapeHtml = (str) => str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#39;');

      // Split text by newlines for multi-line rendering
      const lines = textContent.split('\n');
      const isMultiLine = lines.length > 1;

      let svgText = '';

      if (isMultiLine) {
        const tsDy = lineHeight;
        svgText += `<text x="${x}" y="${y}" font-size="${fontSize}" fill="${color}" data-base-size="${fontSize}" class="jww-text" transform="rotate(${svgAngle}, ${x}, ${y})" style="font-family: sans-serif; letter-spacing: ${spacing}px; cursor: move;">`;
        lines.forEach((line, i) => {
          const dy = i === 0 ? '0' : tsDy;
          svgText += `<tspan x="${x}" dy="${dy}">${escapeHtml(line)}</tspan>`;
        });
        svgText += `</text>\n`;
      } else {
        svgText += `<text x="${x}" y="${y}" font-size="${fontSize}" fill="${color}" data-base-size="${fontSize}" class="jww-text" style="font-family: sans-serif; letter-spacing: ${spacing}px; cursor: move;`;
        if (charWidthScale !== 1) {
          svgText += ` transform-box: fill-box; transform-origin: left center; transform: rotate(${svgAngle}, ${x}, ${y}) scaleX(${charWidthScale});`;
        } else {
          svgText += ` transform: rotate(${svgAngle}, ${x}, ${y});`;
        }
        svgText += `">${escapeHtml(textContent)}</text>\n`;
      }

      return svgText;
    }

    case 'Solid': {
      const x1 = value.point1_x;
      const y1 = coordTransform.transformY(value.point1_y);
      const x2 = value.point2_x;
      const y2 = coordTransform.transformY(value.point2_y);
      const x3 = value.point3_x;
      const y3 = coordTransform.transformY(value.point3_y);
      const x4 = value.point4_x;
      const y4 = coordTransform.transformY(value.point4_y);
      return `<polygon points="${x1},${y1} ${x2},${y2} ${x3},${y3} ${x4},${y4}" fill="${color}" stroke="none"/>\n`;
    }

    case 'Block':
      return `<!-- Block entity: def_number=${value.def_number} -->\n`;

    default:
      return `<!-- Unhandled entity type: ${type} -->\n`;
  }
}

// Get screen size for responsive layout
function getScreenSize() {
  const width = window.innerWidth;
  if (width <= 480) return 'mobile';
  if (width <= 768) return 'tablet';
  return 'desktop';
}

// Check if device supports touch
function isTouchDevice() {
  return 'ontouchstart' in window ||
         navigator.maxTouchPoints > 0 ||
         navigator.msMaxTouchPoints > 0;
}

// Calculate distance between two touch points for pinch zoom
function getTouchDistance(touches) {
  if (touches.length < 2) return 0;
  const dx = touches[0].clientX - touches[1].clientX;
  const dy = touches[0].clientY - touches[1].clientY;
  return Math.sqrt(dx * dx + dy * dy);
}

function getColor(penColor) {
  const idx = penColor || 1;
  const colors = [
    '#ffffff', '#000000', '#ff0000', '#00ff00', '#0000ff',
    '#ffff00', '#ff00ff', '#00ffff', '#ff8000', '#808080',
  ];
  return colors[Math.min(idx, colors.length - 1)];
}

function renderFloatingPanel(layerGroups) {
  const screenSize = getScreenSize();
  const isMobile = screenSize === 'mobile';
  const isTablet = screenSize === 'tablet';

  // Responsive panel styles
  let panelStyle, headerStyle, headerCursor, showOverlay = '';

  if (isMobile) {
    // Mobile: bottom sheet
    panelStyle = `
      position: fixed;
      bottom: 0;
      left: 0;
      right: 0;
      width: 100%;
      max-height: 50vh;
      border-radius: 12px 12px 0 0;
      transform: translateY(0);
      transition: transform 0.3s ease-out;
    `;
    headerStyle = `
      padding: 12px 16px;
      border-radius: 12px 12px 0 0;
    `;
    headerCursor = 'pointer';
    showOverlay = `<div id="jww-panel-overlay" style="
      position: fixed;
      top: 0;
      left: 0;
      right: 0;
      bottom: 0;
      background: rgba(0, 0, 0, 0.3);
      z-index: 999;
      display: none;
    "></div>`;
  } else if (isTablet) {
    // Tablet: smaller floating panel
    panelStyle = `
      position: absolute;
      top: 10px;
      right: 10px;
      width: 200px;
    `;
    headerStyle = `
      padding: 10px 12px;
      border-radius: 6px 6px 0 0;
    `;
    headerCursor = 'grab';
  } else {
    // Desktop: full floating panel
    panelStyle = `
      position: absolute;
      top: 10px;
      right: 10px;
      width: 240px;
    `;
    headerStyle = `
      padding: 10px 12px;
      border-radius: 6px 6px 0 0;
    `;
    headerCursor = 'grab';
  }

  let layerItems = '';
  for (const layer of layerGroups) {
    const checked = layer.visible ? 'checked' : '';
    layerItems += `
      <label style="
        display: flex;
        align-items: center;
        gap: 8px;
        padding: 4px 0;
        cursor: pointer;
        font-size: 13px;
      ">
        <input type="checkbox" ${checked} data-layer="${layer.id}" class="layer-toggle" style="cursor: pointer;">
        <span style="flex: 1;">L${layer.id}</span>
        <span style="color: #999; font-size: 11px;">(${layer.entities.length})</span>
      </label>
    `;
  }

  return `
    ${showOverlay}
    <div id="jww-floating-panel" data-screen-size="${screenSize}" style="
      ${panelStyle}
      background: rgba(255, 255, 255, 0.98);
      border: 1px solid #ccc;
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      z-index: 1000;
      display: flex;
      flex-direction: column;
    ">
      <!-- Header -->
      <div id="jww-panel-header" style="
        ${headerStyle}
        background: #f5f5f5;
        border-bottom: 1px solid #ddd;
        cursor: ${headerCursor};
        user-select: none;
        display: flex;
        align-items: center;
        justify-content: space-between;
        font-weight: 600;
        font-size: 14px;
      ">
        <span style="display: flex; align-items: center; gap: 6px;">
          ${isMobile ? '▼' : '≡'}
          <span>コントロール</span>
        </span>
      </div>

      <!-- Panel Content (scrollable on mobile) -->
      <div style="
        ${isMobile ? 'overflow-y: auto; flex: 1;' : ''}
      ">
        <!-- Zoom Section -->
      <div style="
        padding: 12px;
        border-bottom: 1px solid #eee;
      ">
        <div style="
          font-size: 11px;
          font-weight: bold;
          color: #888;
          margin-bottom: 8px;
          text-transform: uppercase;
        ">ズーム操作</div>
        <div style="
          display: flex;
          gap: 4px;
          flex-wrap: wrap;
        ">
          <button id="jww-zoom-in" title="拡大" style="
            width: 44px;
            height: 36px;
            border: 1px solid #ddd;
            border-radius: 4px;
            background: white;
            cursor: pointer;
            font-size: 16px;
            display: flex;
            align-items: center;
            justify-content: center;
          ">🔍+</button>
          <button id="jww-zoom-out" title="縮小" style="
            width: 44px;
            height: 36px;
            border: 1px solid #ddd;
            border-radius: 4px;
            background: white;
            cursor: pointer;
            font-size: 16px;
            display: flex;
            align-items: center;
            justify-content: center;
          ">🔍−</button>
          <button id="jww-fit" title="フィット" style="
            width: 44px;
            height: 36px;
            border: 1px solid #ddd;
            border-radius: 4px;
            background: white;
            cursor: pointer;
            font-size: 16px;
            display: flex;
            align-items: center;
            justify-content: center;
          ">📐</button>
          <button id="jww-reset" title="リセット" style="
            width: 44px;
            height: 36px;
            border: 1px solid #ddd;
            border-radius: 4px;
            background: white;
            cursor: pointer;
            font-size: 16px;
            display: flex;
            align-items: center;
            justify-content: center;
          ">🔄</button>
        </div>
        <div style="
          display: flex;
          align-items: center;
          gap: 8px;
          margin-top: 8px;
          font-size: 12px;
          color: #666;
        ">
          <span>倍率:</span>
          <span id="jww-scale-display" style="min-width: 40px;">100%</span>
        </div>
      </div>

      <!-- Text Section -->
      <div style="
        padding: 12px;
        border-bottom: 1px solid #eee;
      ">
        <div style="
          font-size: 11px;
          font-weight: bold;
          color: #888;
          margin-bottom: 8px;
          text-transform: uppercase;
        ">テキスト操作</div>
        <div style="
          display: flex;
          align-items: center;
          gap: 8px;
        ">
          <label style="
            display: flex;
            align-items: center;
            gap: 6px;
            font-size: 13px;
            cursor: pointer;
          ">
            <input type="checkbox" id="jww-text-enabled" checked style="cursor: pointer;">
            <span>有効</span>
          </label>
          <button id="jww-reset-text" title="テキスト位置リセット" style="
            padding: 4px 8px;
            border: 1px solid #ddd;
            border-radius: 4px;
            background: white;
            cursor: pointer;
            font-size: 12px;
          ">リセット</button>
        </div>
        <div style="
          display: flex;
          align-items: center;
          gap: 8px;
          margin-top: 8px;
          font-size: 12px;
          color: #666;
        ">
          <span>サイズ:</span>
          <input type="range" id="jww-font-size" min="0.5" max="3" step="0.1" value="1" style="
            flex: 1;
            cursor: pointer;
          ">
          <span id="jww-font-display" style="min-width: 35px;">100%</span>
        </div>
      </div>

      <!-- Layers Section -->
      <div style="
        padding: 12px;
        max-height: 200px;
        overflow-y: auto;
      ">
        <div style="
          font-size: 11px;
          font-weight: bold;
          color: #888;
          margin-bottom: 8px;
          text-transform: uppercase;
        ">レイヤー (${layerGroups.length})</div>
        ${layerItems}
      </div>
      </div>
    </div>
  `;
}

function setupLayerToggles(viewer) {
  document.querySelectorAll('.layer-toggle').forEach(cb => {
    cb.addEventListener('change', () => {
      const layerId = cb.dataset.layer;
      viewer.toggleLayer(layerId);
    });
  });
}

function setupMobilePanelToggle() {
  const panel = document.getElementById('jww-floating-panel');
  const header = document.getElementById('jww-panel-header');
  const overlay = document.getElementById('jww-panel-overlay');
  if (!panel || !header) return;

  const screenSize = panel.dataset.screenSize;
  if (screenSize !== 'mobile') return;

  let isOpen = true;

  const togglePanel = () => {
    isOpen = !isOpen;
    if (isOpen) {
      panel.style.transform = 'translateY(0)';
      if (overlay) overlay.style.display = 'block';
    } else {
      panel.style.transform = 'translateY(100%)';
      if (overlay) overlay.style.display = 'none';
    }
  };

  // Header click to toggle
  header.addEventListener('click', (e) => {
    // Prevent drag from triggering toggle
    if (!e.defaultPrevented) {
      togglePanel();
    }
  });

  // Overlay click to close
  if (overlay) {
    overlay.addEventListener('click', () => {
      if (isOpen) togglePanel();
    });
  }
}

function setupPanelDrag() {
  const panel = document.getElementById('jww-floating-panel');
  const header = document.getElementById('jww-panel-header');
  if (!panel || !header) return;

  // Skip drag on mobile
  const screenSize = panel.dataset.screenSize;
  if (screenSize === 'mobile') return;

  let isDragging = false;
  let startX, startY, panelStartX, panelStartY;

  header.addEventListener('mousedown', (e) => {
    isDragging = true;
    startX = e.clientX;
    startY = e.clientY;
    const rect = panel.getBoundingClientRect();
    panelStartX = rect.left;
    panelStartY = rect.top;
    header.style.cursor = 'grabbing';
    e.preventDefault();
  });

  window.addEventListener('mousemove', (e) => {
    if (!isDragging) return;
    const dx = e.clientX - startX;
    const dy = e.clientY - startY;
    const newX = panelStartX + dx;
    const newY = panelStartY + dy;
    panel.style.left = newX + 'px';
    panel.style.top = newY + 'px';
    panel.style.right = 'auto';
  });

  window.addEventListener('mouseup', () => {
    if (isDragging) {
      isDragging = false;
      header.style.cursor = 'grab';
    }
  });
}

function renderFilePicker() {
  return `
    <div style="display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100vh; background: #f5f5f5;">
      <div style="background: white; padding: 40px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); text-align: center;">
        <h1 style="margin-bottom: 20px; color: #333;">SVG JWW Viewer</h1>
        <p style="margin-bottom: 30px; color: #666;">Select a JWW file to view</p>
        <input type="file" id="fileInput" accept=".jww" style="display: none;">
        <button onclick="document.getElementById('fileInput').click()"
                style="padding: 12px 24px; font-size: 16px; cursor: pointer; background: #2563eb; color: white; border: none; border-radius: 4px;">
          Select JWW File
        </button>
        <p style="margin-top: 20px; font-size: 12px; color: #999;">Or drag and drop a .jww file here</p>
      </div>
    </div>
  `;
}

async function loadJWWFile(file) {
  try {
    const buffer = await file.arrayBuffer();
    const uint8Array = new Uint8Array(buffer);

    const jwwData = parse(uint8Array);
    console.log('Parsed JWW data:', jwwData);
    console.log('Entities count:', jwwData.entities?.length);

    const { svgContent, layerGroups, bounds, coordTransform } = renderJWWToSVG(jwwData);

    const app = document.getElementById('app');
    app.innerHTML = `
      <div id="jww-canvas" style="width: 100%; height: 100vh; position: relative; overflow: hidden;">
        ${svgContent}
        ${renderFloatingPanel(layerGroups)}
      </div>
    `;

    // Get SVG element and setup viewer
    const svg = app.querySelector('svg');
    const canvas = document.getElementById('jww-canvas');
    svg.style.width = '100%';
    svg.style.height = '100%';

    const viewer = new JWWViewer(canvas, svg, bounds, coordTransform, layerGroups);

    // Setup zoom buttons
    document.getElementById('jww-zoom-in').onclick = () => viewer.zoomIn();
    document.getElementById('jww-zoom-out').onclick = () => viewer.zoomOut();
    document.getElementById('jww-fit').onclick = () => viewer.fit();
    document.getElementById('jww-reset').onclick = () => viewer.reset();

    // Setup font size slider
    const fontSizeSlider = document.getElementById('jww-font-size');
    fontSizeSlider.addEventListener('input', (e) => {
      viewer.setFontSize(parseFloat(e.target.value));
    });

    // Setup text enabled toggle
    const textEnabledCheckbox = document.getElementById('jww-text-enabled');
    textEnabledCheckbox.addEventListener('change', (e) => {
      viewer.setTextEnabled(e.target.checked);
    });

    // Setup reset text button
    document.getElementById('jww-reset-text').onclick = () => viewer.resetTextPositions();

    // Setup layer toggles
    setupLayerToggles(viewer);

    // Setup panel drag
    setupPanelDrag();

    // Setup mobile panel toggle
    setupMobilePanelToggle();

    // Handle window resize - re-render panel for responsive layout
    let resizeTimeout;
    window.addEventListener('resize', () => {
      clearTimeout(resizeTimeout);
      resizeTimeout = setTimeout(() => {
        const canvas = document.getElementById('jww-canvas');
        if (canvas) {
          // Remove old panel
          const oldPanel = document.getElementById('jww-floating-panel');
          const oldOverlay = document.getElementById('jww-panel-overlay');
          if (oldPanel) oldPanel.remove();
          if (oldOverlay) oldOverlay.remove();

          // Re-add panel with new responsive styles
          canvas.insertAdjacentHTML('beforeend', renderFloatingPanel(layerGroups));

          // Re-setup event handlers
          setupLayerToggles(viewer);
          setupPanelDrag();
          setupMobilePanelToggle();

          // Re-bind button handlers
          document.getElementById('jww-zoom-in').onclick = () => viewer.zoomIn();
          document.getElementById('jww-zoom-out').onclick = () => viewer.zoomOut();
          document.getElementById('jww-fit').onclick = () => viewer.fit();
          document.getElementById('jww-reset').onclick = () => viewer.reset();
          document.getElementById('jww-reset-text').onclick = () => viewer.resetTextPositions();

          const fontSizeSlider = document.getElementById('jww-font-size');
          fontSizeSlider.addEventListener('input', (e) => {
            viewer.setFontSize(parseFloat(e.target.value));
          });
          const textEnabledCheckbox = document.getElementById('jww-text-enabled');
          textEnabledCheckbox.addEventListener('change', (e) => {
            viewer.setTextEnabled(e.target.checked);
          });
        }
      }, 250);
    });

    // Initial fit
    setTimeout(() => viewer.fit(), 100);

    console.log('JWW file loaded:', file.name);
    console.log('Layers:', layerGroups.map(l => `${l.id}:${l.entities.length}`).join(', '));

    // Count text entities
    const textCount = jwwData.entities?.filter(e => {
      const v = getEntityValue(e);
      return v.content !== undefined;
    }).length || 0;
    console.log('Text entities:', textCount);

  } catch (error) {
    console.error('Error loading JWW file:', error);
    alert('Error loading JWW file: ' + error.message);
  }
}

function init() {
  const app = document.getElementById('app');
  app.innerHTML = renderFilePicker();

  const fileInput = document.getElementById('fileInput');
  fileInput.addEventListener('change', (e) => {
    const file = e.target.files[0];
    if (file) {
      loadJWWFile(file);
    }
  });

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

  console.log('SVG JWW Viewer initialized');
}

init();
