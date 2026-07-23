# M2 progression and identity foundation

## 100-level intensity contract

Fred's campaign is planned as ten chapters of ten levels. `FredLevelIntensity`
returns a deterministic profile for every level from 1 through 100. Pressure
increases slightly and monotonically; chapters never reset difficulty. The
first ten levels remain welcoming, while levels 81-100 sustain and continue
the highest intensity band. Accessibility assists may widen reaction windows
without changing objectives or progression credit.

This slice defines tuning contracts only. It does not claim that 100 authored
levels exist yet.

## Low-friction identity contract

Fred always starts offline as a guest. On supported phones, the preferred path
is the platform's existing game identity:

- Apple devices: offer Game Center automatically and unobtrusively.
- Cross-platform App Vault profile: offer Sign in with Apple only when account
  linking or cross-device services are requested.
- Android devices: provide the equivalent Google Play Games adapter later.

Account setup is skippable. Fred never stores passwords, Apple credentials,
authorization codes, identity tokens, or refresh tokens in `fred_save`.
Provider tokens belong only in platform-secure runtime storage and are
exchanged with the shared backend for a revocable opaque profile identifier.
Cloud sync, leaderboards, and production authentication remain disabled until
their privacy, security, backend, and device gates are approved.

## Windows Swift boundary

Swift on Windows can compile and test pure shared value types, request-state
machines, and fictional token-response fixtures. Windows cannot validate
GameKit, AuthenticationServices, Apple entitlements, App Store signing, or
native Apple sign-in presentation. Those require an Apple Developer account,
owner-controlled credentials, Xcode, and an Apple device or simulator.
