import Combine
import SwiftUI
import SpriteKit

struct FarmRootView: View {
    @EnvironmentObject private var game: FarmController
    @Environment(\.scenePhase) private var phase
    @State private var area: FarmArea?
    @State private var flying = false
    @State private var players = false
    @State private var editing = false
    @State private var settings = false
    @State private var choosingHorse = false
    @State private var launchingWand = false
    @State private var celebrationFly = false
    @State private var map = FarmScene()
    private let dayTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private var paused: Bool { settings || players || editing || choosingHorse || launchingWand || game.message != nil }
    private var audioScene: String { flying ? "flight" : (area?.rawValue ?? "farm") }
    var body: some View {
        ZStack {
            Color(red: 0.84, green: 0.92, blue: 0.73).ignoresSafeArea()
            if let player = game.active {
                VStack(spacing: 8) {
                    header(player).zIndex(10)
                    RibbonRow(player: player)
                    playArea(player).contentShape(Rectangle()).clipped()
                    Text("Your Farm With Unicorns").font(.caption2).foregroundColor(.secondary)
                }.padding(16)
            } else {
                CharacterEditor(player: nil) { name, rider, palette in game.create(name: name, rider: rider, palette: palette) }
                    .disabled(game.storageBlocked)
            }
            if let reward = game.reward {
                RosetteCelebration(area: reward.area)
                    .scaleEffect(celebrationFly ? 0.18 : 1)
                    .offset(x: celebrationFly ? -260 : 0, y: celebrationFly ? -220 : 0)
                    .opacity(celebrationFly ? 0 : 1).allowsHitTesting(false)
            }
        }
        .buttonStyle(.borderedProminent).tint(.brown)
        .sheet(isPresented: $players) { PlayerPicker { players = false; home() } }
        .sheet(isPresented: $choosingHorse) { HorsePicker { choosingHorse = false } }
        .sheet(isPresented: $launchingWand) {
            if let player = game.active { WandLaunchScreen(player: player) { launchingWand = false; beginFlight() } }
        }
        .sheet(isPresented: $editing) {
            CharacterEditor(player: game.active) { name, rider, palette in
                game.edit(name: name, rider: rider, palette: palette); editing = false
            }
        }
        .sheet(isPresented: $settings) {
            NavigationStack {
                Form {
                    Toggle("Music", isOn: Binding(get: { game.active?.musicEnabled ?? true }, set: { value in game.update { $0.musicEnabled = value } }))
                    Toggle("Sound Effects", isOn: Binding(get: { game.active?.sfxEnabled ?? true }, set: { value in
                        game.update { $0.sfxEnabled = value }; if !value { GameAudio.stopEffects() }
                    }))
                    Section("Sound credits") {
                        Text("Chewing carrot — InspectorJ · Freesound 412068. Edited and mixed for this game.").font(.footnote)
                        Link("Creative Commons Attribution 3.0", destination: URL(string: "https://creativecommons.org/licenses/by/3.0/")!)
                        Link("Original recording", destination: URL(string: "https://freesound.org/people/InspectorJ/sounds/412068/")!)
                        Text("Eating crunches — StarNinjas · CC0. Water Flowing — rubberduck · CC0.").font(.footnote)
                    }
                }.navigationTitle("Sound").toolbar { Button("Done") { settings = false } }
            }
        }
        .alert("Saved game", isPresented: Binding(get: { game.message != nil }, set: { if !$0 { game.message = nil } })) {
            Button("OK") { game.message = nil }
        } message: { Text(game.message ?? "") }
        .onReceive(dayTimer) { _ in if phase == .active { game.refreshDay() } }
        .onAppear { syncAudio() }
        .onChange(of: area) { _ in syncAudio() }
        .onChange(of: flying) { _ in syncAudio() }
        .onChange(of: phase) { _ in syncAudio() }
        .onChange(of: game.active?.musicEnabled) { _ in syncAudio() }
        .onChange(of: game.active?.id) { _ in syncAudio() }
        .onChange(of: game.active?.name) { name in map.updateName(name ?? "Your") }
        .task(id: game.reward?.id) {
            guard let reward = game.reward else { return }
            celebrationFly = false
            GameAudio.effect("ribbon", enabled: game.active?.sfxEnabled ?? false)
            try? await Task.sleep(nanoseconds: 1_100_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.6)) { celebrationFly = true }
            try? await Task.sleep(nanoseconds: 650_000_000)
            guard !Task.isCancelled else { return }
            game.clearReward(reward.id)
        }
    }
    private func header(_ player: Player) -> some View {
        HStack {
            if area != nil || flying {
                Button(action: home) { Label("Home", systemImage: "house.fill").padding(.vertical, 5) }.accessibilityIdentifier("home")
            } else {
                Button { players = true } label: { Label("Switch / Add Player", systemImage: "person.2.fill").padding(.vertical, 5) }
            }
            Spacer()
            Text("\(player.name)’s Farm").font(.title2.bold()).lineLimit(1).minimumScaleFactor(0.35)
            Spacer()
            Button { settings = true } label: { Image(systemName: "gearshape.fill").font(.title2).padding(5) }.accessibilityLabel("Sound settings")
        }.padding(10).background(.regularMaterial).clipShape(RoundedRectangle(cornerRadius: 20))
    }
    @ViewBuilder private func playArea(_ player: Player) -> some View {
        if flying {
            FlightScreen(player: player, paused: paused, finish: home).id(player.id)
        } else if let area {
            if area == .arena || area == .roundYard {
                RidingScreen(player: player, mode: area == .arena ? .arena : .roundYard, paused: paused) { activity in
                    game.recordActivity(area: area.rawValue, activity: activity)
                    GameAudio.chime(enabled: game.active?.sfxEnabled ?? false)
                }.id("\(player.id)-\(area.rawValue)")
            } else if area == .farmhouse {
                FarmhouseScreen(player: player) { game.discoverWand(at: $0) }
            } else {
                FarmTasksScreen(player: player, area: area, paused: paused,
                                chooseHorse: { choosingHorse = true }, editCharacter: { editing = true },
                                choosePalette: { palette in game.update { $0.palette = palette } },
                                wand: { launchingWand = true },
                                onActivity: { game.recordActivity(area: area.rawValue, activity: $0) },
                                onTack: { tack in if game.active?.tack != tack { game.update { $0.tack = tack } } })
                    .id("\(player.id)-\(area.rawValue)")
            }
        } else {
            VStack(spacing: 7) {
                SpriteView(scene: map).clipShape(RoundedRectangle(cornerRadius: 24))
                    .onAppear {
                        map.updateName(player.name)
                        map.onVisit = { place in game.refreshDay(); area = place }
                    }.accessibilityLabel("Farm map")
                    .overlay {
                        GeometryReader { geometry in
                            let scale = min(geometry.size.width / 1000, geometry.size.height / 620)
                            let insetX = (geometry.size.width - 1000 * scale) / 2
                            let insetY = (geometry.size.height - 620 * scale) / 2
                            ForEach(FarmLandscape.paintedLocations, id: \.0) { place, point in
                                Button { game.refreshDay(); area = place } label: {
                                    Circle().fill(Color.white.opacity(0.001))
                                        .frame(width: max(44, 64 * scale), height: max(44, 64 * scale))
                                        .contentShape(Circle())
                                }.buttonStyle(.plain)
                                    .accessibilityLabel(place.title).accessibilityIdentifier("visit-\(place.rawValue)")
                                    .position(x: insetX + point.x * scale, y: insetY + (620 - point.y) * scale)
                            }
                        }
                    }
                Text("\(player.horse.name) · \(player.palette.label)").font(.caption)
            }
        }
    }
    private func home() { game.save(); flying = false; area = nil }
    private func beginFlight() {
        game.refreshDay()
        guard game.active?.canFly == true else { return }
        game.save(); flying = true
    }
    private func syncAudio() {
        GameAudio.music(scene: audioScene, enabled: (game.active?.musicEnabled ?? false) && phase == .active)
        if phase != .active { GameAudio.stopEffects() }
    }
}

struct CharacterEditor: View {
    let player: Player?
    let submit: (String, Rider, Palette) -> Void
    @State private var name: String
    @State private var rider: Rider
    @State private var palette: Palette
    @FocusState private var nameFocused: Bool
    init(player: Player?, submit: @escaping (String, Rider, Palette) -> Void) {
        self.player = player; self.submit = submit
        _name = State(initialValue: player?.name ?? "")
        _rider = State(initialValue: player?.rider ?? .girl)
        _palette = State(initialValue: player?.palette ?? .pink)
    }
    var body: some View {
        ScrollView {
        VStack(spacing: 20) {
            if player == nil {
                Image("UnicornBrand").resizable().scaledToFit().frame(height: 95)
                    .clipShape(RoundedRectangle(cornerRadius: 22)).accessibilityHidden(true)
            }
            Text(player == nil ? "Welcome to Your Farm With Unicorns" : "Edit Character").font(.title.bold())
            TextField("Your name", text: $name).textFieldStyle(.roundedBorder).font(.title2)
                .autocorrectionDisabled().submitLabel(.done)
                .focused($nameFocused).onSubmit { nameFocused = false }.accessibilityIdentifier("player-name")
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
            RiderPortrait(rider: rider, palette: palette).frame(height: 130)
            Text("Choose your rider and colours").font(.caption)
            Button(player == nil ? "🏡 Go to my farm" : "Save Character") { nameFocused = false; submit(name, rider, palette) }
                .buttonStyle(.borderedProminent).controlSize(.large).accessibilityIdentifier("save-character")
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }.padding(32).frame(maxWidth: 760).frame(maxWidth: .infinity)
        }.background(Color(red: 0.95, green: 0.96, blue: 0.88))
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
