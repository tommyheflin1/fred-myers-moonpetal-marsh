# Fred App Build 1 test report

Updated: 2026-08-19

## Scope and authorization

The owner's explicit next-phase instruction starts App Build 1 as a local
testing phase. Revision 21 packages Campaign 1 as a touch-only, age-five-targeted
PG family adventure with exactly 100 progressively harder levels. It retains
the direct playfield drag steering, large bottom action row, sporty Fred art,
six full-screen formations/backgrounds, coin-backed cosmetics, fresh-run Exit
contract, wildlife, Moonpetal Promise story, touch instructions,
child-readable Fred gear with measured three-point jaw clearance,
outfit-specific anatomical necklines, beveled fabric volume, soft edge finishing,
pose-aware drape and limb-mounted tailoring, continuous leap traversal over predators,
deterministic surface/underwater routes for naturally aquatic predators,
depth-aware danger collisions, upgraded Fred/predator/bug/fairy anatomy and
connected deterministic character articulation, layered vector body volume,
integrated joints and facial depth, clean label-free space above Fred and every
predator, realistic depth-aware marsh currents, an offline-safe native Apple
Game Center adapter and a reproducible unsigned iOS handoff.
The exact package source checkpoint and focused rig/graphics implementation is
`c3e09aa64d7eb13a578f53ee24eec88dc1e29957`. Core and save v1 remain
unchanged.

This build is not a public release, App Review submission, deployment or
physical-device acceptance result. The owner has authorized the first
TestFlight upload, but the signed Mac archive and App Store Connect processing
have not occurred. Source remains local and unpushed because the configured
GitHub repository is public.

## Artifact identity

- Local artifact: `builds/android/fred-myers-app-build-1-debug.apk`
- SHA-256: `2DA94078B21F2A9C0ADE46CADE02C89FDDA06E5742BF96C66AA84AAFC1C6B3C4`
- Size: 84,912,026 bytes
- Package: `com.flinsappvault.fredmyers.dev`
- Label: `Fred Myers App Build 1`
- Version: `0.2.1-app-build-1-r21` (`20121`)
- Minimum/target/compile SDK: 24/36/36
- Architectures: `arm64-v8a` and `x86_64`
- Orientation: landscape
- Requested Android permissions: zero
- Signing: Godot development/debug certificate, RSA 2048, APK Signature
  Schemes v2 and v3; no production keystore or release signing
- ZIP alignment: passed with 16 KiB page alignment validation

The monotonic version code preserves the existing development package identity
so an authorized owner phone can test an update without a downgrade or a
second Fred application. The 1024-pixel v3 platform master is the active Godot
and Android icon; the matching transparent Moonpetal Crest drives the one
Windows owner shortcut. The rebuilt xxxhdpi APK launcher icon was extracted
and visually inspected after packaging.

## Toolchain and package inspection

- Godot: `4.7.1.stable.official.a13da4feb`
- JDK: Eclipse Temurin/OpenJDK `17.0.19`
- Android build tools: `36.0.0`; `aapt2` 2.20-13193326
- ADB: 1.0.41, platform tools 37.0.0-14910828
- APK entries: 205
- Content scan: 68 text entries; no tests, tools, evidence, source-control
  metadata, signing material, credentials, private Windows paths, or secret-like
  content
- Package inspection retains Godot's optional missing themed-icon warning;
  standard and adaptive launcher-icon entries are present and the package gate
  passes.
- Debug signer certificate SHA-256:
  `3846f003df913682a497d7bf726439df432ed9d4f83cf99f46647079be8f6a87`

## Validation

- Godot headless import: passed.
- Complete deterministic matrix: 24 suites, 5,208 passed, 0 failed, using
  isolated temporary AppData. Headless default customization is memory-only so
  legacy gameplay suites cannot write owner economy data.
- Readiness: 120 artifacts, eight save fixtures, Core 0.5.1, Godot 4.7.
- Desktop/icon handoff: 43 checks passed before the final shortcut refresh.
- App Generation Engine/Apple readiness audit: 27 checks passed; all ten
  reusable foundation controls are present. Five of eleven Apple execution
  items are locally prepared and Apple remains `APPLE_PREPARATION_REQUIRED`.
- iOS preparation contract: ten checks passed for the unsigned iPhone+iPad
  preset, version 1.0 build 1, source/production bundle split, no source signing
  identity, official-plugin pin and two permanent Fred leaderboard IDs.
- iOS generated-export helpers: seven checks passed; official Game Center
  plugin validator: four checks passed; all three shell handoff/upload scripts
  passed syntax validation.
- Accurate App Store media: sixteen visually inspected RGB screenshots passed
  exact-size/hash validation at 2868x1320 (6.9-inch iPhone landscape) and
  2752x2064 (13-inch iPad landscape). Manifest SHA-256:
  `4DE7F4565416FBFCCE144ABD6C6D99C2D89898C504FA4E0F5B212952662875E0`.
- App Build 1 export contract: passed.
- Physical-device safety fixtures: 60 passed, 0 failed.
- Physical-device static safety contract: passed.
- Revision 21 physical-device state: `UNVERIFIED`; no phone install, control or
  capture is claimed. The earlier bounded ADB probe timed
  out before device classification. No serial, install, launch, or diagnostic
  mode was requested, and the probe was stopped cleanly with no ADB residue.
- Preflight tooling now prefers the verified bundled Python runtime and rejects
  the nonfunctional Microsoft Store execution alias uncovered during this run.
- Mobile Game Core remains version 0.5.1 at tree
  `288d87420c5694f80c071f00aa71a0b581f9f60c`.
- `fred_save` remains schema v1.

The focused leap suite passed 65/65. It proves open-water landing continues
from the exact endpoint with no teleport, life loss, checkpoint change or
countdown, and that a full fixed-tick arc clears a surface predator while
grounded contact remains hazardous. A real isolated 1280x720 touch-path review
used the visible `LEAP` action to cross a surface bass and froze after landing
with `LIVES 3` and the complete status `Same round, 3 lives, no restart
countdown.` The focused
Campaign 1 suite passed 1,328/1,328; the touch-only player-input
suite passed 22/22; the M2 foundation suite passed 750/750; the authored rig
suite passed 1,133/1,133; and the product-uplift suite passed 94/94. Four actual
1280x720 Godot customizer frames cover every mouth-clear fitted face/body gear
set, with distinct mesh, canvas, satin and reinforced-knit materials.
Live attire motion review also covers 960x540 and reduced-motion 640x360 idle,
leap/landing, surfacing, tongue, and boost states without gear drift or control
overlap. Revision 18 adds four distinct anatomical garment cuts, curved hems,
tapered sleeves, outfit-specific accessories, softer material-dependent edges,
subtler badges and smaller fitted eyewear. The Firefly cape now responds to
pose and reduced-motion state rather than reading as a rigid sheet. The title's
Campaign 1 / 100 levels / PG identity, Moonpetal Promise, three story cards and
six touch instructions remained readable. Level 1 showed one introductory
predator, no whirlpool, the five-second countdown and separated Objective,
Lives, Energy, Pause, Exit and action controls. Pointer review uses the exact
touch input path; real multitouch, a physical Android device and an iPad remain
separate owner/device gates. The attire improvements are presentation-only and
do not alter touch hit targets or phone/tablet layout.

The refined predator-depth/identity suite passes 338/338, including every aquatic phase,
100 identical fixed-tick traces, real touch-driven Fred depth traversal,
surface/underwater pass-under safety, same-depth damage, save-v1 exclusion and
a 10,000-update 14 ms loop with zero measured memory growth. Real 1280x720
Godot review confirmed readable surface, diving and underwater fish states.
Revision 19 removes the predator species/depth nameplates entirely while
retaining non-text waterline, ripple, bubble, depth-tint and silhouette cues.
Actual Level 100 lineup review at 1280x720 and phone-like 640x360 showed all
five species together: the
largemouth bass anatomy, long spotted pike, long barred muskie, scaled snake
and long-necked heron were visibly distinct without overhead names. Objective,
Lives, Energy, Pause, Exit and the bottom touch actions remained separated.
Fred's former overhead locomotion/location label remained absent in active play.

Revision 20 replaces repeated text chevrons and straight water bars with 28
curved, layered streamlines, depth-aware color/speed, restrained strong-current
foam, and fitted eddies/wakes around every lily pad and the safe perch. The
focused current suite passes 261/261, including 100 identical traces and a
10,000-calculation 187 ms loop with 680 bytes measured growth. Computer Use
inspected moving 1280x720 frames and a reduced-motion 640x360 frame; direction,
depth and obstacle wakes remained readable without obscuring Fred, predators,
objectives or the bottom touch controls.

Revision 21 lowers every torso, shoulder, scarf, cape clasp and cape attachment
below an explicit three-point jaw exclusion zone. Four distinct five-point
necklines now expose at least seven rig pixels of idle mouth clearance, while
separated jaw/throat planes, recessed cloth silhouettes, raised edge light,
weave and seven tailored panels add visible volume. The focused rig suite
passes 1,133/1,133 and its 10,000-update loop completed in 409 ms with zero
retained resource, node or orphan growth. Computer Use inspected the actual
customizer at 1280x720, 960x540 and reduced-motion 640x360, plus active Level 1
landing and touch-path MUNCH. Fred's complete mouth stayed visible, gear and
limbs remained attached, Bug 1 was eaten successfully, and no HUD/action
overlap appeared.

Revision 14 retains twelve inspectable Fred realism features and adds one typed
deterministic animation contract for all seven wildlife families. Computer Use
inspected the real Godot runtime at 1280x720, 960x540 and reduced-motion
640x360. Fish tails, dorsal/paired fins, gills, jaws and eyes; the snake spine,
head, jaw and tongue; heron neck, wings, feathers, legs and toes; four-wing
bugs/fairy; and Fred's subtle breathing/blink cues moved as connected parts.
Normal and constrained Level 1 retained separated Objective, Lives, Energy,
Pause, Exit and bottom touch controls with no button overlap. A pointer contact
also exercised the mobile screen-touch MUNCH path and mouth-anchored tongue.
These layers are presentation-only; 100 repeated 240-tick all-character traces,
the complete matrix and save checks prove no collision, reward, progression or
save-v1 change.

Revision 15 adds deterministic layered volume and integrated joint/facial depth
to every active rig. Fred now has sixteen inspectable realism features and a
nine-layer surface contract; wildlife families expose nine-to-eleven layers.
Computer Use inspected two live 1280x720 Level 100 frames plus 960x540 and
reduced-motion 640x360 Level 1. Fish scale/muscle lighting, fin roots, gills and
jaws; snake overlapping muscular scales and deeper head; heron contour feathers
and leg joints; segmented bugs/fairy; and Fred cheek, brow, belly and limb-joint
definition remained readable. Buttons stayed separated at every size, and the
constrained pointer check exercised the phone screen-touch MUNCH path. Moving
specular cues are deterministic and reduced to ten percent with reduced motion;
no surface field enters gameplay or save v1.

No phone was installed to, controlled, or captured. Emulator shader limits
from the earlier M2 run are not relabeled as App Build 1 phone acceptance.

The owner primary and backup gameplay saves remained byte- and timestamp-identical:

- primary: 592 bytes, `20DE8645123BFECD973D3A1A1F82A4BE4F9731B3A015246C64908A07B40F1318`;
- backup: 592 bytes, `89056C555969729AB89E17B78E82B0F632F55AA9FFF375B83DCBEC03C9793C76`.

## Owner gates

Android physical-device acceptance still requires one explicitly authorized
phone and the guarded serial-specific preflight. The workflow forbids implicit
target selection, uninstall, clear-data, downgrade, root, permission grant,
bootloader or broad log capture.

For Apple, create a separate Fred App Store Connect record rather than reusing
Snake Reactor's record, confirm `com.flinsvault.fredmyers`, create the two Game
Center leaderboards, verify $2.99 agreements/storefronts and then run the exact
Mac handoff. The owner has authorized signing and upload of version 1.0 build 1
to TestFlight only. Simulator, physical iPhone/iPad, sandbox Game Center,
archive privacy and TestFlight processing evidence remain open.

Milestone percentages do not increase for packaging or planning alone. App
Review submission, external/public availability and public release remain
separate protected future gates.
