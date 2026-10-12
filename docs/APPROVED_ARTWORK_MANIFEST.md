# Your Farm with Unicorns — Approved Artwork Integration

The user has approved 13 reference illustrations. The binary PNGs are packaged in **Your_Farm_with_Unicorns_Codex_Artwork.zip** (provided separately in the ChatGPT conversation), under `reference_art/`. This repository file is the asset manifest, **not the images themselves**.

## Approved references

- `farm_map_reference.png` — authoritative farm overview; do not replace with alternate map.
- `roo_normal_reference.png` — Roo, female bay horse, black mane/tail/legs, white forehead diamond and one white hind sock.
- `roo_unicorn_reference.png` — transformation style; adapt mane/tail to current rider outfit colour, add wings, preserve individual horse proportions/markings.
- `horse_lineup_reference.png` — 13 horses, one Shetland, one draft horse, others riding horses/ponies.
- `arena_reference.png` — approved elevated riding arena.
- `alternate_arena_reference.png` — secondary reference only; primary arena reference takes precedence.
- `round_yard_reference.png` — circular training yard.
- `stable_reference.png` — stable feeding and care.
- `paddock_reference.png` — paddock activities.
- `wash_bay_reference.png` — grooming/tack-up area on side of stables.
- `chicken_coop_reference.png` — chicken care and eggs.
- `farmhouse_reference.png` — farmhouse interior, hidden wand.
- `ribbons_reference.png` — red pony-club rosettes.

## Codex integration instructions

1. Keep the images in `reference_art/` as **design references**, not runtime sprite sheets.
2. Use the approved farm map and each approved area as visual direction when constructing the corresponding SpriteKit scene.
3. Prepare production assets separately: transparent sprites, animation frames, scenery layers, icons, and hit targets. Do not pretend full-scene illustrations are animated sprites.
4. Build an offline landscape-only iPad app in SwiftUI + SpriteKit. Support multiple locally saved child profiles, entered names, profile switching, editable names, and dynamic signs such as `Alice's Farm`.
5. Preserve the previously agreed daily ribbon progression, farm chores, riding, wand discovery, and winged-unicorn finale.
6. The flight uses an elevated angled camera above paddocks/hills/lake, natural wingbeats and gliding, gentle galloping legs, orchestral music, rainbow-star interactions, and a `What a wonderful day!` banner. Home exits early. The horse reverts instantly upon returning to the farm.
7. Implement in testable stages; begin by replacing placeholder visuals using the farm map reference, without breaking the current Stage 1 project.

**Note:** The PNG binaries must be added to this repository separately. This manifest does not mean the image assets are present.
