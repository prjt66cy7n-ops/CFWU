import Foundation

struct RidePoint: Equatable {
    var x: Double
    var y: Double
    static let zero = RidePoint(x: 0, y: 0)
    static func + (a: Self, b: Self) -> Self { Self(x: a.x + b.x, y: a.y + b.y) }
    static func - (a: Self, b: Self) -> Self { Self(x: a.x - b.x, y: a.y - b.y) }
    static func * (a: Self, b: Double) -> Self { Self(x: a.x * b, y: a.y * b) }
    var length: Double { hypot(x, y) }
    var normalized: Self { length > 0 ? self * (1 / length) : .zero }
    func dot(_ other: Self) -> Double { x * other.x + y * other.y }
}
enum RideGait: String, CaseIterable {
    case walk, trot, canter
    var speed: Double {
        switch self { case .walk: return 100; case .trot: return 160; case .canter: return 220 }
    }
    var label: String { rawValue.capitalized }
    var icon: String {
        switch self { case .walk: return "🐾"; case .trot: return "🐎"; case .canter: return "💨" }
    }
}
enum RideFacing: Int, CaseIterable {
    // Angle zero is right; matches SpriteKit's positive-y-up coordinates.
    case east, northEast, north, northWest, west, southWest, south, southEast
    static func from(_ vector: RidePoint) -> Self {
        let octant = Int((atan2(vector.y, vector.x) / (.pi / 4)).rounded())
        return Self(rawValue: (octant + 8) % 8)!
    }
    var vector: RidePoint {
        let angle = Double(rawValue) * .pi / 4
        return RidePoint(x: cos(angle), y: sin(angle))
    }
}
struct RideObstacle: Identifiable {
    let id: Int
    let center: RidePoint
    // Pole lies along tangent; the correct approach crosses its normal.
    let normal: RidePoint
    let halfWidth: Double
}
struct RideCourse {
    let id: String
    let name: String
    let jumps: [RideObstacle]
    static let all: [Self] = [
        Self(id: "flowers", name: "Flower Trail", jumps: [
            RideObstacle(id: 0, center: RidePoint(x: 280, y: 240), normal: RidePoint(x: 0, y: 1), halfWidth: 60),
            RideObstacle(id: 1, center: RidePoint(x: 500, y: 410), normal: RidePoint(x: 1, y: 0), halfWidth: 60),
            RideObstacle(id: 2, center: RidePoint(x: 740, y: 240), normal: RidePoint(x: 0, y: 1), halfWidth: 60)
        ]),
        Self(id: "rainbow", name: "Rainbow Loop", jumps: [
            RideObstacle(id: 0, center: RidePoint(x: 270, y: 340), normal: RidePoint(x: 1, y: 0), halfWidth: 60),
            RideObstacle(id: 1, center: RidePoint(x: 550, y: 210), normal: RidePoint(x: 0, y: 1), halfWidth: 60),
            RideObstacle(id: 2, center: RidePoint(x: 750, y: 390), normal: RidePoint(x: 1, y: 0), halfWidth: 60)
        ]),
        Self(id: "clover", name: "Clover Course", jumps: [
            RideObstacle(id: 0, center: RidePoint(x: 270, y: 210), normal: RidePoint(x: 0, y: 1), halfWidth: 60),
            RideObstacle(id: 1, center: RidePoint(x: 520, y: 410), normal: RidePoint(x: 0, y: 1), halfWidth: 60),
            RideObstacle(id: 2, center: RidePoint(x: 760, y: 210), normal: RidePoint(x: 0, y: 1), halfWidth: 60)
        ])
    ]
}
struct ArenaRide {
    static let width = 1000.0
    static let height = 620.0
    static let inset = 70.0
    var position = RidePoint(x: 150, y: 135)
    var gait: RideGait = .walk
    var facing: RideFacing = .east
    private(set) var courseIndex = 0
    private(set) var completedJumps: Set<Int> = []
    private(set) var fallenPoles: Set<Int> = []
    private(set) var jumpHeight = 0.0
    private(set) var feedback: String?
    private(set) var justCompletedCourse = false
    private var leap: Leap?
    private var attempts = 0
    private var cooldown = 0.0
    struct Leap {
        let start: RidePoint
        let end: RidePoint
        let obstacleID: Int
        let willKnock: Bool
        var elapsed = 0.0
    }
    var course: RideCourse { RideCourse.all[courseIndex] }
    var isJumping: Bool { leap != nil }
    var courseComplete: Bool { completedJumps.count == course.jumps.count }
    mutating func chooseCourse(_ index: Int) {
        guard RideCourse.all.indices.contains(index) else { return }
        self = ArenaRide(); courseIndex = index
    }
    mutating func resetPole(_ id: Int) { fallenPoles.remove(id) }
    mutating func step(seconds: Double, input: RidePoint) {
        justCompletedCourse = false; feedback = nil
        guard seconds.isFinite, seconds > 0, input.x.isFinite, input.y.isFinite else { return }
        let dt = min(seconds, 0.1) // Ignore long pauses instead of teleporting.
        cooldown = max(0, cooldown - dt)
        if var leap {
            leap.elapsed += dt
            let t = min(1, leap.elapsed / 0.65)
            position = leap.start + (leap.end - leap.start) * t
            jumpHeight = sin(t * .pi) * 42
            if t >= 1 {
                let alreadyComplete = courseComplete
                completedJumps.insert(leap.obstacleID)
                if leap.willKnock { fallenPoles.insert(leap.obstacleID); feedback = "Oops! Tap the pole to put it back." }
                self.leap = nil; jumpHeight = 0; cooldown = 0.4
                justCompletedCourse = !alreadyComplete && courseComplete
            } else { self.leap = leap }
            return
        }
        let direction = input.length > 1 ? input.normalized : input
        if direction.length < 0.04 { return }
        facing = .from(direction)
        let next = clamped(position + direction * (gait.speed * dt))
        if cooldown == 0 {
            for jump in course.jumps where !fallenPoles.contains(jump.id) {
                let from = position - jump.center
                let to = next - jump.center
                let side = from.dot(jump.normal)
                let toward = side * direction.dot(jump.normal) < 0
                let tangent = RidePoint(x: -jump.normal.y, y: jump.normal.x)
                let alignment = abs(direction.normalized.dot(jump.normal))
                // Begin before reaching the rails; both approach directions work.
                if toward && alignment >= 0.82 && abs(to.dot(jump.normal)) <= 42 && abs(from.dot(tangent)) <= jump.halfWidth - 8 {
                    attempts += 1
                    if attempts.isMultiple(of: 11) {
                        position = clamped(position + tangent * 45)
                        cooldown = 0.7; feedback = "A little detour! Try again whenever you like."
                    } else {
                        let landing = position + direction.normalized * (abs(side) / alignment + 65)
                        leap = Leap(start: position, end: clamped(landing), obstacleID: jump.id, willKnock: attempts.isMultiple(of: 7))
                    }
                    return
                }
            }
        }
        position = next
    }
    private func clamped(_ point: RidePoint) -> RidePoint {
        RidePoint(x: min(Self.width - Self.inset, max(Self.inset, point.x)),
                  y: min(Self.height - Self.inset, max(Self.inset, point.y)))
    }
}
struct RoundYardRide {
    var gait: RideGait = .walk
    private(set) var angle = -Double.pi / 2
    private(set) var direction = 1.0
    private(set) var polesEnabled = false
    private(set) var isTurning = false
    private(set) var completedActivities: [String] = []
    private var turnElapsed = 0.0
    private var gaitDistance = 0.0
    private var poleDistance = 0.0
    var speedMultiplier: Double {
        guard isTurning else { return 1 }
        return abs(1 - turnElapsed / 0.75)
    }
    var position: RidePoint { RidePoint(x: 500 + cos(angle) * 280, y: 310 + sin(angle) * 215) }
    var facing: RideFacing { .from(RidePoint(x: -sin(angle) * direction, y: cos(angle) * direction)) }
    mutating func setGait(_ new: RideGait) {
        if new != gait { gaitDistance = 0 }
        gait = new
    }
    mutating func togglePoles() { polesEnabled.toggle(); poleDistance = 0 }
    mutating func changeDirection() {
        guard !isTurning else { return }
        isTurning = true; turnElapsed = 0; gaitDistance = 0; poleDistance = 0
    }
    mutating func step(seconds: Double) {
        completedActivities = []
        guard seconds.isFinite, seconds > 0 else { return }
        let dt = min(seconds, 0.1)
        if isTurning {
            let old = turnElapsed
            turnElapsed = min(1.5, turnElapsed + dt)
            if old < 0.75 && turnElapsed >= 0.75 { direction *= -1 }
            angle += direction * gait.speed / 280 * dt * speedMultiplier
            if turnElapsed >= 1.5 { isTurning = false }
            return
        }
        let delta = gait.speed / 280 * dt
        angle += direction * delta
        angle.formTruncatingRemainder(dividingBy: .pi * 2)
        gaitDistance += delta
        if gaitDistance >= .pi * 2 { completedActivities.append(gait.rawValue); gaitDistance -= .pi * 2 }
        if polesEnabled {
            poleDistance += delta
            if poleDistance >= .pi * 2 { completedActivities.append("groundPoles"); poleDistance -= .pi * 2 }
        }
    }
}
