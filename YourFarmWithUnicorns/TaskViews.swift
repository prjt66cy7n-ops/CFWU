import SwiftUI
import SpriteKit

final class TaskSession: ObservableObject {
    let scene: TaskScene
    @Published var selected: FarmActivity
    @Published var progress = 0.0
    @Published var guide = ""
    @Published var finished: Set<FarmActivity> = []
    init(player: Player, area: FarmArea, onActivity: @escaping (String) -> Void, onTack: @escaping (Tack) -> Void) {
        let first = area.activities[0]
        selected = first; scene = TaskScene(player: player, activity: first)
        guide = scene.guide
        scene.onSelect = { [weak self] in self?.select($0) }
        scene.onChange = { [weak self] state, justCompleted in
            guard let self else { return }
            self.progress = state.progress; self.guide = self.scene.guide
            if state.activity == .tack { onTack(state.tack) }
            if justCompleted { self.finished.insert(state.activity); onActivity(state.activity.rawValue) }
        }
    }
    func select(_ activity: FarmActivity) { selected = activity; scene.choose(activity) }
}
struct FarmTasksScreen: View {
    @StateObject private var session: TaskSession
    @Environment(\.scenePhase) private var phase
    let player: Player
    let area: FarmArea
    let paused: Bool
    let chooseHorse: () -> Void
    let editCharacter: () -> Void
    let choosePalette: (Palette) -> Void
    let wand: () -> Void
    init(player: Player, area: FarmArea, paused: Bool,
         chooseHorse: @escaping () -> Void, editCharacter: @escaping () -> Void,
         choosePalette: @escaping (Palette) -> Void, wand: @escaping () -> Void,
         onActivity: @escaping (String) -> Void, onTack: @escaping (Tack) -> Void) {
        self.player = player; self.area = area; self.paused = paused
        self.chooseHorse = chooseHorse; self.editCharacter = editCharacter
        self.choosePalette = choosePalette; self.wand = wand
        _session = StateObject(wrappedValue: TaskSession(player: player, area: area, onActivity: onActivity, onTack: onTack))
    }
    var body: some View {
        VStack(spacing: 7) {
            HStack {
                Text("\(area.icon) \(area.title)").font(.title2.bold())
                Spacer()
                if area == .stables {
                    Button(action: chooseHorse) { Label("Choose Horse", systemImage: "heart.fill") }.accessibilityIdentifier("choose-horse")
                    if player.canFly { Button(action: wand) { Text("🪄").font(.title) }.accessibilityLabel("Transform and fly").accessibilityIdentifier("launch-wand") }
                }
                if area == .washBay {
                    ForEach(Palette.allCases, id: \.self) { palette in
                        Button { choosePalette(palette) } label: {
                            Circle().fill(palette.color).frame(width: 27, height: 27)
                                .overlay(Circle().stroke(player.palette == palette ? Color.orange : Color.white, lineWidth: 3))
                        }.buttonStyle(.plain).frame(minWidth: 44, minHeight: 44).accessibilityLabel(palette.label)
                    }
                    Button(action: editCharacter) { Image(systemName: "person.crop.circle.fill").font(.title) }.accessibilityLabel("Edit Character")
                }
            }
            SpriteView(scene: session.scene).clipShape(RoundedRectangle(cornerRadius: 22))
                .accessibilityElement(children: .ignore).accessibilityLabel("Farm activity play area").accessibilityIdentifier("farm-task-canvas")
            ProgressView(value: session.progress).tint(.green).accessibilityLabel("Activity progress")
            if session.selected == .feed {
                HStack {
                    ForEach(Array(["🥕", "🍎", "Liquorice", "🌾"].enumerated()), id: \.offset) { index, icon in
                        Button { session.scene.foodVariant = index } label: {
                            if index == 2 {
                                Capsule().fill(Color(red: 0.12, green: 0.08, blue: 0.05)).frame(width: 36, height: 9)
                                    .rotationEffect(.degrees(-12)).frame(width: 44, height: 36)
                            } else { Text(icon).font(.title2) }
                        }.accessibilityLabel(["Carrot", "Apple", "Liquorice stick", "Hay"][index])
                    }
                }
            } else if session.selected == .treats {
                HStack {
                    Button { session.scene.foodVariant = 0 } label: { Text("🪱 Mealworms") }
                    Button { session.scene.foodVariant = 1 } label: { Text("🥬 Vegetables") }
                }
            }
            HStack(spacing: 8) {
                ForEach(area.activities) { activity in
                    Button { session.select(activity) } label: {
                        VStack(spacing: 2) {
                            Text(session.finished.contains(activity) ? "\(activity.icon) ✓" : activity.icon).font(.title2)
                            Text(activity.title).font(.caption).lineLimit(1).minimumScaleFactor(0.7)
                        }.frame(maxWidth: .infinity, minHeight: 50)
                    }.tint(session.selected == activity ? .purple : .brown).accessibilityIdentifier("activity-\(activity.rawValue)")
                }
            }
            Text(session.guide).font(.subheadline).lineLimit(2).frame(minHeight: 25)
        }
        .onAppear { updatePause() }
        .onDisappear { session.scene.pause() }
        .onChange(of: paused) { _ in updatePause() }
        .onChange(of: phase) { _ in updatePause() }
        .onChange(of: player) { session.scene.updatePlayer($0) }
    }
    private func updatePause() {
        if paused || phase != .active { session.scene.pause() } else { session.scene.resume() }
    }
}
struct RibbonRow: View {
    let player: Player
    var body: some View {
        HStack(spacing: 14) {
            ForEach(FarmArea.ribbonAreas) { area in
                HStack(spacing: 4) {
                    if let image = GameArt.region(sheet: "CareTackSheet", column: 3, row: 3, columns: 4, rows: 4) {
                        Image(uiImage: image).resizable().scaledToFit().frame(width: 29, height: 42)
                    } else { Text("🏵️") }
                    Text(area.icon).font(.title3)
                }.opacity(player.ribbons.contains(area.rawValue) ? 1 : 0.25)
                    .accessibilityElement(children: .ignore).accessibilityIdentifier("ribbon-\(area.rawValue)")
                    .accessibilityLabel("\(area.title) ribbon \(player.ribbons.contains(area.rawValue) ? "earned" : "not earned")")
            }
            Spacer(minLength: 0)
        }.padding(.horizontal, 12).padding(.vertical, 3).background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
struct RosetteCelebration: View {
    let area: FarmArea
    var body: some View {
        VStack(spacing: 5) {
            if let image = GameArt.region(sheet: "CareTackSheet", column: 3, row: 3, columns: 4, rows: 4) {
                Image(uiImage: image).resizable().scaledToFit().frame(height: 160)
            }
            Text("✨ \(area.icon) ✨").font(.largeTitle)
        }.padding(20).background(.ultraThinMaterial).clipShape(RoundedRectangle(cornerRadius: 30))
            .accessibilityLabel("You earned the \(area.title) ribbon")
    }
}
struct FarmhouseScreen: View {
    let player: Player
    let search: (Int) -> Void
    @State private var opened: Set<Int> = []
    private let names = ["Sofa cushion", "Toy basket", "Kitchen cupboard", "Bookshelf book", "Upstairs bed", "Hallway drawer"]
    // Bounds refer to real furniture in the farmhouse painting, not a menu grid.
    private let spots: [CGRect] = [
        CGRect(x: 0.24, y: 0.55, width: 0.105, height: 0.09),
        CGRect(x: 0.47, y: 0.78, width: 0.085, height: 0.12),
        CGRect(x: 0.72, y: 0.43, width: 0.07, height: 0.10),
        CGRect(x: 0.415, y: 0.405, width: 0.045, height: 0.08),
        CGRect(x: 0.84, y: 0.11, width: 0.10, height: 0.07),
        CGRect(x: 0.32, y: 0.485, width: 0.10, height: 0.04)
    ]
    var body: some View {
        VStack(spacing: 8) {
            Text("🏡 Farmhouse").font(.headline)
            Text(player.wandFound ? "🪄 Your wand is waiting at the stables" : (player.canFindWand ? "Explore the room · Look behind things" : "Explore the room · Three ribbons unlock your wand"))
                .font(.subheadline)
            GeometryReader { geometry in
                if let image = GameArt.environment(sheet: "FarmEnvironmentSheet", column: 0, row: 1) {
                    let scale = min(geometry.size.width / image.size.width, geometry.size.height / image.size.height)
                    let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
                    ZStack {
                        Image(uiImage: image).resizable().frame(width: size.width, height: size.height).allowsHitTesting(false)
                        ForEach(0..<6, id: \.self) { index in
                            let rect = spots[index]
                            let width = size.width * rect.width, height = size.height * rect.height
                            Button {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { opened.insert(index) }
                                let found = player.wandFound
                                search(index)
                                if !found && player.canFindWand && index == player.wandSpot { GameAudio.effect("wand", enabled: player.sfxEnabled) }
                            } label: {
                                ZStack {
                                    if opened.contains(index) {
                                        Color.brown.opacity(0.65).frame(width: width, height: height)
                                        if player.wandFound && index == player.wandSpot { Text("🪄").font(.system(size: max(22, height * 0.6))) }
                                    }
                                    if index == 1, let basket = GameArt.region(sheet: "FarmhouseSearchSheet", column: 1, row: 0, columns: 4, rows: 2) {
                                        Image(uiImage: basket).resizable().scaledToFit().frame(width: width, height: height)
                                            .offset(x: opened.contains(index) ? width * 0.55 : 0, y: opened.contains(index) ? -height * 0.1 : 0)
                                            .rotationEffect(.degrees(opened.contains(index) ? -8 : 0))
                                    } else if let crop = patch(image, rect: rect) {
                                        Image(uiImage: crop).resizable().frame(width: width, height: height)
                                            .offset(x: opened.contains(index) ? width * 0.55 : 0, y: opened.contains(index) ? -height * 0.18 : 0)
                                            .rotationEffect(.degrees(opened.contains(index) ? -6 : 0))
                                    }
                                }.frame(width: max(44, width), height: max(44, height)).contentShape(Rectangle())
                            }.buttonStyle(.plain).accessibilityLabel(names[index])
                                .accessibilityIdentifier("wand-search-\(index)")
                                .position(x: size.width * rect.midX, y: size.height * rect.midY)
                        }
                    }.frame(width: size.width, height: size.height)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
            }.clipped()
        }.onChange(of: player.dailyDate) { _ in opened = [] }
    }
    private func patch(_ image: UIImage, rect: CGRect) -> UIImage? {
        guard let source = image.cgImage,
              let crop = source.cropping(to: CGRect(x: CGFloat(source.width) * rect.minX, y: CGFloat(source.height) * rect.minY,
                                                   width: CGFloat(source.width) * rect.width, height: CGFloat(source.height) * rect.height)) else { return nil }
        return UIImage(cgImage: crop)
    }
}
struct WandLaunchScreen: View {
    let player: Player
    let launch: () -> Void
    @State private var offset = CGSize.zero
    var body: some View {
        VStack {
            Text("Drag your wand onto \(player.horse.name)").font(.title.bold()).padding()
            GeometryReader { geometry in
                let horseCenter = CGPoint(x: geometry.size.width / 2, y: geometry.size.height * 0.3)
                let wandCenter = CGPoint(x: geometry.size.width / 2, y: geometry.size.height * 0.78)
                HorsePortrait(horse: player.horse).frame(width: 230, height: 230).position(horseCenter)
                    .accessibilityIdentifier("wand-target")
                Text("↑ ✨").font(.largeTitle).position(x: wandCenter.x, y: geometry.size.height * 0.55)
                Text("🪄").font(.system(size: 90)).frame(width: 130, height: 130)
                    .position(x: wandCenter.x + offset.width, y: wandCenter.y + offset.height)
                    .accessibilityIdentifier("wand-drag")
                    .gesture(DragGesture().onChanged { offset = $0.translation }.onEnded { value in
                        let drop = CGPoint(x: wandCenter.x + value.translation.width, y: wandCenter.y + value.translation.height)
                        if CGRect(x: horseCenter.x - 140, y: horseCenter.y - 140, width: 280, height: 280).contains(drop) { launch() }
                        offset = .zero
                    })
            }
        }.background(Color(red: 0.95, green: 0.91, blue: 1)).padding()
    }
}
