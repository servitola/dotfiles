import { defineConfig } from 'astro/config';
import mdx from '@astrojs/mdx';
import { loadSiteConfig } from './src/lib/config.mjs';

const site = loadSiteConfig();

export default defineConfig({
  site: site.url || 'https://example.surge.sh',
  outDir: '../built-site',
  publicDir: 'public',
  integrations: [mdx()],
  build: {
    assets: 'assets',
  },
  vite: {
    server: {
      fs: {
        // Allow reading content from the parent topic folder.
        allow: ['..'],
      },
    },
  },
});
