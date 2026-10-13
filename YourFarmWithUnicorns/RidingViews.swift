import SwiftUI
import SpriteKit

struct RidingScreen: View {
    @StateObject private var session: RidingSession
    @Environment(\.scenePhase) private var phase
    let player: Player
    let mode: RidingScene.Mode
    let paused: Bool
    init(player: Player, mode: RidingScene.Mode, paused: Bool, onActivity: @escaping (String) -> Void) {
        self.player = player; self.mode = mode; self.paused = paused
        _session = StateObject(wrappedValue: RidingSession(player: player, mode: mode, onActivity: onActivity))
    }
    var body: some View {
        VStack(spacing: 8) {
            if mode == .arena {
                HStack {
                    ForEach(Array(RideCourse.all.enumerated()), id: \.offset) { index, course in
                        Button { session.chooseCourse(index) } label: {
                            Text("\(index == session.courseIndex ? "✓ " : "")\(course.name)")
                        }.tint(index == session.courseIndex ? .purple : .brown)
                    }
                    Spacer()
                    Text("\(session.progress) / 3 jumps").font(.headline)
                }
            } else {
                Text(session.lunging ? "Round Yard · Lunging" : "Round Yard").font(.headline)
            }
            SpriteView(scene: session.scene)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .accessibilityLabel(mode == .arena ? "Riding arena" : "Round yard")
            HStack(spacing: 16) {
                if mode == .arena {
                    RideJoystick { session.scene.joystick = $0 }.frame(width: 120, height: 120)
                }
                ForEach(RideGait.allCases, id: \.self) { gait in
                    Button { session.setGait(gait) } label: {
                        VStack { Text(gait.icon).font(.title); Text(gait.label).font(.headline) }
                            .frame(minWidth: 74, minHeight: 58)
                    }.tint(session.gait == gait ? .purple : .brown)
                        .accessibilityAddTraits(session.gait == gait ? .isSelected : [])
                }
                if mode == .roundYard {
                    Button { session.toggleRunning() } label: {
                        Label(session.isRunning ? "Stop" : "Go", systemImage: session.isRunning ? "pause.fill" : "play.fill").frame(minHeight: 58)
                    }.tint(session.isRunning ? .purple : .brown).accessibilityIdentifier("round-go-stop")
                    Button { session.toggleLunging() } label: {
                        Label("Lunging", systemImage: "figure.equestrian.sports").frame(minHeight: 58)
                    }.tint(session.lunging ? .purple : .brown).accessibilityIdentifier("round-lunging")
                    Button { session.scene.changeDirection() } label: {
                        VStack { Image(systemName: "arrow.triangle.2.circlepath").font(.title); Text("Change Direction") }
                            .frame(minHeight: 58)
                    }
                    Button { session.togglePoles() } label: {
                        VStack { Text("▰ ▰ ▰").font(.title); Text(session.polesEnabled ? "Pole Practice: On" : "Pole Practice: Off") }.frame(minHeight: 58)
                    }.tint(session.polesEnabled ? .purple : .brown)
                        .accessibilityHint("Places four poles across the circular track. Press Go to step over them; turn off to put them away.")
                }
                Spacer(minLength: 0)
            }
            Text(session.notice.isEmpty ? (mode == .arena ? "Drag the joystick · Ride across glowing jumps · Tap fallen poles to reset" : (session.polesEnabled ? "Press Go · Your horse steps over four poles · Complete a circuit for pole practice" : "Choose an activity · Press Go · Stop whenever you like")) : session.notice)
                .font(.subheadline).lineLimit(2).frame(minHeight: 32)
                .accessibilityAddTraits(.updatesFrequently)
        }
        .onAppear { updatePause() }
        .onDisappear { session.scene.pause() }
        .onChange(of: player.sfxEnabled) { session.scene.soundEnabled = $0 }
        .onChange(of: paused) { _ in updatePause() }
        .onChange(of: phase) { _ in updatePause() }
    }
    private func updatePause() {
        if paused || phase != .active { session.scene.pause() } else { session.scene.resume() }
    }
}
struct RideJoystick: View {
    let changed: (RidePoint) -> Void
    @State private var thumb = CGSize.zero
    var body: some View {
        GeometryReader { geometry in
            let diameter = min(geometry.size.width, geometry.size.height)
            let radius = diameter * 0.3
            ZStack {
                Circle().fill(.brown.opacity(0.16)).overlay(Circle().stroke(.brown, lineWidth: 3))
                Image(systemName: "arrow.up.and.down.and.arrow.left.and.right").font(.system(size: 46)).foregroundColor(.brown.opacity(0.25))
                Circle().fill(.purple).frame(width: diameter * 0.4, height: diameter * 0.4).offset(thumb)
            }
            .contentShape(Circle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                let dx = value.location.x - diameter / 2
                let dy = value.location.y - diameter / 2
                let length = hypot(dx, dy)
                let factor = length > radius ? radius / length : 1
                thumb = CGSize(width: dx * factor, height: dy * factor)
                changed(RidePoint(x: Double(thumb.width / radius), y: Double(-thumb.height / radius)))
            }.onEnded { _ in thumb = .zero; changed(.zero) })
        }.accessibilityLabel("Directional riding joystick")
            .accessibilityHint("Drag in the direction you want to ride; release to stop")
            .onDisappear { changed(.zero) }
    }
}
