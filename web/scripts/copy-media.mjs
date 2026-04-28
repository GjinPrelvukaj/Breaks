import { mkdir, copyFile, access } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const docs = resolve(here, "../../docs");
const out = resolve(here, "../public/media");

const files = [
  "demo.gif",
  "screenshot-timer.png",
  "screenshot-stats.png",
  "screenshot-settings.png",
];

await mkdir(out, { recursive: true });
for (const f of files) {
  const src = resolve(docs, f);
  try {
    await access(src);
    await copyFile(src, resolve(out, f));
    console.log(`copied ${f}`);
  } catch {
    console.warn(`skip ${f} (not found at ${src})`);
  }
}
