# Story, Press Kit & Donation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `/story`, `/press` pages and a site-wide donation FAB to the Breaks landing site.

**Architecture:** Three new files (`story.astro`, `press.astro`, `DonationFab.astro`) follow existing Astro component patterns. `DonationFab` is included in `Layout.astro`. Footer gets new nav links. No new dependencies.

**Tech Stack:** Astro 4.x, vanilla CSS (no Tailwind), Geist Sans/Mono fonts, existing design tokens in `global.css`.

---

### Task 1: DonationFab component

**Files:**
- Create: `src/components/DonationFab.astro`

- [ ] **Step 1: Create `DonationFab.astro`**

```astro
---
const BASE = import.meta.env.BASE_URL.replace(/\/$/, "");
---

<div class="fab-wrap" id="fab-wrap">
  <div class="fab-panel glass" id="fab-panel" aria-hidden="true">
    <a
      href="https://ko-fi.com"
      target="_blank"
      rel="noopener"
      class="fab-link"
      id="kofi-link"
    >
      <svg class="fab-icon" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
        <path d="M23.881 8.948c-.773-4.085-4.859-4.593-4.859-4.593H.723c-.604 0-.679.798-.679.798s-.082 7.324-.022 11.822c.164 2.424 2.586 2.672 2.586 2.672s8.267-.023 11.966-.049c2.438-.426 2.683-2.566 2.658-3.734 4.352.24 7.422-2.831 6.649-6.916zm-11.062 3.511c-1.246 1.453-4.011 3.976-4.011 3.976s-.121.119-.31.023c-.076-.057-.108-.09-.108-.09-.443-.441-3.368-3.049-4.034-3.954-.709-.965-1.041-2.7-.091-3.71.951-1.01 3.005-1.086 4.363.407 0 0 1.565-1.782 3.468-.963 1.904.82 1.832 3.011.723 4.311zm6.173.478c-.928.116-1.682.028-1.682.028V7.284h1.77s1.971.551 1.971 2.638c0 1.913-.985 2.667-2.059 3.015z"/>
      </svg>
      <span>Buy me a coffee</span>
    </a>
    <a
      href="https://github.com/sponsors/GjinPrelvukaj"
      target="_blank"
      rel="noopener"
      class="fab-link"
    >
      <svg class="fab-icon" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
        <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/>
      </svg>
      <span>Sponsor on GitHub</span>
    </a>
  </div>

  <button class="fab-btn" id="fab-btn" aria-label="Support Breaks" aria-expanded="false">
    <svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
      <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/>
    </svg>
  </button>
</div>

<style>
  .fab-wrap {
    position: fixed;
    bottom: 1.75rem;
    right: 1.75rem;
    z-index: 100;
    display: flex;
    flex-direction: column;
    align-items: flex-end;
    gap: 0.5rem;
  }

  .fab-panel {
    display: flex;
    flex-direction: column;
    gap: 0;
    border-radius: 14px;
    overflow: hidden;
    min-width: 200px;
    opacity: 0;
    transform: translateY(8px) scale(0.97);
    pointer-events: none;
    transition:
      opacity 0.18s ease,
      transform 0.18s ease;
  }
  .fab-panel.open {
    opacity: 1;
    transform: translateY(0) scale(1);
    pointer-events: auto;
  }

  .fab-link {
    display: flex;
    align-items: center;
    gap: 0.65rem;
    padding: 0.75rem 1rem;
    color: var(--ink-dim);
    font-size: 0.88rem;
    font-family: var(--sans);
    transition: background 0.12s ease, color 0.12s ease;
    border-bottom: 1px solid var(--hair);
  }
  .fab-link:last-child {
    border-bottom: none;
  }
  .fab-link:hover {
    background: rgba(255, 255, 255, 0.04);
    color: var(--ink);
  }

  .fab-icon {
    width: 15px;
    height: 15px;
    flex-shrink: 0;
    color: var(--ink-mute);
  }
  .fab-link:hover .fab-icon {
    color: var(--ink-dim);
  }

  .fab-btn {
    width: 48px;
    height: 48px;
    border-radius: 999px;
    background: var(--ink);
    color: #0a0a0a;
    border: none;
    cursor: pointer;
    display: grid;
    place-items: center;
    box-shadow: 0 4px 16px rgba(0, 0, 0, 0.4);
    transition: transform 0.12s ease, background 0.15s ease;
    flex-shrink: 0;
  }
  .fab-btn:hover {
    background: #ffffff;
    transform: scale(1.06);
  }
  .fab-btn:active {
    transform: scale(0.97);
  }
  .fab-btn svg {
    width: 18px;
    height: 18px;
  }
</style>

<script>
  const btn = document.getElementById('fab-btn')!;
  const panel = document.getElementById('fab-panel')!;

  btn.addEventListener('click', (e) => {
    e.stopPropagation();
    const open = panel.classList.toggle('open');
    btn.setAttribute('aria-expanded', String(open));
    panel.setAttribute('aria-hidden', String(!open));
  });

  document.addEventListener('click', (e) => {
    if (!document.getElementById('fab-wrap')!.contains(e.target as Node)) {
      panel.classList.remove('open');
      btn.setAttribute('aria-expanded', 'false');
      panel.setAttribute('aria-hidden', 'true');
    }
  });
</script>
```

- [ ] **Step 2: Add DonationFab to Layout.astro**

In `src/layouts/Layout.astro`, add the import at the top of the frontmatter:
```astro
import DonationFab from "../components/DonationFab.astro";
```

Add `<DonationFab />` just before `<slot />` in the body:
```astro
  <body>
    <DonationFab />
    <slot />
  </body>
```

- [ ] **Step 3: Commit**

```bash
git add src/components/DonationFab.astro src/layouts/Layout.astro
git commit -m "feat: add donation FAB (Ko-fi + GitHub Sponsors)"
```

---

### Task 2: `/story` page

**Files:**
- Create: `src/pages/story.astro`

- [ ] **Step 1: Create `src/pages/story.astro`**

```astro
---
import Layout from "../layouts/Layout.astro";
import SiteHeader from "../components/SiteHeader.astro";
import Footer from "../components/Footer.astro";
import Prose from "../components/Prose.astro";
---

<Layout
  title="Why I built Breaks"
  description="Breaks started as a frustration with noisy tools. A quiet menu-bar Pomodoro for people who just want to focus."
  canonicalPath="/story"
>
  <SiteHeader />
  <main>
    <Prose
      eyebrow="Story"
      title="Built for the tab-closer in all of us."
      updated="April 2026"
    >
      <p>
        Most productivity tools have a problem: they want your attention. Dashboard 
        apps, streak notifications, gamified interfaces — the tools meant to help 
        you focus end up competing for the same focus they're supposed to protect.
      </p>

      <p>
        I wanted a Pomodoro timer that did the opposite. One that lived quietly in 
        the menu bar, showed you a countdown, and got out of the way. No onboarding 
        flows. No accounts. No cloud sync. Just a timer.
      </p>

      <h2>The gap</h2>

      <p>
        The existing options fell into two categories. Big apps with feature lists 
        longer than your to-do list — calendar integrations, analytics dashboards, 
        team sync, AI suggestions. And tiny utilities that worked fine but looked 
        like they were built in an afternoon and hadn't been touched since.
      </p>

      <p>
        Neither felt right. I wanted something small but considered. Something that 
        respected the philosophy it was built on: that deep work needs fewer 
        interruptions, not more interfaces.
      </p>

      <h2>What I built</h2>

      <p>
        Breaks is a menu-bar Pomodoro for macOS. It ticks through work sessions and 
        breaks, keeps a focus journal, tracks streaks, and fires notifications when 
        it's time to move. Global hotkeys mean you never need to open a window to 
        start or stop a session.
      </p>

      <p>
        It's sandboxed, ships with no network access, and stores everything locally 
        in <code>UserDefaults</code>. There's no account, no backend, no telemetry. 
        Your focus data stays on your Mac.
      </p>

      <h2>Shipped and using it daily</h2>

      <p>
        Breaks is free and open source under the MIT license. I use it every day. 
        If you find a bug or want to suggest something, open an issue on 
        <a href="https://github.com/GjinPrelvukaj/Breaks/issues" rel="noopener">GitHub</a> — 
        that's where the project lives.
      </p>

      <p>
        If it saves you a few context switches, it's done its job.
      </p>
    </Prose>
  </main>
  <Footer />
</Layout>
```

- [ ] **Step 2: Commit**

```bash
git add src/pages/story.astro
git commit -m "feat: add /story page"
```

---

### Task 3: `/press` page

**Files:**
- Create: `src/pages/press.astro`

- [ ] **Step 1: Create `src/pages/press.astro`**

```astro
---
import Layout from "../layouts/Layout.astro";
import SiteHeader from "../components/SiteHeader.astro";
import Footer from "../components/Footer.astro";

const BASE = import.meta.env.BASE_URL.replace(/\/$/, "");

const blurbs = {
  oneliner: "A quiet menu-bar Pomodoro for macOS. Free, open source, no account needed.",
  short: `Breaks is a menu-bar Pomodoro timer for macOS. It runs work sessions and breaks, keeps a focus journal, tracks streaks, and fires local notifications — all without an account, a backend, or network access. Sandboxed, MIT licensed, and free.`,
  long: `Breaks is a small, focused Pomodoro app that lives in the macOS menu bar. It cycles through work sessions and breaks, logs each session to a focus journal, and tracks daily streaks with a pause-day budget so a missed day doesn't wipe your progress. Global hotkeys let you start, skip, or reset a session without opening a window. Notifications are delivered locally by macOS — no push server, no account, no email gate. Everything is stored on-device in UserDefaults. The app is sandboxed, ships with no network entitlements, and is free and open source under the MIT license. It requires macOS 13.0 or later.`,
};

const assets = [
  { label: "App Icon", file: "favicon.svg", thumb: `${BASE}/favicon.svg`, mime: "image/svg+xml" },
  { label: "Demo GIF", file: "demo.gif", thumb: `${BASE}/media/demo.gif`, mime: "image/gif" },
  { label: "Screenshot — Timer", file: "screenshot-timer.png", thumb: `${BASE}/media/screenshot-timer.png`, mime: "image/png" },
  { label: "Screenshot — Stats", file: "screenshot-stats.png", thumb: `${BASE}/media/screenshot-stats.png`, mime: "image/png" },
  { label: "Screenshot — Settings", file: "screenshot-settings.png", thumb: `${BASE}/media/screenshot-settings.png`, mime: "image/png" },
];

const facts = [
  { label: "Price", value: "Free" },
  { label: "Platform", value: "macOS 13.0+" },
  { label: "License", value: "MIT" },
  { label: "Version", value: "1.1" },
  { label: "Bundle ID", value: "com.gjinprelvukaj.Breaks" },
  { label: "Source", value: "github.com/GjinPrelvukaj/Breaks" },
];
---

<Layout
  title="Press Kit — Breaks"
  description="Everything you need to write about Breaks: app blurbs, screenshots, GIF, app facts, and contact."
  canonicalPath="/press"
>
  <SiteHeader />
  <main class="press">
    <div class="wrap wrap-narrow">

      <header class="press-head">
        <span class="pill"><span class="dot"></span>Press Kit</span>
        <h1 class="h-section">Everything you need to write about Breaks.</h1>
        <p class="press-contact">
          Questions? Open an issue on
          <a href="https://github.com/GjinPrelvukaj/Breaks/issues" rel="noopener">GitHub</a>.
        </p>
      </header>

      <!-- Blurbs -->
      <section class="section">
        <h2 class="section-title">App Description</h2>
        <div class="blurbs">
          {Object.entries(blurbs).map(([key, text]) => (
            <div class="blurb glass" data-blurb={key}>
              <div class="blurb-header">
                <span class="eyebrow">
                  {key === "oneliner" ? "One-liner" : key === "short" ? "Short" : "Long"}
                </span>
                <button class="btn btn-ghost copy-btn" data-copy={text} aria-label={`Copy ${key} blurb`}>
                  Copy
                </button>
              </div>
              <p class="blurb-text">{text}</p>
            </div>
          ))}
        </div>
      </section>

      <!-- Assets -->
      <section class="section">
        <h2 class="section-title">Download Assets</h2>
        <div class="assets-grid">
          {assets.map((a) => (
            <a
              class="asset-card glass"
              href={a.thumb}
              download={a.file}
              aria-label={`Download ${a.label}`}
            >
              <div class="asset-thumb">
                <img src={a.thumb} alt={a.label} loading="lazy" />
              </div>
              <div class="asset-meta">
                <span class="asset-label">{a.label}</span>
                <span class="asset-file eyebrow">{a.file}</span>
              </div>
              <svg class="asset-dl" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.5" aria-hidden="true">
                <path d="M8 2v8M4 7l4 4 4-4" stroke-linecap="round" stroke-linejoin="round"/>
                <path d="M2 13h12" stroke-linecap="round"/>
              </svg>
            </a>
          ))}
        </div>
      </section>

      <!-- Facts -->
      <section class="section">
        <h2 class="section-title">App Facts</h2>
        <div class="facts glass">
          {facts.map((f, i) => (
            <div class={`fact-row${i < facts.length - 1 ? " bordered" : ""}`}>
              <span class="fact-label eyebrow">{f.label}</span>
              <span class="fact-value">{f.value}</span>
            </div>
          ))}
        </div>
      </section>

    </div>
  </main>
  <Footer />
</Layout>

<style>
  .press {
    padding-block: clamp(4rem, 8vw, 6rem);
  }

  .press-head {
    display: grid;
    gap: 0.85rem;
    margin-bottom: clamp(3rem, 6vw, 4.5rem);
  }
  .press-head .h-section {
    margin-top: 0.25rem;
  }
  .press-contact {
    color: var(--ink-dim);
    font-size: 0.95rem;
  }
  .press-contact a {
    color: var(--ink);
    border-bottom: 1px solid var(--hair-strong);
    transition: border-color 0.15s ease;
  }
  .press-contact a:hover {
    border-color: var(--ink);
  }

  .section {
    margin-bottom: clamp(3rem, 6vw, 4rem);
  }
  .section-title {
    font-size: 0.8rem;
    font-family: var(--mono);
    letter-spacing: 0.08em;
    text-transform: uppercase;
    color: var(--ink-mute);
    margin-bottom: 1rem;
  }

  /* Blurbs */
  .blurbs {
    display: grid;
    gap: 0.75rem;
  }
  .blurb {
    padding: 1.1rem 1.25rem;
  }
  .blurb-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 0.65rem;
  }
  .blurb-text {
    color: var(--ink-dim);
    font-size: 0.95rem;
    line-height: 1.65;
  }
  .copy-btn {
    padding: 0.3rem 0.7rem;
    font-size: 0.78rem;
    border-radius: 6px;
  }
  .copy-btn.copied {
    color: var(--ink);
    border-color: var(--hair-bright);
  }

  /* Assets */
  .assets-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
    gap: 0.75rem;
  }
  .asset-card {
    display: flex;
    flex-direction: column;
    padding: 0.85rem;
    gap: 0.65rem;
    text-decoration: none;
    transition: border-color 0.15s ease, background 0.15s ease;
    position: relative;
  }
  .asset-card:hover {
    border-color: var(--hair-bright);
    background: linear-gradient(180deg, rgba(255,255,255,0.04), rgba(255,255,255,0)), var(--bg-elev);
  }
  .asset-thumb {
    width: 100%;
    aspect-ratio: 1;
    background: var(--bg-soft);
    border-radius: 8px;
    overflow: hidden;
    display: grid;
    place-items: center;
  }
  .asset-thumb img {
    width: 100%;
    height: 100%;
    object-fit: cover;
  }
  .asset-meta {
    display: grid;
    gap: 0.2rem;
  }
  .asset-label {
    font-size: 0.85rem;
    color: var(--ink);
    font-weight: 500;
  }
  .asset-file {
    font-size: 0.68rem;
  }
  .asset-dl {
    width: 14px;
    height: 14px;
    color: var(--ink-mute);
    position: absolute;
    top: 0.85rem;
    right: 0.85rem;
  }

  /* Facts */
  .facts {
    padding: 0;
    overflow: hidden;
  }
  .fact-row {
    display: grid;
    grid-template-columns: 130px 1fr;
    align-items: center;
    padding: 0.8rem 1.25rem;
    gap: 1rem;
  }
  .fact-row.bordered {
    border-bottom: 1px solid var(--hair);
  }
  .fact-label {
    font-size: 0.72rem;
  }
  .fact-value {
    color: var(--ink-dim);
    font-size: 0.92rem;
  }
</style>

<script>
  document.querySelectorAll<HTMLButtonElement>('.copy-btn').forEach((btn) => {
    btn.addEventListener('click', async () => {
      const text = btn.dataset.copy ?? '';
      try {
        await navigator.clipboard.writeText(text);
        btn.textContent = 'Copied!';
        btn.classList.add('copied');
        setTimeout(() => {
          btn.textContent = 'Copy';
          btn.classList.remove('copied');
        }, 1800);
      } catch {
        btn.textContent = 'Failed';
        setTimeout(() => { btn.textContent = 'Copy'; }, 1800);
      }
    });
  });
</script>
```

- [ ] **Step 2: Commit**

```bash
git add src/pages/press.astro
git commit -m "feat: add /press page"
```

---

### Task 4: Update Footer navigation

**Files:**
- Modify: `src/components/Footer.astro`

- [ ] **Step 1: Add Story + Press links under App col, Support link under Author col**

In `src/components/Footer.astro`, replace the App column:
```astro
<div class="col">
  <span class="col-title">App</span>
  <a href="https://github.com/GjinPrelvukaj/Breaks/releases/latest" rel="noopener">Download</a>
  <a href="https://github.com/GjinPrelvukaj/Breaks">Source</a>
  <a href={`${BASE}/story/`}>Story</a>
  <a href={`${BASE}/press/`}>Press Kit</a>
  <a href="https://github.com/users/GjinPrelvukaj/projects/1" rel="noopener">Roadmap</a>
</div>
```

Replace the Author column:
```astro
<div class="col">
  <span class="col-title">Author</span>
  <a href="https://github.com/GjinPrelvukaj" rel="noopener">GjinPrelvukaj</a>
  <a href="https://github.com/sponsors/GjinPrelvukaj" rel="noopener">Sponsor</a>
  <a href="https://github.com/GjinPrelvukaj/Breaks/issues" rel="noopener">Report a bug</a>
</div>
```

- [ ] **Step 2: Commit**

```bash
git add src/components/Footer.astro
git commit -m "feat: add story/press/sponsor links to footer"
```

---

### Task 5: Start dev server

- [ ] **Step 1: Install deps if needed and start dev server**

```bash
cd /Users/gjinprelvukaj/Desktop/Dev/Breaks/web && npm run dev
```

Expected: server running at `http://localhost:4321` (or similar). Verify `/story`, `/press`, FAB visible on all pages.
