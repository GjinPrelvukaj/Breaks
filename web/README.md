# Breaks landing page

Astro static site, deployed to GitHub Pages at `https://gjinprelvukaj.github.io/Breaks/`.

## Local

```sh
cd web
npm install
npm run dev
```

`npm run dev` runs the prebuild script that copies `../docs/{demo.gif,screenshot-*.png}` into `public/media/`. Update those source files and re-run.

## Build

```sh
npm run build
npm run preview
```

## Deploy

Push to `main`. The `.github/workflows/pages.yml` workflow builds and deploys automatically. You may also need to enable Pages once in repo Settings → Pages → Source: GitHub Actions.

## Stack

- Astro 5 (static, zero client JS)
- Self-hosted Fraunces + Geist via @fontsource
- @astrojs/sitemap
- LightningCSS minifier
