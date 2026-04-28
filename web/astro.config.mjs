import { defineConfig } from "astro/config";
import sitemap from "@astrojs/sitemap";

const SITE = "https://gjinprelvukaj.github.io";
const BASE = "/Breaks";

export default defineConfig({
  site: SITE,
  base: BASE,
  trailingSlash: "ignore",
  compressHTML: true,
  build: {
    inlineStylesheets: "auto",
    assets: "_assets",
  },
  integrations: [
    sitemap({
      filter: (page) => !page.includes("/404"),
    }),
  ],
  vite: {
    build: {
      cssMinify: "lightningcss",
    },
  },
});
