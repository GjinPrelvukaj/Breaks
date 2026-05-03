# Contributing to Breaks

Thanks for considering a contribution. Breaks is a personal project I use every day, but PRs and issues are welcome — fair warning, the bar for new features is "would I personally use this?"

## Before opening a PR

1. **Open or comment on an issue first** for anything non-trivial. A 30-second alignment beats a rejected PR.
2. **Build clean.** `xcodebuild -project Breaks.xcodeproj -scheme Breaks -configuration Debug build` should succeed.
3. **No new dependencies.** Breaks has zero third-party packages on purpose.
4. **No new entitlements** unless they unlock a concrete user-facing feature. The sandbox is the smallest viable surface; keep it that way.
5. **Match existing patterns.** Settings persist via per-property `didSet`. UI animations use the named tokens in `Style/DesignTokens.swift`. Prune at write time, not read time.
6. **Update CHANGELOG.md** under the `[Unreleased]` section if your change is user-visible.

## What I'm likely to merge

- Bug fixes with a clear repro.
- Polish on existing features (UI, microcopy, accessibility).
- Performance improvements with a benchmark or profile attached.
- Documentation fixes.

## What I'll usually push back on

- New top-level features without a prior issue and discussion.
- Cross-platform ports (Windows, Linux, iOS).
- Cloud sync, accounts, telemetry, analytics.
- Adding third-party Swift packages.
- Refactors that touch many files without a concrete reason.

## Code style

Swift defaults, SwiftUI idioms. Look at how nearby code is written — match it. Prefer terse, named identifiers over comments. Don't write what the code already says.

## Reporting bugs

Use the bug template. Include `Breaks` version, macOS version, and the shortest repro you can write.

## Reporting security issues

See [SECURITY.md](SECURITY.md). Don't open a public issue.
