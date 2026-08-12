# Fred Myers desktop owner test

Use the single Windows desktop shortcut named `Fred Myers Owner Test`.

Its icon is the unique Moonpetal Crest: Fred's two-eyed frog face, moonpetal
crown, crescent moon, teal water curl, and gold-edged notched lily-pad shield.
The transparent outer silhouette is deliberately organic rather than a square
photo, while the linked platform master remains safe for future store masking.

The shortcut is pinned to one exact clean Git commit and a SHA-256 candidate
manifest created from every tracked file. Before it opens the game, the
launcher verifies the manifest hash, candidate commit, candidate file hashes,
Godot 4.7.1, Mobile Game Core 0.5.1 tree, project entry point, and save-v1
boundary. If a pinned file or the manifest has changed, the launcher stops and
asks for a refreshed owner link.
It does not sign for production, publish, deploy, or connect an account. App
Build 1 is now active as a separate local Android debug-testing phase; the
desktop shortcut remains the exact-candidate Windows owner-review path.

## Controls

- Start or continue: click the gold title button, or press Enter.
- Move: WASD or arrow keys.
- Aim and eat: face the target and press F; right-click is the pointer path.
- Leap: Space or left-click a landing direction.
- Boost: hold Shift while moving.
- Dive: Q.
- Surface: E.
- Pause or resume: P, Escape, or the visible Pause/Resume buttons.
- Failure choices: use the visible `Try Again?` or `Go Home` buttons.

## Effective desktop acceptance path

1. Confirm the title art, menu music, controls, local leaderboard, and offline
   notice are readable. Start and allow the five-second countdown to finish.
2. Move in both directions. Confirm Fred, nearby lily pads, bugs, fish, snake,
   birds, hazards, objective, lives, energy, status, and Pause remain readable.
3. Move within the close tongue-assist boundary of a bug, face it, and press F.
   Confirm Fred visibly eats it once. Press F outside the eligible boundary and
   confirm the miss does not collect a bug or double-trigger a reward.
4. Exercise leap, boost, dive, surface, pause, and resume. Confirm no action
   changes while the countdown or pause overlay owns input.
5. Take one danger hit. Confirm exactly one life is removed and Fred remains on
   the same level, returning to the level start or earned midpoint checkpoint.
   Repeat with a second life; the full failure screen must not appear early.
6. At zero lives, confirm the full-screen `OH NO FRED!!!` choice appears.
   `Try Again?` starts level one with three lives; `Go Home` returns to the title.
7. Finish an odd level and confirm the next even level runs right to left.
   Continue another transition and confirm the route direction alternates and
   the marsh background treatment changes without overlapping the HUD.
8. On every tenth level, eat the one eligible fairy and confirm exactly one
   extra life is added even when Fred already has three lives. The campaign cap
   remains thirteen lives; ordinary damage never erases previously stacked
   lives except by consuming one life per accepted hit.
9. Cross a midpoint checkpoint, close the game, relaunch the same shortcut,
   choose Continue, and confirm the valid checkpoint and life total restore.
10. Resize the window. Confirm objective, lives, Pause, energy, status, and the
    phone-oriented touch targets stay separated and inside the play area.

## Evidence boundaries

This shortcut is the desktop owner-review candidate. Automated keyboard and
synthetic touch coverage support it, but owner control feel remains your human
acceptance. The local App Build 1 Android debug APK and guarded phone preflight
remain separate evidence; neither is a physical-phone pass. Store packaging,
signing, publication, and physical-device acceptance remain protected gates.
