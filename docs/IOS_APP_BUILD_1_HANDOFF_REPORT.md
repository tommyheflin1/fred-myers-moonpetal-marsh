# Fred iOS App Build 1 handoff report

Prepared: 2026-08-19

Fred now has a local unsigned iOS preparation preset, permanent Fred-owned Game
Center leaderboard identifiers, an offline-safe native adapter, pinned official
plugin build/validation tooling, entitlement and encryption helpers, an Xcode
26/iOS 26 validation handoff, and a separately acknowledged TestFlight upload
runner. The source preset contains no team ID, certificate, profile, key or
credential.

Windows can validate the source contract and create the exact Git bundle. It
cannot produce or validate the final iOS archive. The macOS runner must verify
the exact commit, build the official Game Center plugin, export the Xcode
project, validate the privacy manifest, build the Simulator target, archive
with the authenticated Apple team, inspect the signed Game Center entitlement
and upload exactly version 1.0 build 1.

App Store Connect setup must precede upload: create a separate Fred record,
confirm `com.flinsvault.fredmyers`, create both leaderboard records and verify
that build number 1 is unused. The currently open Snake Reactor App Store
Connect record must not be reused.

No signed archive, Simulator run, physical Apple-device test, Game Center
sandbox authentication, App Store Connect mutation, upload, TestFlight
processing, tester invitation, App Review submission or public release is
claimed by this local report.
