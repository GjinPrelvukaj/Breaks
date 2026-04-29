# Story, Press Kit & Donation — Design Spec

**Date:** 2026-04-29  
**Status:** Approved

---

## Overview

Add three features to the Breaks landing site:
1. `/story` — "Why I built Breaks" narrative page
2. `/press` — Press kit page with blurbs, asset downloads, contact
3. Donation FAB — floating Ko-fi + GitHub Sponsors button, site-wide

All follow the existing design system: Geist Sans/Mono, dark palette, `.glass` cards, `.btn-primary`/`.btn-ghost`, `--hair` borders.

---

## 1. `/story` Page

**Route:** `src/pages/story.astro`  
**Pattern:** Uses existing `Prose.astro` component (same as privacy/terms/cookies).

**Props:**
- `eyebrow`: `"Story"`
- `title`: `"Built for the tab-closer in all of us."`
- `updated`: `"April 2026"`

**Content outline** (crafted narrative, ~500 words):
- **Hook:** The problem — modern work is constant context-switching; every tool wants your attention
- **The gap:** Existing Pomodoro apps are either bloated dashboards or ugly utilities; nothing quiet
- **The build:** Wanted something that lives in the menu bar, stays out of the way, just ticks
- **The result:** Breaks — free, sandboxed, no accounts, no cloud, no noise
- **Close:** Shipped it, using it daily, hope it helps

**Footer navigation:** Add `Story` link under "App" column in `Footer.astro`.

---

## 2. `/press` Page

**Route:** `src/pages/press.astro`  
**Pattern:** Custom page (not `Prose.astro`) — structured layout with sections.

**Header:**
- Eyebrow pill: `PRESS KIT`
- Title: `"Everything you need to write about Breaks."`
- Subtitle: contact line — `press@` or GitHub issues link

**Sections (in order):**

### App Blurbs
Three copy-paste text blocks in `.glass` cards with a "Copy" button each:
- **One-liner** (≤15 words): `"A quiet menu-bar Pomodoro for macOS. Free, open source, no account needed."`
- **Short** (2–3 sentences): Pomodoro + focus journal + streaks + hotkeys, lives in menu bar, sandboxed, MIT
- **Long** (1 paragraph): Full description covering all features, privacy angle, open source

Each block: monospace text in a `<pre>`-style card, `Copy` ghost button top-right.

### Download Assets
Grid of `.glass` cards (responsive 2→4 col):
- App Icon (favicon.svg)
- Demo GIF (media/demo.gif)  
- Screenshot — Timer (media/screenshot-timer.png)
- Screenshot — Stats (media/screenshot-stats.png)
- Screenshot — Settings (media/screenshot-settings.png)

Each card: thumbnail preview + filename + download link (`download` attribute).

### App Facts
Simple two-column fact list (label / value):
- Price: Free
- Platform: macOS 13.0+
- License: MIT
- Version: 1.1
- Bundle ID: com.gjinprelvukaj.Breaks
- Source: github.com/GjinPrelvukaj/Breaks

### Contact
Single line: open a GitHub issue or email placeholder.

**Footer navigation:** Add `Press` link under "App" column in `Footer.astro`.

---

## 3. Donation FAB

**Component:** `src/components/DonationFab.astro`  
**Placement:** Included in `Layout.astro` (site-wide, above `<slot />`).

**Behavior:**
- Fixed position: bottom-right, `bottom: 1.5rem; right: 1.5rem`
- Default state: white circle button (matches `btn-primary`), heart icon, `z-index: 100`
- Expanded state: panel expands upward showing two links — Ko-fi + GitHub Sponsors
- Toggle: click to open/close (no hover-only — mobile compatible)
- Close on outside click

**Visual:**
- Collapsed: `48px` circle, white fill, `#` heart SVG icon
- Expanded: `200px` wide panel above button, `.glass` background, two rows:
  - Ko-fi logo + "Buy me a coffee" → placeholder `#` link
  - GitHub heart icon + "Sponsor on GitHub" → `https://github.com/sponsors/GjinPrelvukaj`
- Both links open in new tab

**Note:** Ko-fi link is a placeholder (`#`) until user creates Ko-fi account. GitHub Sponsors link uses real username.

---

## Files to Create

| File | Action |
|------|--------|
| `src/pages/story.astro` | Create |
| `src/pages/press.astro` | Create |
| `src/components/DonationFab.astro` | Create |

## Files to Modify

| File | Change |
|------|--------|
| `src/layouts/Layout.astro` | Import + render `DonationFab` |
| `src/components/Footer.astro` | Add Story + Press links under App col; Support link under Author col |
| `src/components/SiteHeader.astro` | No change |

---

## Out of Scope

- No `/support` dedicated page
- No header nav changes
- No roadmap page
- Ko-fi account setup (user handles separately)
