import { defineConfig } from "vite";

const base =
  process.env.BASE_PATH ??
  (process.env.CF_PAGES ? "/" : "/svg_jww.mbt/");

export default defineConfig(({ mode }) => ({
  base: mode == "production" ? base : "/",
  build: {
    outDir: "dist",
    sourcemap: true,
  },
  optimizeDeps: {
    include: ["svg-jww-viewer"],
  },
  server: {
    port: 5173,
  },
}));
