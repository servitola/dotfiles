// Parses site.yaml and links.yaml from topic root (parent of engine/).
// Returns safe defaults if files are missing.
//
// Topic root is detected by finding site.yaml walking up from cwd. When
// Astro builds, it bundles lib files so import.meta.url is unreliable.

import { readFileSync, existsSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import yaml from 'yaml';

function findTopicRoot() {
  if (process.env.TOPIC_ROOT) return resolve(process.env.TOPIC_ROOT);

  let dir = process.cwd();
  for (let i = 0; i < 6; i++) {
    if (existsSync(resolve(dir, 'site.yaml'))) return dir;
    const parent = dirname(dir);
    if (parent === dir) break;
    dir = parent;
  }

  return resolve(process.cwd(), '..');
}

const topicRoot = findTopicRoot();

const defaults = {
  name: 'My site',
  description: '',
  lang: 'ru',
  url: '',
  sections: {
    home: true,
    about: true,
    blog: true,
    portfolio: true,
    gallery: true,
    contacts: true,
  },
  theme: {
    'primary-color': '#2563eb',
    'background': '#ffffff',
    'text-color': '#0f172a',
    'heading-font': 'Inter',
    'body-font': 'Inter',
    'dark-mode': 'auto',
  },
  seo: { keywords: [], author: '' },
};

function readYaml(path, fallback) {
  if (!existsSync(path)) return fallback;
  try {
    return yaml.parse(readFileSync(path, 'utf8')) ?? fallback;
  } catch (e) {
    console.warn(`Failed to parse ${path}: ${e.message}. Using defaults.`);
    return fallback;
  }
}

export function loadSiteConfig() {
  const raw = readYaml(resolve(topicRoot, 'site.yaml'), {});
  return {
    ...defaults,
    ...raw,
    sections: { ...defaults.sections, ...(raw.sections || {}) },
    theme: { ...defaults.theme, ...(raw.theme || {}) },
    seo: { ...defaults.seo, ...(raw.seo || {}) },
  };
}

export function loadLinks() {
  return readYaml(resolve(topicRoot, 'links.yaml'), {});
}

export function topicPath(...parts) {
  return resolve(topicRoot, ...parts);
}

export { topicRoot };
