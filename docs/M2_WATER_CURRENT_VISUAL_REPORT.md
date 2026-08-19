# M2 realistic marsh-current visual uplift

Updated: 2026-08-18

## Outcome

Revision 20 replaces the repeated `>>` current symbols and straight water bars
with a deterministic, depth-aware marsh flow. Twenty-eight softly layered
streamlines use varied natural lengths, seven water lanes, curved highlights
and darker subsurface edges. Stronger gameplay currents move faster and add
restrained foam, while underwater flow becomes cooler, denser and slower.

Every lily pad and the safe perch now disturb the flow with fitted eddies and
downstream wakes. Odd/even route direction, explicit reversing currents and
underwater vertical pressure still come from the existing gameplay contract;
this component only renders their state. It does not change Fred's current
force, collision, lives, progression, objectives, save v1 or Core 0.5.1.

Reduced motion freezes streamline travel and eddy rotation while keeping the
same directional curves, wakes and depth information. No text or color-only
cue is required to read the flow direction.

## Deterministic evidence

- Focused water-current suite: 261 passed, 0 failed.
- Complete matrix: 23 suites, 5,145 passed, 0 failed.
- One hundred full streamline/eddy traces produced identical hashes.
- 10,000 current calculations completed in 187 ms with 680 bytes measured
  memory growth.
- All 28 streamlines stayed inside the marsh playfield with bounded widths;
  seven depth lanes and five or more distinct lengths remained present.
- Invalid stream/eddy indexes fail closed. Presentation state exposes zero
  save fields and cannot mutate collision.

Computer Use inspected two moving Level 100 frames at 1280x720 and a frozen
reduced-motion frame at 640x360. Streamlines visibly advanced, pad eddies and
wakes remained attached to the water, predator and objective readability held,
and the bottom touch controls did not overlap.

## Local package boundary

The exact implementation/package source is
`6833cc5f698d73cb225935117edd6a6fa6961b86`. Revision 20's local Android
development APK is 84,912,026 bytes with SHA-256
`2580F146554214BB2C35655CE92A57ABFDDF8322C3EC1114605DBE707370033E`, version
`0.2.1-app-build-1-r20` (`20120`). It contains arm64-v8a and x86_64, requests
zero permissions and uses only Godot's debug certificate.

This is local desktop/emulator-ready engineering evidence, not physical-phone,
iOS, store, production-signing, publication or release acceptance. The public
remote remains no-push/no-PR.
