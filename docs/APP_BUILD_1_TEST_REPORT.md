# Fred App Build 1 test report

Updated: 2026-08-18

## Scope and authorization

The owner's explicit next-phase instruction starts App Build 1 as a local
testing phase. Revision 14 packages Campaign 1 as a touch-only, age-five-targeted
PG family adventure with exactly 100 progressively harder levels. It retains
the direct playfield drag steering, large bottom action row, sporty Fred art,
six full-screen formations/backgrounds, coin-backed cosmetics, fresh-run Exit
contract, wildlife, Moonpetal Promise story, touch instructions,
child-readable mouth-clear Fred gear, continuous leap traversal over predators,
deterministic surface/underwater routes for naturally aquatic predators,
depth-aware danger collisions, upgraded Fred/predator/bug/fairy anatomy and
connected deterministic character articulation, a clean
label-free space above Fred's head, and a dormant Apple Game Center scoring adapter.
The exact product source checkpoint is
`2596a691198dcf8dbd08276721d77869151e459e`; Core and save v1 remain unchanged.

This build is not a production build, release, deployment, store submission,
or physical-device acceptance result. It remains local and unpushed because
the configured GitHub repository is public.

## Artifact identity

- Local artifact: `builds/android/fred-myers-app-build-1-debug.apk`
- SHA-256: `270160724F63B0C14D7DDAB6DB2348FB709949E5AF91E7068A30E25ECDD3B882`
- Size: 84,891,371 bytes
- Package: `com.flinsappvault.fredmyers.dev`
- Label: `Fred Myers App Build 1`
- Version: `0.2.1-app-build-1-r14` (`20114`)
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
- Complete deterministic matrix: 22 suites, 4,277 passed, 0 failed in 14.85
  seconds, using
  isolated temporary AppData. Headless default customization is memory-only so
  legacy gameplay suites cannot write owner economy data.
- Readiness: 92 artifacts, eight save fixtures, Core 0.5.1, Godot 4.7.
- Desktop/icon handoff: 43 checks passed before the final shortcut refresh.
- App Generation Engine/Apple readiness audit: 25 checks passed; all ten
  reusable foundation controls are present and Apple remains
  `APPLE_PREPARATION_REQUIRED`.
- App Build 1 export contract: passed.
- Physical-device safety fixtures: 60 passed, 0 failed.
- Physical-device static safety contract: passed.
- Revision 14 physical-device state: `UNVERIFIED`; no phone install, control or
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
suite passed 521/521; and the product-uplift suite passed 94/94. Four actual
1280x720 Godot customizer frames cover every mouth-clear face/body gear set.
Prior revision evidence also
covers constrained 960x540. The title's
Campaign 1 / 100 levels / PG identity, Moonpetal Promise, three story cards and
six touch instructions remained readable. Level 1 showed one introductory
predator, no whirlpool, the five-second countdown and separated Objective,
Lives, Energy, Pause, Exit and action controls. Pointer review uses the exact
touch input path; real multitouch, a physical Android device and an iPad remain
separate owner/device gates. The attire improvements are presentation-only and
do not alter touch hit targets or phone/tablet layout.

The refined predator-depth/identity suite passes 299/299, including every aquatic phase,
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
