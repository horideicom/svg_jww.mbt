# svg-jww-viewer

A JWW file viewer implemented in MoonBit. It provides a toolkit for displaying JW_CAD format files (*.jww) in a web browser.

## Features

* **JWW file parsing**: Parse JW_CAD binary files (uses [horideicom/jww_parser](https://github.com/horideicom/jww_parser.mbt))
* **SVG rendering**: Convert JWW data to SVG for display
* **Interactive viewer**:
  * Zoom in/out (mouse wheel, keyboard shortcuts)
  * Pan (mouse drag)
  * Fit (auto-adjust display bounds)
* **Layer panel**:
  * Toggle layer visibility
  * Show entity counts per layer
* **Text features**:
  * Drag text to move
  * Adjust font size
  * Reset text position
  * Toggle text display on/off

## Tech Stack

* **MoonBit**: Main programming language (WebAssembly target supported)
* **Luna**: Signal-based reactive UI framework (mizchi/luna)
* **mizchi/js**: JavaScript interoperability library
* **TypeScript**: Type definition files
* **Rolldown**: Fast bundler (ESM/CJS output supported)
* **Vite**: Demo application for development

## Installation

```bash
# Clone the repository
git clone https://github.com/horideicom/svg_jww.mbt
cd svg_jww

# Install dependencies
pnpm install
```

## Build

```bash
# Clean build
pnpm run clean

# Build MoonBit code
pnpm run build:moon

# Bundle
pnpm run build:bundle

# Copy TypeScript type definitions
pnpm run build:types

# Build everything
pnpm run build
```

## Usage

### Demo Application

```bash
# Start the dev server in the examples directory
cd examples
pnpm dev

# Open http://localhost:5173 in your browser
```

In the demo app you can:

* **Select a file**: choose or drag & drop a `.jww` file
* **Zoom**: `+`/`-` buttons, mouse wheel, or keyboard `+`/`-`
* **Pan**: drag on the SVG
* **Fit**: `Fit` button or keyboard `F`
* **Reset**: `Reset` button or `Ctrl+R`
* **Toggle layers**: use the checkboxes in the layer panel on the right
* **Edit text**:
  * Toggle text features with the `Text` checkbox
  * Drag text to move it
  * Adjust font size with the `Size` slider
  * Reset text position with `Reset Text`

### CLI Debug Tool

```bash
# Convert a JWW file to SVG
moon run cmd/svg_debug -- input.jww

# Enable debug overlays + metadata JSON
moon run cmd/svg_debug -- --debug input.jww

# Write metadata JSON to a file (pretty-printed)
moon run cmd/svg_debug -- --debug --json-out debug.json --pretty input.jww
```

### Use as a Library

npmへのpublishは停止中のため、ローカルワークスペースまたはビルド成果物を参照してください。

```javascript
import { parse } from 'jww-parser'; // workspace or local build
import { renderToSvg } from 'svg-jww-viewer'; // workspace or local build

// Parse a JWW file
const buffer = await file.arrayBuffer();
const uint8Array = new Uint8Array(buffer);
const jwwData = parse(uint8Array);

// Render to SVG
const svg = renderToSvg(jwwData);
```

## Project Structure

```
svg_jww/
├── cmd/                        # Entry points
│   ├── browser/main.mbt        # For browser (Luna UI)
│   └── main/main.mbt           # For CLI
├── svg_jww_ui/                 # UI components (MoonBit + Luna)
│   ├── app.mbt                 # Main application
│   ├── canvas.mbt              # SVG canvas
│   ├── layer_panel.mbt         # Layer panel
│   └── state.mbt               # State management (Signal)
├── svg_jww.mbt                 # SVG element builder
├── svg_jww_renderer.mbt        # Rendering logic
├── svg_jww_types.mbt           # Type definitions
├── svg_jww_wbtest.mbt          # WebAssembly tests
├── examples/                   # Demo application
│   ├── src/main.js             # Main logic (vanilla JS)
│   ├── index.html              # HTML template
│   ├── vite.config.ts          # Vite config
│   └── package.json            # Demo dependencies
├── package/                    # npm package config
│   ├── package.json
│   └── dist/                   # Build output
├── moon.mod.json               # MoonBit dependencies
├── rolldown.config.mjs         # Bundler config
└── package.json                # Root package
```

## License

AGPL-3.0

## Author

f12o

## Repository

https://github.com/horideicom/svg_jww.mbt
