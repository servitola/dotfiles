// Loads content from the user's topic folders into structures ready for
// rendering. Missing folders/files return empty results, never throw.

import { readFileSync, existsSync, readdirSync, statSync } from 'node:fs';
import { basename, extname, join } from 'node:path';
import matter from 'gray-matter';
import yaml from 'yaml';
import { topicPath } from './config.mjs';

const IMG_EXT = new Set(['.jpg', '.jpeg', '.png', '.webp', '.gif', '.avif']);

function readMarkdown(path) {
  if (!existsSync(path)) return null;
  const raw = readFileSync(path, 'utf8');
  const parsed = matter(raw);
  return { data: parsed.data, body: parsed.content };
}

function slugify(name) {
  return name.replace(/\.md$/i, '').replace(/\s+/g, '-').toLowerCase();
}

function listDir(path) {
  if (!existsSync(path)) return [];
  return readdirSync(path).filter((n) => !n.startsWith('.'));
}

function readCaptions(basePath) {
  // Supports captions.yaml (preferred) and captions.md (fallback).
  const yamlPath = basePath + '.yaml';
  if (existsSync(yamlPath)) {
    try {
      return yaml.parse(readFileSync(yamlPath, 'utf8')) || {};
    } catch { return {}; }
  }
  const md = readMarkdown(basePath + '.md');
  return md?.data || {};
}

export function loadPosts() {
  const dir = topicPath('posts');
  return listDir(dir)
    .filter((f) => extname(f).toLowerCase() === '.md')
    .map((file) => {
      const parsed = readMarkdown(join(dir, file));
      const data = parsed?.data || {};
      return {
        slug: slugify(file),
        title: data.title || basename(file, '.md'),
        date: data.date || null,
        cover: data.cover || null,
        description: data.description || '',
        body: parsed?.body || '',
        data,
      };
    })
    .sort((a, b) => {
      const da = a.date ? new Date(a.date).getTime() : 0;
      const db = b.date ? new Date(b.date).getTime() : 0;
      return db - da;
    });
}

export function loadProjects() {
  const dir = topicPath('projects');
  return listDir(dir)
    .filter((n) => statSync(join(dir, n)).isDirectory())
    .map((projDir) => {
      const md = readMarkdown(join(dir, projDir, 'description.md'));
      const data = md?.data || {};
      const coverFile = listDir(join(dir, projDir))
        .find((f) => f.startsWith('cover') && IMG_EXT.has(extname(f).toLowerCase()));
      const images = listDir(join(dir, projDir, 'images'))
        .filter((f) => IMG_EXT.has(extname(f).toLowerCase()));
      return {
        slug: slugify(projDir),
        name: data.name || projDir,
        year: data.year || null,
        link: data.link || null,
        cover: coverFile ? `projects/${projDir}/${coverFile}` : null,
        images: images.map((f) => `projects/${projDir}/images/${f}`),
        body: md?.body || '',
        data,
      };
    });
}

export function loadGallery() {
  const dir = topicPath('gallery');
  return listDir(dir)
    .filter((n) => statSync(join(dir, n)).isDirectory())
    .map((album) => {
      const files = listDir(join(dir, album))
        .filter((f) => IMG_EXT.has(extname(f).toLowerCase()))
        .sort();
      const captions = readCaptions(join(dir, album, 'captions'));
      return {
        slug: slugify(album),
        name: album,
        photos: files.map((f) => ({
          path: `gallery/${album}/${f}`,
          caption: captions[f] || '',
        })),
      };
    })
    .filter((a) => a.photos.length > 0);
}

export function loadAbout() {
  return readMarkdown(topicPath('about.md'));
}

export function loadHome() {
  return readMarkdown(topicPath('home.md'));
}
