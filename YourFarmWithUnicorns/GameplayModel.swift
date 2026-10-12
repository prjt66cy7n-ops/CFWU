import Foundation

enum FarmArea: String, CaseIterable, Identifiable {
    case stables, washBay, arena, roundYard, paddock, chickenCoop, farmhouse
    var id: String { rawValue }
    var title: String {
        switch self {
        case .stables: return "Stables"
        case .washBay: return "Wash Bay"
        case .arena: return "Arena"
        case .roundYard: return "Round Yard"
        case .paddock: return "Paddocks"
        case .chickenCoop: return "Chicken Coop"
        case .farmhouse: return "Farmhouse"
        }
    }
    var icon: String {
        switch self {
        case .stables: return "🐴"
        case .washBay: return "🧽"
        case .arena: return "🏇"
        case .roundYard: return "⭕️"
        case .paddock: return "🌾"
        case .chickenCoop: return "🐔"
        case .farmhouse: return "🏡"
        }
    }
    static let ribbonAreas: [Self] = [.stables, .paddock, .arena, .roundYard, .washBay, .chickenCoop]
    var activities: [FarmActivity] {
        switch self {
        case .stables: return [.feed, .stableWater, .sweepStable]
        case .washBay: return [.brush, .hooves, .wash, .tack]
        case .paddock: return [.manure, .trough, .paddockWater, .hay, .fence]
        case .chickenCoop: return [.eggs, .grain, .coopWater, .sweepCoop, .straw, .treats]
        default: return []
        }
    }
    var activityIDs: Set<String> {
        switch self {
        case .arena: return Set(RideCourse.all.map(\.id))
        case .roundYard: return ["walk", "trot", "canter", "groundPoles"]
        default: return Set(activities.map(\.rawValue))
        }
    }
}
enum FarmActivity: String, CaseIterable, Identifiable {
    case feed, stableWater, sweepStable, brush, hooves, wash, tack
    case manure, trough, paddockWater, hay, fence
    case eggs, grain, coopWater, sweepCoop, straw, treats
    var id: String { rawValue }
    var title: String {
        switch self {
        case .feed: return "Feed Horse"
        case .stableWater, .paddockWater: return "Water Bucket"
        case .sweepStable: return "Sweep Stable"
        case .brush: return "Brush Coat"
        case .hooves: return "Pick Hooves"
        case .wash: return "Wash Horse"
        case .tack: return "Tack Up"
        case .manure: return "Scoop Manure"
        case .trough: return "Clean Trough"
        case .hay: return "Give Hay"
        case .fence: return "Fix Fence"
        case .eggs: return "Collect Eggs"
        case .grain: return "Feed Chickens"
        case .coopWater: return "Refill Water"
        case .sweepCoop: return "Clean Coop"
        case .straw: return "Fresh Straw"
        case .treats: return "Give Treats"
        }
    }
    var icon: String {
        switch self {
        case .feed: return "🥕"
        case .stableWater, .paddockWater, .coopWater: return "💧"
        case .sweepStable, .sweepCoop: return "🧹"
        case .brush: return "🪮"
        case .hooves: return "🧲"
        case .wash: return "🫧"
        case .tack: return "🐎"
        case .manure: return "🛒"
        case .trough: return "🧽"
        case .hay, .straw: return "🌾"
        case .fence: return "🔨"
        case .eggs: return "🥚"
        case .grain: return "🌽"
        case .treats: return "🥬"
        }
    }
}
extension Player {
    var canFindWand: Bool { ribbons.intersection(Set(FarmArea.ribbonAreas.map(\.rawValue))).count >= 3 }
    var canFly: Bool { canFindWand && wandFound }
    @discardableResult mutating func completeActivity(area: FarmArea, activity: String, now: Date = Date(), calendar: Calendar = .current) -> Bool {
        refreshDay(now: now, calendar: calendar)
        guard area.activityIDs.contains(activity) else { return false }
        completedActivities[area.rawValue, default: []].insert(activity)
        let distinct = completedActivities[area.rawValue, default: []].intersection(area.activityIDs)
        guard distinct.count >= min(3, area.activityIDs.count), !area.activityIDs.isEmpty,
              !ribbons.contains(area.rawValue) else { return false }
        ribbons.insert(area.rawValue)
        return true
    }
    @discardableResult mutating func discoverWand(at spot: Int, now: Date = Date(), calendar: Calendar = .current) -> Bool {
        refreshDay(now: now, calendar: calendar)
        guard canFindWand, !wandFound, spot == wandSpot, (0..<6).contains(spot) else { return false }
        wandFound = true; return true
    }
}

// Scene-entry state only; nothing in this type is written to the child save.
struct ChoreGame {
    let activity: FarmActivity
    let brokenFence: Bool
    var stage = 0
    var progress = 0.0
    var completed = false
    var collection: Set<Int> = []
    var revealed: Set<Int> = []
    var liftedHoof: Int?
    var hoofPicks = [0, 0, 0, 0]
    var bucketAtTap = false
    var bucketFull = false
    var tack: Tack
    init(activity: FarmActivity, tack: Tack = Tack(), brokenFence: Bool = true) {
        self.activity = activity; self.tack = tack; self.brokenFence = brokenFence
    }
    var isScrubbing: Bool { [.brush, .wash, .trough, .sweepStable, .sweepCoop, .grain].contains(activity) }
    mutating func scrub(distance: Double) {
        guard !completed, isScrubbing, distance.isFinite, distance > 0 else { return }
        if activity == .trough && stage != 0 { return }
        let required: Double = activity == .wash && stage != 1 ? 280 : 600
        progress = min(1, progress + min(distance, 80) / required)
        if progress >= 1 {
            if activity == .wash {
                if stage < 2 { stage += 1; progress = 0 } else { completed = true }
            } else if activity == .trough { stage = 1; progress = 0 }
            else { completed = true }
        }
    }
    mutating func holdWater(seconds: Double) {
        guard activity == .coopWater, !completed, seconds.isFinite, seconds > 0 else { return }
        progress = min(1, progress + min(seconds, 0.1) / 1.8)
        if progress >= 1 { completed = true }
    }
    mutating func tapTarget(_ index: Int = 0) {
        guard !completed else { return }
        switch activity {
        case .manure: if (0..<5).contains(index), !collection.contains(index) { revealed.insert(index) }
        case .eggs: if (0..<4).contains(index), !collection.contains(index) { revealed.insert(index) }
        case .straw: if (0..<4).contains(index), !collection.contains(index) { revealed.insert(index) }
        case .hooves:
            guard (0..<4).contains(index), hoofPicks[index] < 3 else { return }
            if liftedHoof == index {
                hoofPicks[index] += 1
                if hoofPicks[index] == 3 { collection.insert(index); liftedHoof = nil }
                if collection.count == 4 { completed = true }
            } else { liftedHoof = index }
        case .stableWater, .paddockWater: if bucketAtTap { bucketFull = true }
        case .trough: if stage == 1 { progress = 1; completed = true }
        case .fence:
            if brokenFence { stage += 1; progress = Double(stage) / 5; completed = stage >= 5 }
        default: break
        }
    }
    mutating func liftHoof(_ index: Int) {
        guard activity == .hooves, !completed, (0..<4).contains(index), hoofPicks[index] < 3 else { return }
        liftedHoof = index
    }
    mutating func pickLiftedHoof() {
        guard activity == .hooves, let index = liftedHoof else { return }
        tapTarget(index)
    }
    mutating func dropAtTap() {
        guard [.stableWater, .paddockWater].contains(activity), !completed else { return }
        bucketAtTap = true
    }
    mutating func dropAtDestination(item: Int = 0) {
        guard !completed else { return }
        switch activity {
        case .feed, .hay, .treats: progress = 1; completed = true
        case .stableWater, .paddockWater: if bucketFull { progress = 1; completed = true }
        case .manure:
            if (0..<5).contains(item), revealed.contains(item) { collection.insert(item); progress = Double(collection.count) / 5; completed = collection.count == 5 }
        case .eggs, .straw:
            if (0..<4).contains(item), revealed.contains(item) { collection.insert(item); progress = Double(collection.count) / 4; completed = collection.count == 4 }
        default: break
        }
    }
    mutating func equip(_ item: Int) {
        guard activity == .tack, (0..<3).contains(item) else { return }
        let previouslyFull = tack.saddlePad && tack.saddle && tack.bridle
        switch item { case 0: tack.saddlePad = true; case 1: tack.saddle = true; default: tack.bridle = true }
        if !previouslyFull && tack.saddlePad && tack.saddle && tack.bridle { completed = true; progress = 1 }
    }
    mutating func removeTack(_ item: Int) {
        guard activity == .tack else { return }
        switch item { case 0: tack.saddlePad = false; case 1: tack.saddle = false; case 2: tack.bridle = false; default: return }
        completed = false; progress = 0
    }
}
struct UnicornAppearance {
    let sourceHorseID: String
    let size: HorseSize
    let palette: Palette
    let winged = true
    let whiteBaseCoat = true
    let tackVisible = false
    init(player: Player) { sourceHorseID = player.horse.id; size = player.horse.size; palette = player.palette }
}
struct FlightGame {
    enum Phase { case transformation, flying, finale, finished }
    static let duration = 38.0
    private(set) var elapsed = 0.0
    private(set) var rainbowStars = 0
    private(set) var exited = false
    var phase: Phase {
        if exited || elapsed >= Self.duration { return .finished }
        if elapsed < 2.5 { return .transformation }
        if elapsed < 35 { return .flying }
        return .finale
    }
    var routeProgress: Double { min(1, max(0, (elapsed - 2.5) / 32.5)) }
    mutating func step(seconds: Double) {
        guard !exited, seconds.isFinite, seconds > 0 else { return }
        elapsed = min(Self.duration, elapsed + min(seconds, 0.1))
    }
    mutating func tapStar() { if phase == .flying { rainbowStars += 1 } }
    mutating func home() { exited = true }
}
