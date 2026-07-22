# Fred Myers M1 owner test

Double-click `Fred Myers M1 Owner Test.cmd`. The launcher verifies that Godot 4.7.1 is installed and opens the committed M1 project directly. It does not export, install, sign, publish, or deploy the game.

## Controls

- Start or continue: click the gold title button, or press Enter.
- Move: WASD or arrow keys.
- Boost: hold Shift while moving.
- Dive: Q.
- Surface: E.
- Pause or resume: P, Escape, or the visible mouse buttons.
- Retry after failure: R or the visible Retry button.

## Acceptance path

1. Confirm the title and controls are readable; start with the mouse.
2. Move across the lily pads and collect all three gold bugs.
3. Hold Shift while moving and confirm boost energy decreases; stop and confirm it recharges.
4. Press Q and confirm `Underwater`; press E and confirm `Surface`.
5. Pause and resume once by keyboard and once with the mouse.
6. Enter the dark `SAFE` circle and confirm the red predator cannot damage Fred there.
7. Contact the predator away from `SAFE` until the failure overlay appears; retry.
8. Cross the center lily pad and confirm `Midpoint saved`.
9. Close the window, relaunch from the same shortcut, choose Continue, and confirm Fred resumes at midpoint.
10. Collect the remaining bugs and reach the purple EXIT; confirm `Lily Leap Complete`.

Touch and controller behavior is deferred to M2. This is a local, non-production owner candidate only.
