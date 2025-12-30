import { defineConfig } from "vite";

export default defineConfig({
  base: "/svg_jww.mbt/",
  build: {
    outDir: "dist",
    sourcemap: true,
  },
  optimizeDeps: {
    include: ["svg-jww-viewer-mbt"],
  },
  server: {
    port: 5173,
  },
});
