# Fred App Build 1 test report

Updated: 2026-08-18

## Scope and authorization

The owner's explicit next-phase instruction starts App Build 1 as a local
testing phase. Revision 17 packages Campaign 1 as a touch-only, age-five-targeted
PG family adventure with exactly 100 progressively harder levels. It retains
the direct playfield drag steering, large bottom action row, sporty Fred art,
six full-screen formations/backgrounds, coin-backed cosmetics, fresh-run Exit
contract, wildlife, Moonpetal Promise story, touch instructions,
child-readable mouth-clear Fred gear with pose-aware drape, limb-mounted
tailoring and fitted material construction, continuous leap traversal over predators,
deterministic surface/underwater routes for naturally aquatic predators,
depth-aware danger collisions, upgraded Fred/predator/bug/fairy anatomy and
connected deterministic character articulation, layered vector body volume,
integrated joints and facial depth, a clean
label-free space above Fred's head, and a dormant Apple Game Center scoring adapter.
The exact package source checkpoint is
`b56005e1ec4f2024330bdeb11b1cb24d4dc2b4a8`; the focused attire implementation
is `128e7cda434fad814e9b26adb08749dcfb939738`. Core and save v1 remain unchanged.

This build is not a production build, release, deployment, store submission,
or physical-device acceptance result. It remains local and unpushed because
the configured GitHub repository is public.

## Artifact identity

- Local artifact: `builds/android/fred-myers-app-build-1-debug.apk`
- SHA-256: `46F188D68058B58D697A950CA3C0EE41BF5575AA6FAE242BAB429EAFF8CB3798`
- Size: 84,907,755 bytes
- Package: `com.flinsappvault.fredmyers.dev`
- Label: `Fred Myers App Build 1`
- Version: `0.2.1-app-build-1-r17` (`20117`)
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
- APK entries: 203
- Content scan: 67 text entries; no tests, tools, evidence, source-control
  metadata, signing material, credentials, private Windows paths, or secret-like
  content
- Package inspection retains Godot's optional missing themed-icon warning;
  standard and adaptive launcher-icon entries are present and the package gate
  passes.
- Debug signer certificate SHA-256:
  `3846f003df913682a497d7bf726439df432ed9d4f83cf99f46647079be8f6a87`

## Validation

- Godot headless import: passed.
- Complete deterministic matrix: 22 suites, 4,846 passed, 0 failed, using
  isolated temporary AppData. Headless default customization is memory-only so
  legacy gameplay suites cannot write owner economy data.
- Readiness: 93 artifacts, eight save fixtures, Core 0.5.1, Godot 4.7.
- Desktop/icon handoff: 43 checks passed before the final shortcut refresh.
- App Generation Engine/Apple readiness audit: 25 checks passed; all ten
  reusable foundation controls are present and Apple remains
  `APPLE_PREPARATION_REQUIRED`.
- App Build 1 export contract: passed.
- Physical-device safety fixtures: 60 passed, 0 failed.
- Physical-device static safety contract: passed.
- Revision 17 physical-device state: `UNVERIFIED`; no phone install, control or
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
suite passed 1,052/1,052; and the product-uplift suite passed 94/94. Four actual
1280x720 Godot customizer frames cover every mouth-clear fitted face/body gear
set, with distinct mesh, canvas, satin and reinforced-knit materials.
Live attire motion review also covers 960x540 and reduced-motion 640x360 idle,
leap/landing, surfacing, tongue, and boost states without gear drift or control
overlap. Revision 17 adds pose-aware folds, material-specific surface response,
anatomical armholes, real limb-mounted sleeves/bracers/knee wraps, and smaller
fitted eyewear. The title's
Campaign 1 / 100 levels / PG identity, Moonpetal Promise, three story cards and
six touch instructions remained readable. Level 1 showed one introductory
predator, no whirlpool, the five-second countdown and separated Objective,
Lives, Energy, Pause, Exit and action controls. Pointer review uses the exact
touch input path; real multitouch, a physical Android device and an iPad remain
separate owner/device gates. The attire improvements are presentation-only and
do not alter touch hit targets or phone/tablet layout.

The refined predator-depth/identity suite passes 337/337, including every aquatic phase,
100 identical fixed-tick traces, real touch-driven Fred depth traversal,
surface/underwater pass-under safety, same-depth damage, save-v1 exclusion and
a 10,000-update 14 ms loop with zero measured memory growth. Real 1280x720
Godot review confirmed readable surface, diving and underwater fish states;
the discovered low-screen label overlap was corrected and rechecked. A second
actual Level 100 lineup review showed all five named species together: the
largemouth bass anatomy, long spotted pike, long barred muskie, scaled snake
and long-necked heron were visibly distinct. Fred's former overhead
locomotion/location label remained absent in active play.

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

## Owner gate

The next owner action is to connect one authorized Android phone with USB
debugging, run the read-only preflight with its explicit serial, review the
result, and separately approve install/launch. The guarded workflow forbids
implicit target selection, uninstall, clear-data, downgrade, root, permission
grant, bootloader, or broad log capture.

Milestone percentages do not increase for packaging or planning alone. The
next Apple engineering action is a local unsigned iOS preset plus exact
macOS/Xcode handoff; production signing, Game Center/provider activation,
TestFlight, submission, publication, and release remain separate protected
future gates.
