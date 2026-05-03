# Changelog

All notable changes to Breaks will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project uses semantic versioning.

## [Unreleased]

## [1.4.0] - 2026-05-03

### Changed
- **Default accent is now amber (`#E8B56B`)** to match the Breaks brand. Existing installs that never customized their accent are migrated automatically; custom-picked accents are preserved.
- **Bigger, calmer timer ring.** Diameter 144 → 172, stroke 8 → 9, time text 34pt → 42pt, and the progress trim now eases with a spring instead of jumping.
- **Stats screen no longer shows a wall of zeroes for new users.** Until you finish your first focus block, the streak hero, heatmap, and weekly review are replaced by a small empty state that explains what shows up where.
- **Streak microcopy.** "Decay, not reset" is now "Miss a day, keep going" with a tooltip; "0/2 rest days used" is now "1 rest day this week" / "0 of 2 rest days left." "Focus days" is "Days with focus."
- **Primary buttons keep contrast on any accent.** The Start button now picks black or white text based on the tint's luminance, so light accents like amber stay legible.
- **Settings → More → Break suggestions.** The raw `symbol` text field is gone. Each row now has a curated 12-icon picker (Eyes, Stretch, Walk, Cooldown, Mindful, Hydrate, Outside, Breathe, Sun, Tea, Reset, Other).
- **Liquid Glass popover background** wired to the popover root. macOS 26 users get the real `glassEffect`; older versions fall back to `.ultraThinMaterial`.
- **Animation timings normalized** under three named tokens (`breaksQuick`, `breaksDefault`, `breaksGentle`) to make the app feel more rhythmically consistent. Spacing tokens added under `BreakSpacing`.

### Added
- **Quiet popover**: notifications no longer fire while the popover is open and you can already see the timer. The willPresent delegate suppresses banner + sound when the popover is visible, and resumes normal delivery when it's closed.

## [1.3.2] - 2026-05-03

### Changed
- Breaks AI now answers basic questions about the Breaks app itself (made by Gjin Prelvukaj, Swift/SwiftUI, MIT licensed, runs locally, where the source code lives, etc.) instead of dodging with an identity statement when the question is about the app rather than your journal.

## [1.3.1] - 2026-05-03

### Changed
- Breaks AI now knows the app was made by Gjin Prelvukaj and answers questions about the creator/author directly instead of dodging.

## [1.3.0] - 2026-05-03

### Added
- **Breaks AI**: on-device weekly review and conversational journal Q&A. Reads your focus journal locally via Apple Foundation Models — no servers, no telemetry, no API keys. Available on macOS 26 with Apple Intelligence enabled.
  - **Weekly summary**: a 3-sentence reflection plus one specific suggestion, generated once per ISO week and cached.
  - **Ask Breaks AI**: collapsible chat. Ask things like "when did I focus best?" or "which project took the most time?". Suggestion chips, multi-turn context, off-topic refusal.
- **Per-project stats**: tap any project in the weekly review to expand a card with week / month / all-time minutes, a 7-day mini chart, and good / messy / skipped outcome counts.
- **Cycle templates**: three new presets — 52/17, Flowtime (90/20), Ultradian (90/30) — alongside Pomodoro, Deep Work, and Quick.
- **Markdown export**: Settings → More → Data → "Export focus journal as Markdown…" dumps your full journal grouped by day with outcomes, projects, and totals to a file you choose. Stays on your machine.

### Changed
- Sandbox file entitlement upgraded from user-selected read-only to read-write, scoped to user-picked save destinations only (needed for Markdown export).

## [1.2.1] - 2026-04-30

### Removed
- Focus / Do Not Disturb shortcut automation. The Shortcuts URL bridge was a workaround — macOS has no public API for an app to toggle Focus directly, so the feature is gone rather than papered over.

## [1.2.0] - 2026-04-29

### Added
- Per-project focus tracking. Tag focus blocks with a project; weekly review breaks time down by project.
- Optional Focus / Do Not Disturb automation via user-configured Shortcuts. Starting a work session can run a "Focus On" shortcut; ending/skipping/pausing can run a "Focus Off" shortcut.
- `CHANGELOG.md` at repo root.

### Changed
- Settings moved from a popover panel into a native macOS Settings window (`NavigationSplitView`) with sidebar grouping, glass titlebar, page-level title and caption per tab, and scroll-blur titlebar.
- Sidebar shows app icon, version, About / Help / Feedback, and Quit pinned at the bottom.
- Project rows redesigned as cards with color stripe, drag-to-reorder, and right-click context menu.
- Settings window switches the dock icon on while open so the window is reachable via Cmd-Tab.
- Custom About panel with app credits and copyright.

## [1.1.0] - 2026-04-28

### Added
- Editable break suggestion library.
- Optional Calendar export for completed focus sessions.
- Website link in the app footer.

### Changed
- App and website version metadata updated for v1.1.

## [1.0.0] - 2026-04-28

### Added
- Initial menu-bar Pomodoro release.
- Focus journal, streaks, idle detection, sleep/wake recovery, global hotkeys.
