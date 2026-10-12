# Your Farm With Unicorns

A complete **v1 gameplay prototype** for an offline, landscape-only iPad farm game, with independent local child profiles. All seven farm areas, daily ribbons, the wand search, and a winged-unicorn flight are implemented. The app uses SwiftUI + SpriteKit with no third-party app dependencies or gameplay network calls.

The game is ready for build and device testing, not a finished App Store release: scenery and animal animation are still draft artwork. Original concept illustrations remain visual references rather than runtime animation assets. Twelve horse names are provisional. Native build and smoke-test results are available under the repository's **Actions → iPad build and smoke test** workflow; do not assume a green result until the workflow finishes.

## Open the app on your Mac

1. Close the previous project in Xcode. On GitHub choose **Code → Download ZIP**, then unzip into a new folder.
2. In Finder open **YourFarmWithUnicorns.xcodeproj** inside that folder. Open this file specifically; opening the whole folder or `Package.swift` opens the core test library instead of the app.
3. Select the shared **YourFarmWithUnicorns** scheme and a **named iPad simulator**, then press **⌘R**. Simulator builds do not need a signing team.
4. Keep the existing app installed in the simulator if you want to retain its child saves. The bundle identifier and save format are unchanged.
5. Press **⌘U** for the 31 model tests and one UI smoke test. Run the UI test in a fresh simulator: it intentionally checks first-launch setup and creates a test child. Existing personal saves are not erased by the test code.

Requires Xcode 15+ and an installed iOS simulator runtime. Real iPad installation needs your own signing team and unique bundle identifier.

```sh
xcodebuild -project YourFarmWithUnicorns.xcodeproj -scheme YourFarmWithUnicorns -showdestinations
xcodebuild test -project YourFarmWithUnicorns.xcodeproj -scheme YourFarmWithUnicorns -destination 'platform=iOS Simulator,id=YOUR_IPAD_SIMULATOR_UUID' -derivedDataPath DerivedData
```

## What you can play

| Area | Activities |
| --- | --- |
| Stables | Drag carrots, apples, liquorice treats or hay to the horse; fill a bucket at the tap and deliver it; sweep the dirty floor. Choose any of 13 horses here. |
| Wash bay | Brush the coat; lift and pick all four hooves; wet/sponge/rinse the coat; drag on pad, saddle and bridle, or tap equipped pieces to remove them. Choose six coordinated palettes and edit the child's name/rider. |
| Paddocks | Tap and scoop five manure piles into a wheelbarrow; brush and refill a green trough; fill and deliver a bucket; drag in hay; hammer an occasionally broken fence rail. |
| Chicken coop | Reveal eggs and drag them to a basket; scatter grain; hold the hose at the water dispenser; sweep; replace straw in four nests; give mealworms or vegetables. Tap chickens for a hop/cluck. |
| Arena | Joystick plus Walk/Trot/Canter, eight facings, three freely available courses, automatic aligned jumps, playful detours/knockdowns, and tap-to-reset poles. |
| Round yard | Automatic riding, Walk/Trot/Canter, gentle direction reversal, and ground poles. Complete whole circuits. |
| Farmhouse | After three ribbons, search one of six daily hiding spots for the wand, guided by sparkles. |

Large activity buttons choose a task. A brief moving-hand demonstration and glowing targets guide touch/drag play; no reading or voice-over is required to perform the gestures. Tasks are freely replayable, and scene-entry state resets when leaving/re-entering without erasing the child's daily progress. Food can be fed repeatedly directly from the tray. A fence can be sound on a particular entry; other paddock tasks remain available.

## Ribbons, wand and flight

- Each participating area gives at most one red rosette per local calendar day after **three distinct activities**, in any order. Repeated foods count as one feeding activity; mealworms/vegetables count as one treat activity. Invalid activity IDs cannot award progress.
- Arena's three preset courses count as its three distinct activities; round yard has walk, trot, canter and poles. The farmhouse itself does not award a ribbon.
- After three ribbons, tap the sparkling hiding spot in the farmhouse. One discovery unlocks the reusable wand at stables for the rest of that day.
- At stables tap the wand tray, then drag the wand onto the horse. Every horse can become a winged unicorn with a white base coat, retained identifying markings and size, and palette-matched mane/tail. It is ridden bareback with tack hidden.
- Flight lasts about **38 seconds**, including transformation and finale, above the same draft farm layout as the map. Tap stars for rainbow trail, and hearts/butterflies/rings for optional effects. There is no steering, score or failure condition.
- The finale says **“What a wonderful day!”** and returns to the map. Home exits immediately at any point. Flight appearance is temporary rendering state; it never overwrites the saved horse or tack, so normal appearance returns instantly.
- The device's local date is checked during play, on scene changes and after app reactivation. At midnight ribbons, activity tracking and wand availability reset; rider, horse, tack and audio preferences remain. Flight pauses when the app is inactive.

## Profiles and audio

First launch requires a nonempty trimmed child name, rider and outfit selection. Later launches open the last-used child's map directly. Switch/Add Player lives on the map; Edit Character lives at the wash bay. Immutable UUIDs, not names, identify saves. Renaming immediately changes farm signs without merging or resetting progress.

`Application Support/YourFarmWithUnicorns/profiles.json` is written atomically after changes. Corrupted saves are backed up before allowing a fresh start, and failed backups block overwriting. Stage 2's valid existing daily course/circuit completions can now award their corresponding rosettes.

Music and SFX toggles are independent and saved per child. Nine original synthesized instrumental loops vary by area, including a brighter flight theme, with ten short synthetic feedback/animal sounds and the original completion chime. These are draft audio, not recorded animal sounds or a finished orchestral soundtrack. Effects are throttled and animal calls use varied, infrequent timings. Muted play retains visual feedback.

## Validation and core tests

The Linux cloud compiled and passed all **31 pure-Swift model tests**, parsed Apple-platform sources, and verified project source membership, shared scheme references, PNG integrity, and all 20 bundled audio resources. This does not resolve Apple SDK APIs or establish UI behavior. GitHub's macOS workflow builds the real app and runs model tests plus an iPad UI smoke test for launch, three stable chores, a ribbon, horse selection, all-area Home navigation, and saved relaunch behavior.

```sh
bash scripts/setup-swift-core.sh  # Linux only, if compiler is missing
bash scripts/test-core.sh
```

The pinned Swift 6.0.3 archive is signature-verified before extraction using the official Swift release-key bundle. The key was valid at signing time; GPG currently reports it as expired. Toolchain files persist under `/workspace/toolchains`; writable caches use temporary folders. On a Mac the test helper uses the installed Swift compiler. No cloud service needs starting, and no Git worktree is needed for these already isolated tasks.

## Full iPad QA checklist

- Create two children, choose different horses/colours/tack/audio preferences, switch and relaunch. Rename a child without losing progress; test long names and small/large iPads.
- Complete every task using touch and drag. Try incomplete buckets, partially cleaned troughs, unfinished hooves, unrevealed eggs and un-cleared nests; those must not count as completed.
- Replay the same food/treat variants: no extra distinct-activity credit. Leave/re-enter to reset props; daily ribbons should remain.
- Earn three activities in an area in different orders and verify one rosette; complete three areas, find the wand, and fly more than once.
- Try flight with Roo, a Shetland and the Clydesdale, each palette and equipped tack. Check wings, bareback appearance, optional tap effects, finale, and both early Home and automatic return.
- Cross a local midnight or change the simulator date: daily progress/wand should reset while other settings remain. Repeat after sleep or relaunch.
- Switch each audio setting independently, pause the app, and try the whole loop with networking disabled.
- Check touch target alignment, artwork edges, animation anchors, memory and frame rate on a real iPad before release.

## Artwork and remaining release work

Nine generated PNG sheets are bundled for portrait/outfit/tack previews, care and coop props, scenery pieces, magic effects and farmhouse search furniture. `GameArt` renders atlas regions in memory; original sheets and provenance notes remain in `artwork/drafts`. Some silhouettes touch grid boundaries and still need production separation/edge cleanup.

The map and activity backgrounds, mounted horses/riders, gaits and wingbeats remain clearly labelled procedural drafts. Final scene layers and animation exports need integration using the approved concepts; exact approved pixels cannot be reconstructed from concept IDs. The white Model Y is still a labelled map placeholder. Licensed/finished music and animal recordings, app icon, release signing, accessibility tuning and device performance QA are outstanding.

The concept lineup had 14 entries; the provisional 13-horse catalog omits the second generic bay, Charlie. The other twelve names remain placeholders. Lake swimming, hidden trail rides, pony club/horse float, accounts, purchases, advertising and online dependencies are outside v1.
