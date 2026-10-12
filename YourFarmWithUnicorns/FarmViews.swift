import SwiftUI
import SpriteKit

private extension Palette {
    var color: Color {
        switch self {
        case .pink: return .pink
        case .purple: return .purple
        case .blue: return .blue
        case .green: return .green
        case .red: return .red
        case .blackGold: return .black
        }
    }
}
struct FarmRootView: View {
    @EnvironmentObject private var game: FarmController
    @State private var area: FarmArea?
    @State private var players = false
    @State private var editing = false
    @State private var settings = false
    @State private var scene = FarmScene()
    private let dayTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    var body: some View {
        Group {
            if game.active == nil {
                CharacterEditor(player: nil) { name, rider, palette in game.create(name: name, rider: rider, palette: palette) }
                    .disabled(game.storageBlocked)
            } else {
                ZStack {
                    SpriteView(scene: scene).ignoresSafeArea()
                    VStack(spacing: 12) {
                        HStack {
                            if area != nil {
                                Button { game.save(); area = nil } label: { Label("Home", systemImage: "house.fill") }
                            } else {
                                Button { players = true } label: { Label("Switch / Add Player", systemImage: "person.2.fill") }
                            }
                            Spacer()
                            Text("\(game.active!.name)’s Farm").font(.title.bold()).lineLimit(1).minimumScaleFactor(0.4)
                            Spacer()
                            Button { settings = true } label: { Image(systemName: "gearshape.fill").accessibilityLabel("Sound settings") }
                        }
                        .padding().background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: 20))
                        if let area {
                            activity(area)
                        } else {
                            Text("Your Farm With Unicorns").font(.title2.bold())
                            Text("Tap a place to visit").font(.headline)
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), spacing: 16) {
                                ForEach(FarmArea.allCases) { place in
                                    Button { game.refreshDay(); area = place } label: {
                                        VStack { Text(place.icon).font(.system(size: 48)); Text(place.title).font(.headline) }
                                            .frame(maxWidth: .infinity, minHeight: 115)
                                            .background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: 22))
                                    }
                                }
                            }
                            Text("TEMPORARY MAP ART · Wash bay is the stable verandah").font(.caption)
                            Text("Daily ribbons: \(game.active!.ribbons.count) · Activities arrive in later stages").font(.caption)
                        }
                        Spacer(minLength: 0)
                    }.padding(24)
                }
            }
        }
        .buttonStyle(.borderedProminent).tint(.brown)
        .sheet(isPresented: $players) { PlayerPicker { players = false; area = nil } }
        .sheet(isPresented: $editing) {
            CharacterEditor(player: game.active) { name, rider, palette in
                game.edit(name: name, rider: rider, palette: palette); editing = false
            }
        }
        .sheet(isPresented: $settings) {
            NavigationStack {
                Form {
                    Toggle("Music", isOn: Binding(get: { game.active?.musicEnabled ?? true }, set: { value in game.update { $0.musicEnabled = value } }))
                    Toggle("Sound effects", isOn: Binding(get: { game.active?.sfxEnabled ?? true }, set: { value in game.update { $0.sfxEnabled = value } }))
                    Text("Preferences save per player. Music and sound files have not been supplied; this prototype is silent.")
                }.navigationTitle("Sound").toolbar { Button("Done") { settings = false } }
            }
        }
        .alert("Saved game", isPresented: Binding(get: { game.message != nil }, set: { if !$0 { game.message = nil } })) {
            Button("OK") { game.message = nil }
        } message: { Text(game.message ?? "") }
        .onReceive(dayTimer) { _ in game.refreshDay() }
    }
    private func activity(_ place: FarmArea) -> some View {
        VStack(spacing: 20) {
            Text(place.icon).font(.system(size: 84))
            Text(place.title).font(.largeTitle.bold())
            Text("TEMPORARY SCENE · Activities coming in later stages").font(.headline)
            Text("\(game.active!.rider == .boy ? "👦" : "👧")  🐴 Roo").font(.system(size: 60))
                .padding().background(game.active!.palette.color.opacity(0.25)).clipShape(RoundedRectangle(cornerRadius: 24))
            Text("Outfit: \(game.active!.palette.label)")
            if place == .washBay {
                Button { editing = true } label: { Label("Edit Character", systemImage: "person.crop.circle") }
            }
            if place == .farmhouse { Text("🚙 White Tesla Model Y · placeholder").font(.caption) }
        }.frame(maxWidth: .infinity, maxHeight: .infinity).padding()
            .background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: 28))
    }
}

struct CharacterEditor: View {
    let player: Player?
    let submit: (String, Rider, Palette) -> Void
    @State private var name: String
    @State private var rider: Rider
    @State private var palette: Palette
    init(player: Player?, submit: @escaping (String, Rider, Palette) -> Void) {
        self.player = player; self.submit = submit
        _name = State(initialValue: player?.name ?? "")
        _rider = State(initialValue: player?.rider ?? .girl)
        _palette = State(initialValue: player?.palette ?? .pink)
    }
    var body: some View {
        VStack(spacing: 20) {
            Text(player == nil ? "Welcome to Your Farm With Unicorns" : "Edit Character").font(.title.bold())
            TextField("Your name", text: $name).textFieldStyle(.roundedBorder).font(.title2)
                .autocorrectionDisabled().submitLabel(.done)
            Picker("Rider", selection: $rider) {
                Text("👦 Boy").tag(Rider.boy); Text("👧 Girl").tag(Rider.girl)
            }.pickerStyle(.segmented)
            HStack {
                ForEach(Palette.allCases, id: \.self) { choice in
                    Button { palette = choice } label: {
                        VStack {
                            Circle().fill(choice.color).frame(width: 44, height: 44)
                                .overlay(Circle().stroke(palette == choice ? Color.orange : .clear, lineWidth: 5))
                            Text(choice.label).font(.caption)
                        }.frame(minWidth: 64, minHeight: 80)
                    }.buttonStyle(.plain).accessibilityAddTraits(palette == choice ? .isSelected : [])
                }
            }
            Text(rider == .boy ? "👦" : "👧").font(.system(size: 70)).padding()
                .background(palette.color.opacity(0.3)).clipShape(Circle())
            Text("TEMPORARY RIDER ART").font(.caption)
            Button(player == nil ? "🏡 Go to my farm" : "Save Character") { submit(name, rider, palette) }
                .buttonStyle(.borderedProminent).controlSize(.large)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }.padding(32).frame(maxWidth: 760).frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 0.95, green: 0.96, blue: 0.88))
    }
}

struct PlayerPicker: View {
    @EnvironmentObject private var game: FarmController
    let close: () -> Void
    @State private var adding = false
    var body: some View {
        NavigationStack {
            List {
                ForEach(game.farm.players) { player in
                    Button { game.switchPlayer(player.id); close() } label: {
                        HStack { Text("\(player.rider == .boy ? "👦" : "👧")  \(player.name)"); Spacer()
                            if player.id == game.active?.id { Image(systemName: "checkmark") }
                        }.font(.title2).padding(12)
                    }
                }
                Button { adding = true } label: { Label("Add Player", systemImage: "person.badge.plus").padding(12) }
            }.navigationTitle("Who is playing?").toolbar { Button("Done", action: close) }
                .sheet(isPresented: $adding) {
                    CharacterEditor(player: nil) { name, rider, palette in
                        game.create(name: name, rider: rider, palette: palette); adding = false; close()
                    }
                }
        }
    }
}
