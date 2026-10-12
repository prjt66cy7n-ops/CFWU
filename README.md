# Your Farm With Unicorns

Stage 1 source prototype for an offline, landscape-only iPad game. Native SwiftUI controls sit over a SpriteKit placeholder farm. Requires a Mac with Xcode 15 or later and the iOS simulator runtime. No third-party dependencies, accounts, or network calls are used by the app.

## Run on a Mac

1. Open `YourFarmWithUnicorns.xcodeproj` in Xcode.
2. Select the shared **YourFarmWithUnicorns** scheme and an installed iPad simulator.
3. Choose Product → Run. For a physical iPad, choose your own signing team and unique bundle identifier in Signing & Capabilities.
4. Choose Product → Test for the three persistence and daily-reset tests.

For command-line validation, list installed simulator destinations first:

```sh
xcodebuild -project YourFarmWithUnicorns.xcodeproj -scheme YourFarmWithUnicorns -showdestinations
xcodebuild -project YourFarmWithUnicorns.xcodeproj -scheme YourFarmWithUnicorns -destination 'platform=iOS Simulator,id=YOUR_IPAD_SIMULATOR_UUID' -derivedDataPath DerivedData build test
```

The Linux cloud machine has no Swift compiler, Apple SDK, or simulator. Project object references, source membership, scheme XML and asset JSON were checked here. **Native compilation, automated Swift tests, simulator launch, and touch behavior remain unverified.** No dependencies need installing in this cloud workspace.

## Stage 1 manual checks

- First launch: whitespace-only names cannot continue. Enter a name, choose boy/girl and one of six palettes, then enter the map.
- Tap each of seven area cards, then Home. Lake is scenery; wash bay represents the stable verandah. All activity scenes explicitly show placeholder status.
- Open Switch / Add Player, create a second child, then switch back. Each child keeps separate appearance and audio settings.
- At Wash Bay choose Edit Character. Rename the child and change their palette; return Home and confirm the sign changed without creating another profile.
- Change Music and Sound Effects independently. Close and relaunch; the last-used profile opens directly on the map, with preferences retained. No audio is played until assets are integrated.
- Turn networking off and repeat navigation, editing and relaunch.
- Rotate the simulator: only landscape orientations are permitted. Check a small and a large iPad; long names should shrink to fit.

## Persistence

`Application Support/YourFarmWithUnicorns/profiles.json` stores an active profile UUID and independent player records using atomic writes. Display names are not save keys; duplicate names are permitted. Unreadable saves are copied to an `unreadable-UUID.json` recovery file before allowing a fresh profile. If that copy fails, profile creation is blocked to protect the original. Save failures display a message; in-memory changes remain available for a later retry. Do not delete recovery files without backing them up.

The daily date uses the device's local calendar. It is checked on app activation, map entry and every 30 seconds while the app is active. Daily activity, ribbon and wand state reset, while rider, horse, tack and audio settings remain. Those fields are prepared for later stages; Stage 1 does not award ribbons or offer flight.

## Art and later stages

The current map uses temporary vector hills and lake, with emoji area/rider/horse illustrations. It is a navigation prototype rather than the approved isometric artwork. Original concept IDs are not usable files. `Assets.xcassets` is the replaceable image catalog; scene navigation is keyed by stable `FarmArea` IDs.

Still needed: exported farm and seven scene backgrounds, rider/outfit sprites, 13 horse sprites and animation poses, coordinated tack, unicorn variants, activity props, rosettes, UI icons, flight art, and licensed music/SFX. No supplied artwork has been recreated or claimed as final.

Stages 2–6 add the horse catalog/riding, farm tasks, daily rewards/wand, unicorn flight, then approved asset integration and device QA. Lake swimming, hidden trail rides and pony club/horse float remain outside version 1.
