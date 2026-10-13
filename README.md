# Your Farm With Unicorns

A complete **v1 gameplay prototype** for an offline, landscape-only iPad farm game, with independent local child profiles. All seven farm areas, daily ribbons, the wand search, and a winged-unicorn flight are implemented. The app uses SwiftUI + SpriteKit with no third-party app dependencies or gameplay network calls.

The game has illustrated environments, all thirteen painted care horses, angled riding horses and articulated overhead unicorn artwork and an automatically exported app icon. It is ready for native build and device testing; App Store signing and real-device release QA remain. Generated art follows the concept direction rather than reproducing exact reference pixels. Twelve horse names are provisional. The native iPad tests and optimized Release build passed for round-yard and discovery update commit `a74bcc4`: **41 tests executed, 0 failed, 0 skipped** (37 model tests, two native artwork/scene tests and two UI tests). [View the passing run](https://github.com/prjt66cy7n-ops/CFWU/actions/runs/38346433964). This is simulator validation; real-device release QA remains.

## Open the app on your Mac

1. Close the previous project in Xcode. On GitHub choose **Code → Download ZIP**, then unzip into a new folder.
2. In Finder open **YourFarmWithUnicorns.xcodeproj** inside that folder. Open this file specifically; opening the whole folder or `Package.swift` opens the core test library instead of the app.
3. Select the shared **YourFarmWithUnicorns** scheme and a **named iPad simulator**, then press **⌘R**. Simulator builds do not need a signing team.
4. Keep the existing app installed in the simulator if you want to retain its child saves. The bundle identifier and save format are unchanged.
5. Press **⌘U** for the 37 model tests, two UI tests and two native artwork/scene tests. UI tests use isolated UUID-named temporary saves in Debug builds, so first-launch and flight checks do not touch existing child profiles.

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
| Round yard | Go/Stop controls, Walk/Trot/Canter, gentle direction reversal, perpendicular ground poles and Lunging with the child and rope in the centre. Complete whole circuits. |
| Farmhouse | Touch real furniture in the room to shift it aside and search behind it. After three ribbons, one of six daily hiding spots reveals the wand. |

Large activity buttons choose a task. A brief moving-hand demonstration and glowing targets guide touch/drag play; no reading or voice-over is required to perform the gestures. Tasks are freely replayable, and scene-entry state resets when leaving/re-entering without erasing the child's daily progress. Switching between unfinished activities within an area retains their partial progress. Food can be fed repeatedly directly from the tray. A fence can be sound on a particular entry; other paddock tasks remain available.

## Ribbons, wand and flight

- Each participating area gives at most one red rosette per local calendar day after **three distinct activities**, in any order. Repeated foods count as one feeding activity; mealworms/vegetables count as one treat activity. Invalid activity IDs cannot award progress.
- Arena's three preset courses count as its three distinct activities; round yard has walk, trot, canter, poles and lunging. The farmhouse itself does not award a ribbon.
- After three ribbons, search behind furniture in the room in the farmhouse. One discovery unlocks the reusable wand at stables for the rest of that day.
- At stables tap the wand tray, then drag the wand onto the horse. Every horse can become a winged unicorn with a white base coat, retained identifying markings and size, and palette-matched mane/tail. It is ridden bareback with tack hidden.
- Flight lasts about **38 seconds**, including transformation and finale, above the same illustrated farm layout as the map. Tap stars for rainbow trail, and hearts/butterflies/rings for optional effects. There is no steering, score or failure condition.
- The finale says **“What a wonderful day!”** and returns to the map. Home exits immediately at any point. Flight appearance is temporary rendering state; it never overwrites the saved horse or tack, so normal appearance returns instantly.
- The device's local date is checked during play, on scene changes and after app reactivation. At midnight ribbons, activity tracking and wand availability reset; rider, horse, tack and audio preferences remain. Flight pauses when the app is inactive.

## Profiles and audio

First launch requires a nonempty trimmed child name, rider and outfit selection. Later launches open the last-used child's map directly. Switch/Add Player lives on the map; Edit Character lives at the wash bay. Immutable UUIDs, not names, identify saves. Renaming immediately changes farm signs without merging or resetting progress.

`Application Support/YourFarmWithUnicorns/profiles.json` is written atomically after changes. Corrupted saves are backed up before allowing a fresh start, and failed backups block overwriting. Stage 2's valid existing daily course/circuit completions can now award their corresponding rosettes.

Music and SFX toggles are independent and saved per child. Nine original synthesized instrumental loops vary by area, including a brighter flight theme, with ten short synthetic feedback/animal sounds and the original completion chime. These are draft audio, not recorded animal sounds or a finished orchestral soundtrack. Effects are throttled and animal calls use varied, infrequent timings. Muted play retains visual feedback.

## Validation and core tests

The Linux cloud compiled and passed all **34 pure-Swift model tests**, parsed Apple-platform sources, and verified project source membership, shared scheme references, PNG integrity, and all 20 bundled audio resources. This does not resolve Apple SDK APIs or establish UI behavior. GitHub's macOS workflow built the real app and passed 38 native tests. UI checks cover launch, three stable chores, a ribbon, horse selection, all-area Home navigation and saved relaunch, plus wand discovery from an isolated three-ribbon fixture, drag launch, early Home, a genuine 38-second replay and reusable wand. Native tests decode the 39 care/overhead horse silhouettes, all 104 angled riding poses and all eight environment cells, and verify that activity objects persist and chicken feeding animations survive task/player updates. The workflow reads the result bundle to reject zero-test, skipped-test or failed-test runs, then compiles the optimized Release app. Both checks passed for the linked illustrated build.

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

Twenty-nine PNG assets are bundled for illustrated scenery, full-body care horses, overhead normal/unicorn rigs, a painted wing, portrait/outfit/tack previews, tools, magic effects and farmhouse furniture. `GameArt` crops atlas regions in memory, trims transparent margins for the rigs, and excludes environment divider gutters. Source masters and provenance notes remain in `artwork/drafts`.

The navigation map and flight share one illustrated farm. New environment paintings follow the supplied concept direction, with interactive tools and animals rendered separately. Overhead horses use separate painted head, body and tail sections above gait-specific articulated legs, with rider/tack layers and animated painted wings. A shader matches unicorn hair to the child's palette. The native build exports an opaque 1024px AppIcon from the original branding master using the macOS SDK; its PNG output is intentionally ignored and regenerated during build. Full-sheet silhouette rectangles and runtime fragment filtering prevent neighbouring sprite pieces from appearing in the selected object; the extraction audit is in artwork/ATLAS_AUDIT.md.

Original synthesized music and feedback/animal effects are bundled. Recorded animal sounds and orchestral instrumentation can improve audio fidelity. Remaining release work is Apple signing and distribution, full real-iPad touch/performance/accessibility QA, and optional visual/audio refinements.

The concept lineup had 14 entries; the provisional 13-horse catalog omits the second generic bay, Charlie. The other twelve names remain placeholders. Lake swimming, hidden trail rides, pony club/horse float, accounts, purchases, advertising and online dependencies are outside v1.

## Illustrated build update

Eight illustrated environment cells now cover every area and the shared navigation/flight map. All thirteen horses have full-body care artwork, with saved tack overlaid. Riding uses smoother gait-specific procedural animation. New unicorn branding appears on first launch. The native build exports the opaque 1024px app icon from its painted master. Mounted horses and unicorns now use articulated painted overhead body sections, separate rider/tack, and painted flapping wings; unicorn hair is recoloured per palette in a shader. Audio remains original synthesized music and effects, with recorded animal sounds still optional production work. Native tests now also decode all 39 horse silhouettes and all eight environments. The second native UI test starts from a clearly isolated three-ribbon fixture, discovers the wand through the normal farmhouse UI, drags it onto the horse, checks early Home, awaits the real 38-second replay, and checks saved relaunch and reusable wand. The illustrated build passed all 41 native tests and the optimized Release compilation in the run linked above.

## Scene interaction update

Activity objects and tools now exist at fixed locations before selection. Touching a resting tool can select its task; switching tasks retains other activity objects and their progress. The coop keeps the same chicken nodes while they gather and peck at scattered food; updates no longer interrupt their feeding animation. Eggs are already present beneath straw in back-wall nesting boxes and must be uncovered before collection. Floor mess uses varied scattered patches rather than four identical piles in a row. Liquorice is a small dark stick, with separate carrot/apple/liquorice/hay crunch effects and an occasional delayed post-eating fart. Hooves are lifted then scrubbed with the pick; lower leg artwork hinges upward. Tack rests on a side rack and is dragged onto the horse. Riding uses eight angled poses for each of thirteen horses, projected ground positions and upright jumps. Full-sheet silhouette rectangles in Resources/atlas-regions.json and runtime filtering prevent adjacent-image fragments, and the outdoor scene-divider crop is corrected. The scene-interaction build passed all 41 native tests and optimized Release compilation in the run linked above. The native checks also caught and verified fixes for Home controls being obstructed by oversized scene hit regions.

## Round yard and discovery interaction update

The round yard starts stopped, with Go/Stop and Lunging controls. Lunging removes the mounted rider, places the chosen child in the centre and connects a visible rope to the horse’s halter; a full circuit counts as a distinct activity. Ground poles lie perpendicular to the elliptical track and use the same angled camera projection as the horse.

Farmhouse search targets follow furniture in the painting rather than covering it with cards. Touching them shifts the object aside to reveal what is behind it. The coop has solid wooden nesting boxes with eggs concealed by textured straw, collected eggs stack inside the basket, and only five small floor mess patches. A fixed tap connects to the movable hose; droplets flow while held at the dispenser and its blue water level rises. Feeding chickens gather, peck and cluck repeatedly. Audio session configuration and player loading run on a serial background queue; Combine is explicitly imported for the daily timer.

Validation for this update: 37 local model tests passed; all Apple app sources parsed. The native iPad run linked above passed all 41 tests with no failures or skips, including Go/Stop, Lunging selection and furniture-based wand discovery, followed by a successful optimized Release simulator build.
