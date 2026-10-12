import Foundation

enum HorseSize: String { case pony, riding, draft
    var scale: Double {
        switch self { case .pony: return 0.78; case .riding: return 1; case .draft: return 1.2 }
    }
}
enum HorseCoat: String { case bay, palomino, dun, dapple, paint, chestnut, black, appaloosa, white, piebald, fawn }
struct Horse: Identifiable {
    let id: String
    let name: String
    let description: String
    let coat: HorseCoat
    let size: HorseSize
    let portraitIndex: Int
}
enum HorseCatalog {
    // Twelve names remain provisional. The concept lineup had 14 entries;
    // its second generic bay (Charlie) is omitted to retain the specified 13.
    static let all: [Horse] = [
        Horse(id: "roo", name: "Roo", description: "Kind bay mare", coat: .bay, size: .riding, portraitIndex: 0),
        Horse(id: "sunny", name: "Sunny", description: "Friendly palomino", coat: .palomino, size: .riding, portraitIndex: 1),
        Horse(id: "dusty", name: "Dusty", description: "Gentle dun", coat: .dun, size: .riding, portraitIndex: 2),
        Horse(id: "bruno", name: "Bruno", description: "Gentle Clydesdale", coat: .bay, size: .draft, portraitIndex: 3),
        Horse(id: "luna", name: "Luna", description: "Calm dapple grey", coat: .dapple, size: .riding, portraitIndex: 4),
        Horse(id: "poppy", name: "Poppy", description: "Playful paint", coat: .paint, size: .riding, portraitIndex: 5),
        Horse(id: "daisy", name: "Daisy", description: "Confident Shetland", coat: .chestnut, size: .pony, portraitIndex: 6),
        Horse(id: "misty", name: "Misty", description: "Kind black pony", coat: .black, size: .pony, portraitIndex: 7),
        Horse(id: "pebbles", name: "Pebbles", description: "Curious spotted pony", coat: .appaloosa, size: .pony, portraitIndex: 8),
        Horse(id: "snowy", name: "Snowy", description: "Gentle white pony", coat: .white, size: .pony, portraitIndex: 9),
        Horse(id: "maple", name: "Maple", description: "Friendly chestnut pony", coat: .chestnut, size: .pony, portraitIndex: 10),
        Horse(id: "oreo", name: "Oreo", description: "Playful piebald pony", coat: .piebald, size: .pony, portraitIndex: 11),
        Horse(id: "biscuit", name: "Biscuit", description: "Calm fawn pony", coat: .fawn, size: .pony, portraitIndex: 12)
    ]
    static func horse(id: String) -> Horse { all.first { $0.id == id } ?? all[0] }
}
extension Player {
    var horse: Horse { HorseCatalog.horse(id: selectedHorseID) }
    mutating func selectHorse(_ id: String) {
        guard HorseCatalog.all.contains(where: { $0.id == id }) else { return }
        selectedHorseID = id // Tack, rider and outfit stay on this profile.
    }
}
