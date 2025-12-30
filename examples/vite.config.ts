import { defineConfig } from "vite";

export default defineConfig({
  base: "/svg_jww.mbt/",
  build: {
    outDir: "dist",
    sourcemap: true,
  },
  server: {
    port: 5173,
  },
});
