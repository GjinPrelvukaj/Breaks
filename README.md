# Breaks

A small, opinionated Pomodoro app that lives in your Mac menu bar.

I built Breaks because every other timer either nagged me too much, hid in a Dock icon I never wanted, or treated breaks as an afterthought. This one is the opposite: it's quiet, it remembers what you were focused on, and it actually cares whether the break was any good.

![Platform](https://img.shields.io/badge/platform-macOS%2013%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-purple)

## What it does

- **Lives in the menu bar.** Click the icon, get a popover. No Dock clutter, no extra window.
- **Pomodoro the way you want it.** Tweak work / short break / long break lengths, sessions per cycle, sounds, auto-start behavior.
- **Global hotkeys.** Start/pause, skip, reset cycle — bind whatever keys you like. Works even when the app isn't focused (Carbon `RegisterEventHotKey`, not the flaky `NSEvent` route).
- **A focus journal that's actually useful.** Pick a focus for the day, label each block, mark it good / messy / skipped. It's quick — one tap during the break — and it adds up over the week.
- **Streaks with grace.** Miss a day? You get a small per-week pause-day budget before the streak decays. Life happens.
- **Idle detection.** If you walked away mid-session, Breaks notices and asks whether the time should still count.
- **Survives sleep.** Close the lid, come back, the timer is still where it should be. Driven by `endDate` plus `NSWorkspace` sleep/wake notifications, so it doesn't drift.
- **Sandboxed and small.** No analytics, no account, nothing leaves your machine. State lives in `UserDefaults`.

## Install / run

There's no release artifact yet — clone and build:

```sh
git clone git@gjinprelvukaj.github.com:GjinPrelvukaj/Breaks.git
cd Breaks
open Breaks.xcodeproj
```

Then Cmd+R in Xcode. Or from the CLI:

```sh
xcodebuild -project Breaks.xcodeproj -scheme Breaks -configuration Debug build
```

Requires macOS 13.0+ and a recent Xcode.

## Reset state

Everything is in `UserDefaults` under the bundle ID. To wipe settings, history, journal — the lot:

```sh
defaults delete com.gjinprelvukaj.Breaks
```

## How it's built

SwiftUI all the way down. The codebase is split into four small folders:

```
Breaks/
├── BreaksApp.swift              entry point + menu bar label
├── SharedStorage.swift          UserDefaults keys, widget snapshot
├── Models/
│   ├── BreakTimer.swift         the controller — modes, ticks, idle, sleep
│   ├── TimerSettings.swift      every user-tunable knob
│   ├── SessionHistory.swift     daily counts + streak math (with pause budget)
│   └── FocusJournal.swift       today's focus, per-block labels, weekly rollups
├── Views/
│   ├── TimerPopover.swift       routes between onboarding/stats/settings/timer
│   ├── TimerContentView.swift   main page — check-in, dashboard, panels
│   ├── TimerRing.swift          the circular progress ring
│   ├── OnboardingView.swift     three-step onboarding
│   ├── StatsView.swift          streak hero + heatmap + weekly review
│   ├── SettingsPanel.swift      collapsible settings sections
│   └── ReusableComponents.swift segmented pickers, hotkey rows, etc.
├── Style/                       button styles, hex colors, glass cards
└── System/
    ├── Hotkeys.swift            Carbon global hotkeys
    ├── LoginItemController.swift SMAppService wrapper
    └── NotificationPermissions.swift
```

A couple of design choices worth flagging if you go editing:

- **Tick decoupling.** `BreakTimer.remaining` only updates at action boundaries (start / pause / reset / fire). Per-second updates flow through a separate `TickClock` `ObservableObject`. That keeps the popover view tree from re-rendering every single second. If you add UI that needs the live countdown, observe `TickClock`, not `BreakTimer`.
- **Persistence per-property.** Each `@Published` setting writes itself in its own `didSet`. No central save call. New settings should follow the same pattern.
- **Pruning at write time.** `SessionHistory` is capped at 120 days, `FocusJournal` logs at 30 — pruned when you write, not when you read. Cold-start reads stay cheap.
- **Streak math.** `SessionHistory.streakSnapshot(pauseDayBudget:)` walks day-by-day from the earliest record forward and decays by 1 per missed day, except the first N missed days each ISO week are absorbed by the budget. That's the only non-trivial bit of logic in the app.
- **Explicit imports.** The project sets `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES`, so every file imports what it actually uses (`import Combine` for `@Published`, etc.). Don't rely on transitive imports through `SwiftUI`.

## Permissions

Breaks asks for:

- **Notifications** — so you actually know when a session ends. Granted from the onboarding screen.
- **Launch at login** — optional, via `SMAppService`. Toggle in settings.

That's it. No accessibility, no automation, no calendar, no network.

## Status

Used daily by me. Probably has rough edges if your workflow is very different. PRs and issues welcome — but be warned this is a personal app first.

## License

MIT. Do whatever you want with it.
