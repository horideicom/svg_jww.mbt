// JWW Viewer class

import { isTouchDevice, getTouchDistance } from './utils.js';

// Coordinate transform: JWW (Y-up) to SVG (Y-down)
export class CoordinateTransform {
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
export class JWWViewer {
  constructor(container, svg, bounds, coordTransform, layerGroups, getCurrentJwwData) {
    this.container = container;
    this.svg = svg;
    this.bounds = bounds;
    this.coordTransform = coordTransform;
    this.layerGroups = layerGroups;
    this.getCurrentJwwData = getCurrentJwwData;

    // Viewport state
    this.scale = 1.0;
    this.offsetX = 0;
    this.offsetY = 0;

    // Text font scale
    this.textScale = 1.0;

    // Text features enabled (drag + font size) - default off
    this.textEnabled = false;

    // Original bounds for fit - read from actual SVG viewBox
    const initialViewBox = svg.getAttribute('viewBox').split(' ').map(Number);
    this.origMinX = initialViewBox[0];
    this.origMinY = initialViewBox[1];
    this.origWidth = initialViewBox[2];
    this.origHeight = initialViewBox[3];
    this.origMaxX = this.origMinX + this.origWidth;
    this.origMaxY = this.origMinY + this.origHeight;

    // Panning state
    this.isPanning = false;
    this.lastMouseX = 0;
    this.lastMouseY = 0;
    this.didPan = false;

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
    this.didDragText = false;

    // Display options state
    this.showGrid = false;
    this.showRuler = false;
    this.showPrintArea = false;

    // Picker state
    this.selectedElement = null;
    this.selectionOverlay = null;

    this.setupEvents();
    this.setupTextDrag();
    this.setupPicker();
    this.setTextEnabled(false);  // Initialize with text disabled
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
        this.didPan = false;
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
        if (dx !== 0 || dy !== 0) this.didDragText = true;

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
        if (dx !== 0 || dy !== 0) this.didPan = true;

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
        if (dx !== 0 || dy !== 0) this.didDragText = true;

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
        this.didPan = false;
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
        if (dx !== 0 || dy !== 0) this.didPan = true;

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
        this.didDragText = false;
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
          this.didDragText = false;
          this.dragStartX = e.touches[0].clientX;
          this.dragStartY = e.touches[0].clientY;
          this.textOrigX = parseFloat(textEl.getAttribute('x')) || 0;
          this.textOrigY = parseFloat(textEl.getAttribute('y')) || 0;
        }
      }, { passive: false });
    });
  }

  setupPicker() {
    const overlay = document.createElementNS('http://www.w3.org/2000/svg', 'rect');
    overlay.setAttribute('id', 'jww-selection-overlay');
    overlay.setAttribute('fill', 'none');
    overlay.setAttribute('stroke', '#ef4444');
    overlay.setAttribute('stroke-width', '1');
    overlay.setAttribute('stroke-dasharray', '4 3');
    overlay.setAttribute('pointer-events', 'none');
    overlay.style.display = 'none';
    this.selectionOverlay = overlay;
    this.svg.appendChild(overlay);

    this.svg.addEventListener('click', (e) => {
      this.handlePick(e);
    });
  }

  handlePick(e) {
    if (this.didPan || this.didDragText || this.isPanning || this.isDraggingText) {
      this.didPan = false;
      this.didDragText = false;
      return;
    }

    const target = e.target;
    if (!(target instanceof Element)) return;

    const entityEl = target.closest('[data-entity-index]');
    if (!entityEl || !this.svg.contains(entityEl)) {
      this.clearSelection();
      return;
    }

    this.selectEntity(entityEl);
  }

  selectEntity(element) {
    this.selectedElement = element;
    this.updateSelectionOverlay(element);
    this.updateSelectionPanel(element);
  }

  clearSelection() {
    this.selectedElement = null;
    if (this.selectionOverlay) {
      this.selectionOverlay.style.display = 'none';
    }
    this.updateSelectionPanel(null);
  }

  updateSelectionOverlay(element) {
    if (!this.selectionOverlay) return;
    const bbox = element.getBBox();
    const padding = 2;
    this.selectionOverlay.setAttribute('x', bbox.x - padding);
    this.selectionOverlay.setAttribute('y', bbox.y - padding);
    this.selectionOverlay.setAttribute('width', bbox.width + padding * 2);
    this.selectionOverlay.setAttribute('height', bbox.height + padding * 2);
    this.selectionOverlay.style.display = 'inline';
  }

  updateSelectionPanel(element) {
    const emptyEl = document.getElementById('jww-selected-entity-empty');
    const detailsEl = document.getElementById('jww-selected-entity-details');
    if (!emptyEl || !detailsEl) return;

    detailsEl.textContent = '';
    if (!element) {
      emptyEl.style.display = 'block';
      detailsEl.style.display = 'none';
      return;
    }

    emptyEl.style.display = 'none';
    detailsEl.style.display = 'grid';

    const rows = this.buildEntityRows(element);
    rows.forEach(({ label, value }) => {
      const labelEl = document.createElement('div');
      labelEl.textContent = label;
      labelEl.style.color = '#888';

      const valueEl = document.createElement('div');
      valueEl.textContent = value;
      valueEl.style.textAlign = 'right';

      detailsEl.appendChild(labelEl);
      detailsEl.appendChild(valueEl);
    });
  }

  buildEntityRows(element) {
    const data = element.dataset || {};
    const rows = [];
    const addRow = (label, value) => {
      if (value === undefined || value === '') return;
      rows.push({ label, value: String(value) });
    };
    const addAngleRad = (label, value) => {
      if (value === undefined || value === '') return;
      const num = Number(value);
      if (!Number.isFinite(num)) {
        addRow(label, value);
        return;
      }
      const deg = num * 180 / Math.PI;
      const radText = num.toFixed(6).replace(/\.?0+$/, '');
      const degText = deg.toFixed(2).replace(/\.?0+$/, '');
      addRow(label, `${radText} rad (${degText} deg)`);
    };
    const addTextValue = (label, value) => {
      if (value === undefined || value === '') return;
      const text = String(value).replace(/\s+/g, ' ').trim();
      const maxLen = 80;
      const clipped = text.length > maxLen ? text.slice(0, maxLen) + '...' : text;
      addRow(label, clipped);
    };

    const type = data.entityType;
    addRow('種別', type);
    addRow('ID', data.entityIndex);
    addRow('レイヤ', data.entityLayer);
    addRow('レイヤG', data.entityLayerGroup);
    addRow('グループ', data.entityGroup);
    addRow('線種', data.entityPenStyle);
    addRow('色', data.entityPenColor);
    addRow('線幅', data.entityPenWidth);
    addRow('フラグ', data.entityFlag);

    if (type === 'line') {
      addRow('始点X', data.entityStartX);
      addRow('始点Y', data.entityStartY);
      addRow('終点X', data.entityEndX);
      addRow('終点Y', data.entityEndY);
    } else if (type === 'arc') {
      addRow('中心X', data.entityCenterX);
      addRow('中心Y', data.entityCenterY);
      addRow('半径', data.entityRadius);
      addRow('扁平率', data.entityFlatness);
      addAngleRad('傾き角', data.entityTiltAngle);
      addAngleRad('開始角', data.entityStartAngle);
      addAngleRad('円弧角', data.entityArcAngle);
      addRow('全円', data.entityIsFullCircle);
    } else if (type === 'point') {
      addRow('X', data.entityX);
      addRow('Y', data.entityY);
      addRow('コード', data.entityCode);
      addRow('角度', data.entityAngle);
      addRow('スケール', data.entityScale);
      addRow('一時点', data.entityIsTemporary);
    } else if (type === 'text') {
      addRow('始点X', data.entityStartX);
      addRow('始点Y', data.entityStartY);
      addRow('終点X', data.entityEndX);
      addRow('終点Y', data.entityEndY);
      addRow('文字種別', data.entityTextType);
      addRow('サイズX', data.entitySizeX);
      addRow('サイズY', data.entitySizeY);
      addRow('間隔', data.entitySpacing);
      addRow('角度', data.entityAngle);
      addRow('フォント', data.entityFontName);
      addTextValue('文字列', data.entityText || element.textContent || '');
    } else if (type === 'solid') {
      addRow('点1X', data.entityPoint1X);
      addRow('点1Y', data.entityPoint1Y);
      addRow('点2X', data.entityPoint2X);
      addRow('点2Y', data.entityPoint2Y);
      addRow('点3X', data.entityPoint3X);
      addRow('点3Y', data.entityPoint3Y);
      addRow('点4X', data.entityPoint4X);
      addRow('点4Y', data.entityPoint4Y);
      addRow('塗色', data.entityColor);
    } else if (type === 'arc_solid') {
      addRow('中心X', data.entityCenterX);
      addRow('中心Y', data.entityCenterY);
      addRow('半径', data.entityRadius);
      addRow('扁平率', data.entityFlatness);
      addAngleRad('傾き角', data.entityTiltAngle);
      addAngleRad('開始角', data.entityStartAngle);
      addAngleRad('円弧角', data.entityArcAngle);
      addRow('ソリッド', data.entitySolidParam);
      addRow('塗色', data.entityColor);
    } else if (type === 'block') {
      addRow('参照X', data.entityRefX);
      addRow('参照Y', data.entityRefY);
      addRow('倍率X', data.entityScaleX);
      addRow('倍率Y', data.entityScaleY);
      addRow('回転', data.entityRotation);
      addRow('定義番号', data.entityDefNumber);
    } else if (type === 'image') {
      addRow('X', data.entityX);
      addRow('Y', data.entityY);
      addRow('幅', data.entityWidth);
      addRow('高さ', data.entityHeight);
      addRow('回転', data.entityRotation);
      addTextValue('パス', data.entityImagePath);
    }

    return rows;
  }

  resetTextPositions() {
    const texts = this.svg.querySelectorAll('text.jww-text');
    texts.forEach(el => {
      const origX = el.dataset.origX;
      const origY = el.dataset.origY;
      if (origX !== undefined) el.setAttribute('x', origX);
      if (origY !== undefined) el.setAttribute('y', origY);
    });
    // Also reset font size
    this.setFontSize(1.0);
    const slider = document.getElementById('jww-font-size');
    if (slider) slider.value = 1;
  }

  setTextEnabled(enabled) {
    this.textEnabled = enabled;
    const texts = this.svg.querySelectorAll('text.jww-text');
    texts.forEach(el => {
      // Always allow pointer events for text selection
      el.style.pointerEvents = 'auto';
      el.style.cursor = enabled ? 'move' : 'text';
      el.style.userSelect = enabled ? 'none' : 'text';
      el.style.webkitUserSelect = enabled ? 'none' : 'text';
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

  toggleGrid() {
    this.showGrid = !this.showGrid;
    this.updateDisplayOptions();
  }

  toggleRuler() {
    this.showRuler = !this.showRuler;
    this.updateDisplayOptions();
  }

  togglePrintArea() {
    this.showPrintArea = !this.showPrintArea;

    // Toggle print area overlay visibility
    const printAreaOverlay = document.getElementById('jww-print-area-overlay');
    if (printAreaOverlay) {
      printAreaOverlay.style.display = this.showPrintArea ? 'inline' : 'none';
    }

    this.updateDisplayOptions();
  }

  updateDisplayOptions() {
    // Update display status text
    const statusEl = document.getElementById('jww-display-status');
    if (statusEl) {
      const options = [];
      if (this.showGrid) options.push('グリッド');
      if (this.showRuler) options.push('ルーラー');
      if (this.showPrintArea) options.push('印刷領域');
      statusEl.textContent = options.length > 0 ? options.join(', ') : 'オフ';
    }

    // Update button styles
    const gridBtn = document.getElementById('jww-toggle-grid');
    if (gridBtn) {
      gridBtn.style.background = this.showGrid ? '#e0e0e0' : 'white';
    }
    const rulerBtn = document.getElementById('jww-toggle-ruler');
    if (rulerBtn) {
      rulerBtn.style.background = this.showRuler ? '#e0e0e0' : 'white';
    }
    const printAreaBtn = document.getElementById('jww-toggle-print-area');
    if (printAreaBtn) {
      printAreaBtn.style.background = this.showPrintArea ? '#e0e0e0' : 'white';
    }
  }

  print() {
    const currentJwwData = this.getCurrentJwwData();
    if (!currentJwwData) {
      alert('ドキュメントが読み込まれていません');
      return;
    }

    // Use the SVG directly from the parsed document
    const printSVG = currentJwwData.svg;

    // Create print container
    const printContainer = document.createElement('div');
    printContainer.id = 'print-container';
    printContainer.innerHTML = printSVG;
    document.body.appendChild(printContainer);

    // Trigger browser print dialog
    window.print();

    // Cleanup after print
    setTimeout(() => {
      printContainer.remove();
    }, 1000);
  }
}
