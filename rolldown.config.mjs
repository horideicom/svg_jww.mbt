import { defineConfig } from 'rolldown';

export default defineConfig({
  input: './target/js/release/build/svg_jww_ui/svg_jww_ui.js',
  output: [
    {
      format: 'esm',
      file: './dist/index.mjs',
      sourcemap: true,
      exports: 'named'
    },
    {
      format: 'cjs',
      file: './dist/index.cjs',
      sourcemap: true,
      exports: 'named'
    }
  ],
  external: [
    /^node:/
  ]
});
