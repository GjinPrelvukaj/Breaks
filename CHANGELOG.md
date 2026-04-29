# Changelog

All notable changes to Breaks will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project uses semantic versioning.

## [Unreleased]

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
