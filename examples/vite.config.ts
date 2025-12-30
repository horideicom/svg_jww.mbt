import { defineConfig } from "vite";
import path from "path";

export default defineConfig({
  base: "/svg_jww.mbt/",
  build: {
    outDir: "dist",
    sourcemap: true,
  },
  resolve: {
    alias: {
      // Use local svg-jww-viewer-mbt in development
      "svg-jww-viewer-mbt": path.resolve(__dirname, "../dist/index.mjs"),
    },
  },
  server: {
    port: 5173,
  },
});
