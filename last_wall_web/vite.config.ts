import { defineConfig } from 'vite';

export default defineConfig({
  // Relative paths so the dist/ folder works when zipped and uploaded to itch.io.
  base: './',
  build: {
    outDir: 'dist',
    assetsInlineLimit: 0,
    // Phaser itself is ~1.2 MB minified; that is expected.
    chunkSizeWarningLimit: 1600,
  },
  server: {
    port: 5173,
  },
});
