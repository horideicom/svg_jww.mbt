// Panel UI for JWW viewer

import { getScreenSize, getPaperSizeString } from './utils.js';
import { currentTheme } from './theme.js';

// Render floating panel (original function, kept for compatibility)
export function renderFloatingPanel(layerGroups, jwwData = null) {
  return renderFloatingPanelWithPrintArea(layerGroups, false, jwwData);
}

// Render floating panel with print area support
export function renderFloatingPanelWithPrintArea(layerGroups, showPrintArea, jwwData = null) {
  // Defensive check for layerGroups
  if (!layerGroups || !Array.isArray(layerGroups)) {
    console.warn('layerGroups is invalid:', layerGroups);
    layerGroups = [];
  }

  const screenSize = getScreenSize();
  const isMobile = screenSize === 'mobile';
  const isTablet = screenSize === 'tablet';

  // Responsive panel styles
  let panelStyle, headerStyle, headerCursor, showOverlay = '';

  if (isMobile) {
    // Mobile: bottom sheet with safe area for iOS Safari address bar
    panelStyle = `
      position: fixed;
      bottom: env(safe-area-inset-bottom);
      left: 0;
      right: 0;
      width: 100%;
      max-height: 50vh;
      border-radius: 12px 12px 0 0;
      transform: translateY(0);
      transition: transform 0.3s ease-out;
      padding-bottom: constant(safe-area-inset-bottom);
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
    if (!layer) continue;
    const checked = layer.visible ? 'checked' : '';
    const entityCount = layer.entities ? layer.entities.length : 0;
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
        <span style="color: #999; font-size: 11px;">(${entityCount})</span>
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
          <button id="jww-zoom-in" data-action="zoom_in" title="拡大" style="
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
          <button id="jww-zoom-out" data-action="zoom_out" title="縮小" style="
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
          <button id="jww-fit" data-action="fit" title="フィット" style="
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
          <button id="jww-reset" data-action="reset" title="リセット" style="
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

      <!-- Display Options Section -->
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
        ">表示オプション</div>
        <div style="
          display: flex;
          gap: 4px;
          flex-wrap: wrap;
        ">
          <button id="jww-toggle-grid" data-action="toggle_grid" title="グリッド表示" style="
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
          ">▦</button>
          <button id="jww-toggle-ruler" data-action="toggle_ruler" title="ルーラー表示" style="
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
          ">📏</button>
          <button id="jww-toggle-print-area" data-action="toggle_print_area" title="印刷領域表示" style="
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
          ">🖼</button>
          <button id="jww-print" title="印刷" style="
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
          ">🖨</button>
        </div>
        <div style="
          display: flex;
          align-items: center;
          gap: 8px;
          margin-top: 8px;
          font-size: 12px;
          color: #666;
        ">
          <span id="jww-display-status">表示オプション: オフ</span>
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
            <input type="checkbox" id="jww-text-enabled" style="cursor: pointer;">
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
          <input type="range" id="jww-font-size" min="0.5" max="3" step="0.1" value="1" disabled style="
            flex: 1;
            cursor: pointer;
            opacity: 0.5;
          ">
          <span id="jww-font-display" style="min-width: 35px;">100%</span>
        </div>
      </div>

      <!-- Document Info Section -->
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
        ">ドキュメント</div>
        <div style="font-size: 12px; color: #666;">
          ${jwwData ? `
            <div style="display: flex; justify-content: space-between; margin-bottom: 4px;">
              <span>バージョン:</span>
              <span>${jwwData.version || '-'}</span>
            </div>
            <div style="display: flex; justify-content: space-between; margin-bottom: 4px;">
              <span>用紙:</span>
              <span>${getPaperSizeString(jwwData.paper_size)}</span>
            </div>
            <div style="display: flex; justify-content: space-between; margin-bottom: 4px;">
              <span>メモ:</span>
              <span style="max-width: 120px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">${jwwData.memo || '-'}</span>
            </div>
            <div style="margin-top: 8px; font-size: 11px; color: #888;">エンティティ</div>
            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 4px; font-size: 11px;">
              <span>Lines: ${jwwData.entity_counts.lines}</span>
              <span>Arcs: ${jwwData.entity_counts.arcs}</span>
              <span>Points: ${jwwData.entity_counts.points}</span>
              <span>Texts: ${jwwData.entity_counts.texts}</span>
              <span>Solids: ${jwwData.entity_counts.solids}</span>
              <span>Blocks: ${jwwData.entity_counts.blocks}</span>
              <span>Images: ${jwwData.entity_counts.images}</span>
            </div>
            <div style="margin-top: 8px; font-size: 11px; color: #888;">選択中</div>
            <div id="jww-selected-entity" style="font-size: 11px; color: #666;">
              <div id="jww-selected-entity-empty" style="color: #999;">未選択</div>
              <div id="jww-selected-entity-details" style="
                display: none;
                grid-template-columns: 1fr 1fr;
                gap: 4px;
                max-height: 120px;
                overflow-y: auto;
              "></div>
            </div>
            ${jwwData.print_settings ? `
              <div style="margin-top: 8px; font-size: 11px; color: #888;">印刷設定</div>
              <div style="display: flex; justify-content: space-between; font-size: 11px;">
                <span>原点: (${Math.round(jwwData.print_settings.origin_x || 0)}, ${Math.round(jwwData.print_settings.origin_y || 0)})</span>
              </div>
              <div style="display: flex; justify-content: space-between; font-size: 11px;">
                <span>スケール: ${jwwData.print_settings.scale || 1.0}</span>
              </div>
            ` : ''}
          ` : '<div style="font-size: 12px; color: #999;">ドキュメント情報なし</div>'}
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

      <!-- Images Section -->
      <div style="
        padding: 12px;
        max-height: 150px;
        overflow-y: auto;
        border-bottom: 1px solid #eee;
      ">
        <div style="
          font-size: 11px;
          font-weight: bold;
          color: #888;
          margin-bottom: 8px;
          text-transform: uppercase;
        ">画像 (<span id="jww-image-count">0</span>)</div>
        <div id="jww-image-list">
          <div style="font-size: 12px; color: #999;">画像なし</div>
        </div>
      </div>
      <!-- Theme Section -->
      <div style="
        padding: 12px;
      ">
        <div style="
          font-size: 11px;
          font-weight: bold;
          color: #888;
          margin-bottom: 8px;
          text-transform: uppercase;
        ">テーマ</div>
        <select id="jww-theme-select" style="
          width: 100%;
          padding: 6px 8px;
          border: 1px solid #ddd;
          border-radius: 4px;
          background: white;
          font-size: 13px;
          cursor: pointer;
        ">
          <option value="system" ${currentTheme === 'system' ? 'selected' : ''}>System</option>
          <option value="solarizedLight" ${currentTheme === 'solarizedLight' ? 'selected' : ''}>Solarized Light</option>
          <option value="solarizedDark" ${currentTheme === 'solarizedDark' ? 'selected' : ''}>Solarized Dark</option>
        </select>
      </div>
      </div>
    </div>
  `;
}

export function setupLayerToggles(viewer) {
  document.querySelectorAll('.layer-toggle').forEach(cb => {
    cb.addEventListener('change', () => {
      const layerId = cb.dataset.layer;
      viewer.toggleLayer(layerId);
    });
  });
}

export function setupMobilePanelToggle() {
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
      // Keep header visible (44px) when closed - above address bar
      panel.style.transform = 'translateY(calc(100% - 44px - env(safe-area-inset-bottom)))';
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

export function setupPanelDrag() {
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
