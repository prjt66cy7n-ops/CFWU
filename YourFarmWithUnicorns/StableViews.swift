import SwiftUI

struct StableScreen: View {
    @EnvironmentObject private var game: FarmController
    let chooseHorse: () -> Void
    var body: some View {
        VStack(spacing: 12) {
            Text("Stables").font(.largeTitle.bold())
            HStack(spacing: 30) {
                HorsePortrait(horse: game.active!.horse).frame(maxWidth: 280, maxHeight: 240)
                VStack(spacing: 16) {
                    Text(game.active!.horse.name).font(.largeTitle.bold())
                    Text(game.active!.horse.description)
                    Button(action: chooseHorse) { Label("Choose Horse", systemImage: "heart.fill").padding(8) }
                    Text("Ready to ride! Grooming and tack are optional.").font(.subheadline)
                }
                RiderPortrait(rider: game.active!.rider, palette: game.active!.palette).frame(width: 110, height: 200)
            }
            Text("Feeding and stable chores arrive in Stage 3").font(.caption)
        }.frame(maxWidth: .infinity, maxHeight: .infinity).padding()
            .background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: 28))
    }
}
struct HorsePicker: View {
    @EnvironmentObject private var game: FarmController
    let close: () -> Void
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                    ForEach(HorseCatalog.all) { horse in
                        Button { game.selectHorse(horse.id); close() } label: {
                            VStack(spacing: 5) {
                                HorsePortrait(horse: horse).frame(height: 115)
                                Text("\(game.active?.selectedHorseID == horse.id ? "✓ " : "")\(horse.name)").font(.headline)
                                Text(horse.description).font(.caption).lineLimit(2)
                            }.frame(maxWidth: .infinity, minHeight: 175).padding(8)
                                .background(game.active?.selectedHorseID == horse.id ? Color.purple.opacity(0.18) : Color.brown.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                        }.buttonStyle(.plain)
                    }
                }.padding()
                Text("13 horses · Tack transfers automatically · All ride with the same easy controls")
                    .font(.caption).padding()
            }.navigationTitle("Choose your horse").toolbar { Button("Done", action: close) }
        }
    }
}
struct TackScreen: View {
    @EnvironmentObject private var game: FarmController
    let editCharacter: () -> Void
    var body: some View {
        VStack(spacing: 12) {
            Text("Wash Bay & Tack-Up").font(.title.bold())
            HStack(spacing: 20) {
                HorsePortrait(horse: game.active!.horse).frame(width: 200, height: 170)
                RiderPortrait(rider: game.active!.rider, palette: game.active!.palette).frame(width: 90, height: 170)
                VStack(spacing: 10) {
                    Text(game.active!.horse.name).font(.title2.bold())
                    Button(action: editCharacter) { Label("Edit Character", systemImage: "person.crop.circle") }
                    Text("Try tack · tap again to remove").font(.caption)
                    HStack {
                        tackButton("Saddle Pad", equipped: game.active!.tack.saddlePad) { game.update { $0.tack.saddlePad.toggle() } }
                        tackButton("Saddle", equipped: game.active!.tack.saddle) { game.update { $0.tack.saddle.toggle() } }
                        tackButton("Bridle", equipped: game.active!.tack.bridle) { game.update { $0.tack.bridle.toggle() } }
                    }
                }
            }
            HStack {
                ForEach(Palette.allCases, id: \.self) { palette in
                    Button { game.update { $0.palette = palette } } label: {
                        VStack {
                            if let image = GameArt.pad(palette) { Image(uiImage: image).resizable().scaledToFit().frame(height: 48) }
                            Text(palette.label).font(.caption)
                            if palette == game.active?.palette { Image(systemName: "checkmark") }
                        }.frame(minWidth: 65, minHeight: 85)
                    }.buttonStyle(.bordered).tint(palette.color)
                        .accessibilityAddTraits(palette == game.active?.palette ? .isSelected : [])
                }
            }
            Text("Colours change instantly · Grooming, washing and drag-to-equip arrive in Stage 3").font(.caption)
        }.frame(maxWidth: .infinity, maxHeight: .infinity).padding()
            .background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: 28))
    }
    private func tackButton(_ name: String, equipped: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) { Text("\(equipped ? "✓ " : "+ ")\(name)").font(.subheadline).padding(.vertical, 8) }
            .tint(equipped ? .purple : .brown)
    }
}
