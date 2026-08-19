# M2 Fred mouth-clear rig and graphics uplift

Updated: 2026-08-19

## Outcome

App Build 1 Revision 21 gives Fred a clearer, more dimensional in-game rig and
fixes the remaining outfit overlap at his mouth. All four existing outfits now
use distinct five-point necklines that begin below a measured three-point jaw
exclusion zone. The torso, shoulder pieces, scarf, cape clasps and cape mount
were lowered with the collar, so accessories cannot creep back into Fred's
cheeks during landing, damage, tongue or reduced-motion poses.

Fred's face now has separated jaw and throat planes. Clothes use a recessed
silhouette, raised edge lighting, extra fitted panels and subtle woven depth so
they read as garments wrapped around a frog instead of flat pieces pasted on
top. These remain vector-based and bounded for the Windows, Android, and future
iPhone/iPad presentation paths.

## Deterministic fit contract

The rig measures the lower mouth plus both mouth corners against the matching
center and side collar anchors. Every outfit exposes the same five-point
neckline contract, a minimum idle gap of seven rig pixels, nineteen fit
features, fifteen fabric layers and seven tailored panels. The complete
23-state pose matrix retains at least the existing safe clearance under facing,
compression, leap, depth, boost, tongue, damage, failure and reset states.

All new state is presentation-only. Collision, difficulty, touch targets,
tongue targeting, rewards, lives, progression, Core 0.5.1 and `fred_save` v1
are unchanged.

## Validation

- Focused authored-rig suite: 1,133 passed, 0 failed.
- Complete deterministic matrix: 23 suites, 5,189 passed, 0 failed, including
  the original 34-check suite.
- One hundred pose traces stayed byte-identical.
- 10,000 rig updates completed in 409 ms with 4,620 bytes measured static
  growth, one retained object, and zero retained resources, nodes or orphans.
- Godot 4.7.1 headless import/parse passed.
- Readiness passed with 101 artifacts and all eight save fixtures.
- Computer Use inspected the real Godot window at 1280x720, 960x540, and
  reduced-motion 640x360. The customizer, Level 1 landing and MUNCH states kept
  Fred's complete mouth visible, limbs and gear attached, and the HUD/action
  row separated. The mouse exercised the same touch-first MUNCH path and ate
  Bug 1 successfully.

Committed visual evidence:

- `godot/docs/evidence/app-build-1-r21-attire-marsh_runner.png`
- `godot/docs/evidence/app-build-1-r21-attire-trail_scout.png`
- `godot/docs/evidence/app-build-1-r21-attire-moon_champion.png`
- `godot/docs/evidence/app-build-1-r21-attire-firefly_hero.png`

The focused implementation commit is
`c3e09aa64d7eb13a578f53ee24eec88dc1e29957`.

## Owner-build boundary

Revision 21's local Android development APK is 84,912,026 bytes with SHA-256
`2DA94078B21F2A9C0ADE46CADE02C89FDDA06E5742BF96C66AA84AAFC1C6B3C4`, version
`0.2.1-app-build-1-r21` (`20121`). It contains arm64-v8a and x86_64, requests
zero Android permissions, and uses only Godot's debug certificate.

Owner primary and backup saves remain byte- and timestamp-identical at
`20DE8645123BFECD973D3A1A1F82A4BE4F9731B3A015246C64908A07B40F1318` and
`89056C555969729AB89E17B78E82B0F632F55AA9FFF375B83DCBEC03C9793C76`.
No physical-device, iOS, signing, store, deployment, publication or release
acceptance is claimed. The configured remote is public, so this branch remains
local and unpushed.
