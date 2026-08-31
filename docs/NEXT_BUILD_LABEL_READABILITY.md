# Next-build label readability — 2026-08-31

## Focused continuation

This local graphics pass starts from `eae6d56e98dea50ef759380f11b0703b973217f0`
(tree `984028b029ed85fcec64aac947153e90d7c0e0f6`) on
`codex/fred-next-build-pause-fix`. It addresses the world-caption crowding found
in the preceding Level 71 review and the clipped footer feedback. Earlier Fred,
attire, predator, botanical, collectible and whirlpool artwork remains intact.

The canonical `shared-build-process` skill guided protected-baseline checks,
isolated test data, complete regression and separate local/device/Apple evidence.
Its exact-candidate audit still reports `MIGRATION_REQUIRED`: 22 differences
against `1.6.0-candidate.1`. This pass does not migrate release tools or claim
the candidate is ready for Apple delivery.

## Presentation changes

- World captions are drawn above scenery and actors, below action cues, HUD and
  overlays. Safe-perch and exit captions retain their original positions; bug,
  fairy and whirlpool captions use nearby clear positions when crowded.
- Placement measures the actual font and reserves whole-level motion envelopes,
  other captions, the depth indicator, touch controls and camera margins. A
  bounded one-level cache keeps offsets stable during movement and collection.
  Thin muted leader lines connect displaced captions to their objects. There
  are no new label boxes or smaller world-label fonts.
- The Level 71 second-whirlpool caption no longer sits beneath the safe perch.
  All 100 level layouts retain their required captions. Scenery is a placement
  preference; moving predators can still pass behind text, which is drawn above
  them. This is not a claim that all moving artwork is mutually non-overlapping.
- Footer feedback wraps to at most two measured lines inside the existing
  340-by-42 touch box (410-by-42 desktop box). Three-pixel vertical and eight-pixel
  horizontal insets preserve the border. Font size never drops below 13 logical
  pixels. All 100 chapter messages and the tested save notices remain complete;
  exceptional overlong input gets a visible ellipsis rather than silent clipping.

`marsh_label_layout.gd` is presentation-only, deterministic app-owned code. It
adds no dependencies, textures, nodes, physics, timers, random state or growing
history. Actor positions, danger radii, controls, progression, Golden Egg rules,
rewards, save schema, Game Center, audio, app identity and build number are not
changed. Drawing helpers keep their original labels by default for detail-sheet
review, while the game scene uses the separate caption layer.

## Actual renderer review

- [Level 10 phone: fairy and reversed route](evidence/next-build-labels-2026-08-31/level10-reverse-phone-1792x828.png)
- [Level 17 phone: early whirlpool captions](evidence/next-build-labels-2026-08-31/level17-phone-1792x828.png)
- [Level 71 tablet: busy-scene caption separation](evidence/next-build-labels-2026-08-31/level71-tablet-1366x1024.png)
- [Level 71 phone: later movement sample](evidence/next-build-labels-2026-08-31/level71-late-motion-phone-1792x828.png)
- [Level 72 phone: reversed busy route](evidence/next-build-labels-2026-08-31/level72-reverse-phone-1792x828.png)
- [Tablet: complete two-line save feedback](evidence/next-build-labels-2026-08-31/long-feedback-tablet-1366x1024.png)
- [Level 71 phone: Pause overlay](evidence/next-build-labels-2026-08-31/level71-paused-phone-1792x828.png)

These are real Godot drawing-code captures at the named SubViewport resolutions,
using the existing letterbox layout and isolated fictional data. Hazards and
audio are disabled for review; they are not physical-device screenshots or a
completed player-controlled run. The long save notice is deliberately injected
review text, not damage to an owner save. All seven scenes above were visually
inspected. Capture generated 17 PNGs with exit 0 and clean stderr; the other ten
are retained under ignored `builds/label-review/render-first` with capture logs.
All seven detail sheets (Fred builds, attire, predators, water motion, botanicals,
collectibles and whirlpools) are SHA-256-identical to the preceding review.

## Executed validation

| Gate | Result |
| --- | --- |
| Complete Godot regression | 35 suites, each exit 0; 54,571 assertions passed, 0 failed |
| New caption/footer suite, included above | 4,541 passed, 0 failed |
| Pause input, included above | 36 passed, 0 failed |
| Golden Egg Level 10, included above | 122 passed, 0 failed |
| Game Center adapter, included above | 42 passed, 0 failed |
| Python tooling | 5 scripts; 76 checks passed |
| Readiness | 159 artifacts, 8 fixtures, Core 0.5.1 |
| Actual renderer | 17 PNGs; exit 0; clean stderr |
| Redraw state guards | Session save, actor positions, level, collected items and simulation time unchanged over 120 redraws each on Levels 10 and 71 |
| Render node growth | 0 in both measured scenes |
| Patch formatting | `git diff --check` passed |

The new suite covers 100 levels in touch and non-touch modes, both motion modes,
61 time samples per layout and five camera-extreme offsets. It checks stable
caption slots, motion-envelope containment, caption/control separation,
whirlpool/perch clearance, collected-caption removal and full footer text. Ten
thousand cached caption snapshots took 408 ms with zero retained memory growth.
CI and readiness include the new files; no remote CI ran.

Final logs are in `builds/label-review/verified-validation`. Twelve pre-existing
suites emitted ObjectDB/resource-at-exit diagnostics; none reported assertion,
parse or script failures. The new suite has clean stderr. A temporary PowerShell
log filter falsely classified three passing assertions containing the words
"fail closed" or "fail the rig contract"; a case-sensitive, line-anchored audit
confirmed zero failed suites, with every process separately reporting exit 0.
Earlier iterations caught and corrected typed-local compilation issues and
two footer-fit failures before this final validation. Editor import regenerated
an unrelated App Store capture UID from cache; that incidental file was removed.

The Windows/NVIDIA T1000 renderer measured game-draw CPU p95 at 14.780 ms for
Level 10 and 18.227 ms for Level 71. Caption passes averaged 0.132/0.137 ms
respectively. These are CPU drawing-preparation measurements, not GPU/frame
time or phone performance. Busy-scene preparation alone exceeds a 16.67-ms
60-Hz budget; device profiling and any necessary optimization remain open.

## Protected state and next acceptance gates

- Godot 4.7.1, Core 0.5.1 and `fred_save` v1 remain pinned.
- Submitted Build 4 remains clean at `c261e37979b0f306ff86ce7e450922a2c919c2f0`,
  tree `543b7800ad8437f663b32f357c13716b983aaace`.
- Owner primary save SHA-256:
  `20DE8645123BFECD973D3A1A1F82A4BE4F9731B3A015246C64908A07B40F1318`.
- Owner backup save SHA-256:
  `89056C555969729AB89E17B78E82B0F632F55AA9FFF375B83DCBEC03C9793C76`.
- Existing desktop shortcut SHA-256:
  `F75617364EAD7899D8ECEB2A8D3D87CED2A73F2FA6D3F9347182ECF563A28D2A`.
- No shortcut redirection, GitHub push, signing, Apple upload, TestFlight
  assignment, App Review submission or public release ran.

Owner visual preference, physical iPhone/iPad readability and frame pacing,
native Pause/background/Resume and rotation, and release-tool migration remain
separate gates. Local Golden Egg tests do not prove a website leaderboard entry.

For reproduction, redirect APPDATA/LOCALAPPDATA to fresh ignored test folders,
run every `godot/tests/run_*.gd`, the five `tools/tests/test_*.py` scripts and
`python tools/validate_readiness.py`. Render with:

```text
godot --disable-vsync --fixed-fps 60 --path godot --script res://tools/capture_next_build_graphics.gd -- --output=<absolute-review-folder>
```
