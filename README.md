# Your Farm With Unicorns

Stage 2 source prototype of an offline, landscape-only iPad game. SwiftUI provides large touch controls and profile screens; SpriteKit renders the farm and riding areas. No third-party app dependencies, accounts or gameplay network calls.

## Try the updated project on your Mac

1. Close the older project in Xcode. Download the latest ZIP from the repository's **Code → Download ZIP** menu and unzip into a new folder.
2. Open the new `YourFarmWithUnicorns.xcodeproj`, not the older downloaded copy.
3. Select the shared **YourFarmWithUnicorns** scheme and a named **iPad simulator** (not My Mac or Any iOS Simulator).
4. Press **⌘R**. Simulator builds do not need a signing team. Do not delete the app from the simulator if you want to keep existing player saves; this version uses the same bundle identifier and save format.
5. Press **⌘U** to run the 15 model tests in Xcode.

Requires a Mac with Xcode 15+ and an installed iOS simulator runtime. A physical iPad requires your own signing team and unique bundle identifier.

```sh
xcodebuild -project YourFarmWithUnicorns.xcodeproj -scheme YourFarmWithUnicorns -showdestinations
xcodebuild -project YourFarmWithUnicorns.xcodeproj -scheme YourFarmWithUnicorns -destination 'platform=iOS Simulator,id=YOUR_IPAD_SIMULATOR_UUID' -derivedDataPath DerivedData build test
```

## What Stage 2 adds

- Exactly 13 horses selectable **only at stables**, with painted draft portraits. Roo is a bay mare, Daisy a Shetland and Bruno a larger Clydesdale. Selecting a horse transfers the profile's existing pad, saddle and bridle without changing its rider or outfit.
- Six coordinated palettes, illustrated rider previews, and optional tack toggles at the wash bay. All horses can be ridden immediately without grooming or tack.
- A fixed whole-arena view, directional joystick, independent Walk/Trot/Canter buttons, eight directional facings and temporary four-phase procedural gait animation.
- Three similarly simple preset courses, all available immediately. Cross a jump at a suitable angle to jump automatically; yellow highlights and arrows guide the approach. Completing all three jumps gives a chime, sparkles and tick while riding continues.
- Occasional harmless knocked poles and run-outs. Tap a fallen pole to replace it; retries are unlimited and there is no score or penalty.
- Automatic round-yard riding with Walk/Trot/Canter, Change Direction and Ground Poles. Direction changes slow to a stop, reverse and resume the previous gait. A full circuit at one gait or over poles records that activity.
- Riding pauses when settings open or the app becomes inactive. Home exits either riding scene immediately and stops the scene's input and updates.

The simulator check for Stage 1 was reported as working by the user. **The Stage 2 iPad build, UI layout, audio playback and touch behavior have not yet been run here.** This Linux workspace compiled and passed all 15 pure-Swift model tests and parsed the app sources for Swift syntax. These checks do not resolve Apple SDK APIs or substitute for an Xcode build.

## Simulator checks for Stage 2

1. At Stables choose Daisy, Bruno and Roo in turn. Confirm 13 choices and the correct selected name on the farm map. Horse selection should not appear in any other area.
2. At Wash Bay turn on pad, saddle and bridle, select each palette, and edit rider/name. Revisit Stables, switch horse and enter Arena: tack and rider preferences should remain. Horses have different visual sizes but identical movement speeds and jump difficulty.
3. In Arena drag the joystick in all eight directions. Release it to stop; switch among the three gaits. The entire course must stay visible without camera following.
4. Ride across each highlighted jump following its arrows, rather than along the pole. A correct approach should trigger a hop automatically. Jump all three in any order to see the celebration, then choose another course or keep riding.
5. Jump repeatedly until an occasional pole falls or the horse takes a small detour. Tap the fallen pole to reset it. There should be no failure dialog or penalty.
6. In Round Yard select each gait, wait a full circuit, toggle Ground Poles, and change direction. The horse should slow, turn and resume the selected gait. Leave with Home at any point.
7. Open Settings during a ride and confirm the horse pauses. Turn Sound Effects off and complete a course/circuit: visual feedback should still work without a chime. Background music is not supplied yet; its preference is retained for later integration.
8. Switch children and relaunch the app. Each child's horse, tack, outfit and sound preferences should stay separate. Repeat with networking off, and check a small and a large landscape iPad.

Arena course IDs and round-yard gait/pole activity IDs are saved per child and local day for Stage 4. This stage does not award ribbons or unlock the wand/flight. Re-entering a riding scene starts fresh course/circuit state without erasing daily activity history.

## Core tests in this cloud workspace

The model is also a small Swift package containing only Foundation-based persistence, horse catalog and riding simulation. It has no remote package dependencies.

```sh
bash scripts/setup-swift-core.sh   # Linux toolchain, when needed
bash scripts/test-core.sh          # 15 tests plus syntax parsing of app sources
```

The setup script uses Swift 6.0.3 from the official distribution and verifies its release signature against the Swift 6 release key from the official website repository before extraction. The signing key was valid at signing time; GPG now reports it as expired. The installed compiler is retained under `/workspace/toolchains`. Writable compiler/package caches are directed to temporary folders. On a Mac, `scripts/test-core.sh` uses the installed Swift compiler; Linux toolchain installation is unnecessary there.

Tests exercise independent saves and renaming, corruption recovery, date rollover, horse/tack preservation, direction quantization, joystick bounds, aligned and parallel jump approaches, course completion, knockdown/reset/run-out behavior, round-yard circuit tracking, gait changes and reversal.

## Saves and artwork

`Application Support/YourFarmWithUnicorns/profiles.json` stores an active profile UUID and independent player records via atomic writes. Names are editable labels rather than save keys. Unreadable saves are backed up before allowing a fresh profile; failed backups block overwriting. Daily rollover preserves horse, rider, tack and audio preferences.

Three generated draft sheets are bundled in `Assets.xcassets` for horse portraits, rider previews and tack swatches. `GameArt` renders their regions in memory and caches them; originals remain intact in `artwork/drafts`. They are not finished animation atlases. Riding uses clearly labelled temporary vector animation, including a Roo diamond and left hind sock. Final horse gait/jump exports, mounted rider poses and aligned tack overlays remain needed. Approved farm/scene concepts have not been redesigned or replaced.

The initial concept lineup included 14 entries while the specification calls for 13. The provisional catalog keeps Roo and omits the second generic bay entry, Charlie. The other twelve names remain development placeholders. No code change is needed to replace the portraits with final assets later.

`course-chime.wav` is an original synthesized three-note feedback sound, bundled locally. Stage 3 adds touch/drag farm tasks; Stage 4 daily rewards and wand search; Stage 5 unicorn flight; Stage 6 final artwork and device QA. Lake swimming, hidden trail rides and pony club/horse float remain outside version 1.
