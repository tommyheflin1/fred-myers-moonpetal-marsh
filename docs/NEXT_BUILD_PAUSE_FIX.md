# Next-build Pause fix — 2026-08-30

## Outcome and delivery boundary

Owner request: "the pause button doesn't work; fix and add to the next build."

Fixed locally on `codex/fred-next-build-pause-fix` in
`C:\Users\tommy\OneDrive\Documents\The Flins App Vault\fred-myers-next-build-pause-fix`.
Use this candidate (or a descendant containing this change) for the next Fred
Apple build, not the unchanged Build 4 checkout.

Starting commit: `c261e37979b0f306ff86ce7e450922a2c919c2f0`.
Starting tree: `543b7800ad8437f663b32f357c13716b983aaace`.
The separate `fred-myers-app-build-2` checkout remains at that commit. No Apple
access, archive, signing, upload, submission, or public Git push was performed.
No claim is made about today's live App Store status. Build/version metadata is
unchanged; the next unused build number must be verified through the established
Apple delivery workflow when the owner authorizes that build.

## Reproduced cause and fix

Fred processed `InputEventScreenTouch` and the mouse compatibility event generated
for the same finger tap. Pause is a toggle, so the second event immediately
unpaused the game. Existing tests called the touch handler alone and missed the
paired-event failure. Held movement/Boost also survived manual Pause.

- Disable both engine mouse/touch emulation settings: Fred already provides its
  own shared native-touch / physical-mouse handling.
- Ignore pointer events marked `InputEvent.DEVICE_ID_EMULATION`, even if a runtime
  or export re-enables compatibility emulation. No timing-based debounce is used.
- Route manual pause/resume through one helper, clearing contacts, steering,
  Boost holds, pointer state, and leftover fixed-step time.
- Preserve Resume after foregrounding, countdown pause, top-button toggle,
  paused Exit, real desktop mouse input, and simultaneous native touches.

Godot's documented [emulated input device marker](https://docs.godotengine.org/en/4.3/classes/class_inputevent.html#class-inputevent-constant-device-id-emulation)
was checked against the installed Godot 4.7.1 runtime. The new tests use both
native/emulated event orders and `Input.parse_input_event`, with physical-window
coordinate conversion so stretched and headless windows exercise the right target.

## Executed validation

All runs used isolated fictional APPDATA/LOCALAPPDATA under this checkout's
ignored `builds/pause-validation` directory, never the owner's save directory.

| Gate | Result |
| --- | --- |
| Same corrected regression suite against unchanged starting main/settings | 19 passed / 17 failed, confirming the bug |
| Fixed focused Pause suite | 36 passed / 0 failed |
| All Godot deterministic suites | 29 suites; 8,384 passed / 0 failed |
| Golden Egg route (included above) | 122 passed / 0 failed |
| Game Center adapter (included above) | 42 passed / 0 failed |
| Godot 4.7.1 headless import | Passed |
| Readiness | 145 artifacts, 8 fixtures, Core 0.5.1 |
| Python tooling scripts, invoked directly | 5 scripts; 76 checks passed |
| Rendered desktop Pause/Resume regression | 37 passed / 0 failed, including screenshot capture |
| Rendered wide-phone window (1792x828) | 36 passed / 0 failed |
| Rendered tablet window (1366x1024) | 36 passed / 0 failed |

Rendered screenshot `builds/pause-validation/pause-overlay-1280x720.png` was visually
inspected: the centered Marsh Paused overlay and Resume button are readable, the
touch action wheel is hidden, and Pause/Exit remain unobscured. Logs are retained
under `builds/pause-validation`. This is local desktop/synthetic-touch evidence,
not a physical iPhone/iPad acceptance claim.

The first resized rendered reruns reported desktop GLES shader-cache read
errors despite passing the input assertions. Both were repeated with fresh
isolated test profiles and passed with empty stderr. No game graphics setting
was changed. Final import also regenerated an untracked capture-tool UID from
cache; this unrelated generated file was removed before committing.

The regression is included in readiness CI. The existing Core, save schema,
gameplay content, artwork, Golden Egg rules, and export identities are unchanged.

## Owner-data and shortcut integrity

Before/after checks matched bytes, SHA-256, and last-write timestamps:

| File | Bytes | Last write UTC | SHA-256 |
| --- | ---: | --- | --- |
| fred_save.json | 592 | 2026-07-22T03:53:46.7782318Z | `20DE8645123BFECD973D3A1A1F82A4BE4F9731B3A015246C64908A07B40F1318` |
| fred_save.backup.json | 592 | 2026-07-22T03:53:32.9493944Z | `89056C555969729AB89E17B78E82B0F632F55AA9FFF375B83DCBEC03C9793C76` |
| Fred Myers Owner Test.lnk | 3,130 | 2026-08-25T03:22:43.5491375Z | `F75617364EAD7899D8ECEB2A8D3D87CED2A73F2FA6D3F9347182ECF563A28D2A` |

No duplicate shortcut was created and the pinned desktop candidate was not
retargeted. Test-owned Godot processes exited. Disposable test-user data was
removed after retaining the screenshot and logs. No milestone credit changed.

## Next-build physical acceptance

After the next authorized Apple build includes this commit:

1. On an iPhone and iPad, start play and tap Pause once. Keep hands off for at
   least five seconds; Fred, predators, lives, energy, and the countdown must stop.
2. Tap Resume once, then repeat Pause/Resume at least six times. No freeze or
   immediate auto-resume should occur.
3. Hold movement and Boost with two fingers; tap Pause with another finger.
   Release all fingers, then Resume. Neither movement nor Boost should stay held.
4. Pause during the countdown and confirm it resumes from the same value.
5. Background and foreground the app, then tap Resume. Confirm gameplay recovers.
6. Rotate between both landscape directions and repeat Pause/Resume. Verify the
   top buttons and overlay targets still align.
7. Pause, tap Exit, and start again. A fresh run should start while earned coins
   and cosmetics remain intact.

Use the established repeatable Apple workflow for the next delivery. Do not
reuse the already-submitted Build 4 artifact or silently overwrite its number.
