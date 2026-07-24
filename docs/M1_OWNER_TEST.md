# Fred Myers M1 owner test

Double-click `Fred Myers M1 Owner Test.cmd`. The launcher verifies that Godot 4.7.1 is installed and opens the committed M1 project directly. It does not export, install, sign, publish, or deploy the game.

To create or repair the Windows desktop shortcut, run `tools/install_m1_desktop_shortcut.ps1` with PowerShell. The installer verifies the saved shortcut target before reporting success.

## Controls

- Start or continue: click the gold title button, or press Enter.
- Move: WASD or arrow keys.
- Aim/eat: face with movement, then press F; or right-click the target.
- Leap: Space or left-click a landing direction.
- Boost: hold Shift while moving.
- Dive: Q.
- Surface: E.
- Pause or resume: P, Escape, or the visible mouse buttons.
- Retry after failure: R or the visible Retry button.

## Acceptance path

1. Confirm the title and controls are readable; start with the mouse.
2. Move within tongue range of a gold bug, face it, and press F. Confirm the
   tongue reaches the selected bug, the counter advances once, and cooldown
   spam cannot collect it twice. Repeat once with right-click aim.
3. Hold Shift while moving and confirm boost energy decreases; stop and confirm it recharges.
4. Press Q and confirm `[STATUS] Fred is underwater.`; press E and confirm `[STATUS] Fred is at the surface.`.
5. Pause and resume once by keyboard and once with the mouse.
6. Enter the dark `SAFE` circle and confirm the red predator cannot damage Fred there.
7. Contact the predator away from `SAFE` until the failure overlay appears; retry.
8. Cross the center lily pad and confirm `[SAVED] Midpoint is safe.`.
9. Close the window, relaunch from the same shortcut, choose Continue, and confirm Fred resumes at midpoint with a `[RESTORED]` or `[RECOVERED]` notice.
10. Eat the remaining bugs with the tongue and reach the purple EXIT; confirm
    `Lily Leap Complete`.
11. On Level 10, confirm the fairy appears once. Below three lives, eat it for
    exactly one life; at three lives, confirm `[LIVES FULL]` and that the fairy
    remains unconsumed.

## Save-status checks

- A fresh test shows `[NEW GAME]`; it must not claim progress was restored.
- A normal relaunch with a valid save shows `[RESTORED]`.
- Recovery from a valid backup or interrupted save shows `[RECOVERED]`.
- A damaged fictional test save shows `[SAFE START]`, never a restored-progress message.
- A blocked save shows `[SAVE BLOCKED]` without a file path or technical error code.
- Status notices remain readable without blocking movement, buttons, pause, or retry.

Controller and touch adapter actions are automated only; physical-device
acceptance remains deferred. This is a local, non-production owner candidate
only.
