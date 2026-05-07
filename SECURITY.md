# Security

Breaks is a sandboxed macOS app with no network access, no accounts, no telemetry, and no third-party dependencies. The attack surface is small on purpose.

## Reporting a vulnerability

If you believe you've found a security issue, please **do not open a public issue or discussion**. Instead, report it privately:

1. Use GitHub's [private security advisory](https://github.com/GjinPrelvukaj/Breaks/security/advisories/new) flow, or
2. Email the maintainer directly at `asapgjin@gmail.com` with the subject line `Breaks security`.

I'll respond within 7 days and aim to ship a fix in the next minor release. If the issue is severe and being actively exploited, I'll publish a patch release sooner.

## Scope

In scope:

- The Breaks macOS app itself (Swift / SwiftUI code in this repo).
- The release artifacts published under the GitHub Releases page.
- The marketing landing page in `/web` and its deployed GitHub Pages site.

Out of scope:

- Issues in Apple's frameworks (`SwiftUI`, `UserNotifications`, `EventKit`, Foundation Models, etc.). Please report those to Apple via [Feedback Assistant](https://feedbackassistant.apple.com).
- Issues that require an attacker to already have local code execution on the user's machine.
- Sandbox-noise console messages from Apple frameworks (`audioanalyticsd`, `DetachedSignatures`, etc.) — these are harmless logs.

## Supported versions

Only the latest minor version is supported. Older versions don't get backports. Users should update to the [latest release](https://github.com/GjinPrelvukaj/Breaks/releases/latest).

## Disclosure policy

Once a fix is shipped, I'll publish a security advisory crediting the reporter (unless they prefer to remain anonymous).
