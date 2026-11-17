import Foundation

enum PetKind: String, CaseIterable, Codable {
    case moogle, chocobo, cactilio

    var displayName: String {
        switch self {
        case .moogle: return "Moogle"
        case .chocobo: return "Chocobo"
        case .cactilio: return "Cactilio"
        }
    }

    var emoji: String {
        switch self {
        case .moogle: return "☁️"
        case .chocobo: return "🐤"
        case .cactilio: return "🌵"
        }
    }
}

struct PetModel: Codable, Equatable {
    var kind: PetKind
    var hunger: Double
    var happiness: Double
    var energy: Double
    var level: Int
    var experience: Int
    var lastUpdated: Date

    init(kind: PetKind, hunger: Double = 85, happiness: Double = 85, energy: Double = 85, level: Int = 1, experience: Int = 0, lastUpdated: Date = Date()) {
        self.kind = kind
        self.hunger = Self.clamp(hunger)
        self.happiness = Self.clamp(happiness)
        self.energy = Self.clamp(energy)
        self.level = max(1, level)
        self.experience = max(0, experience)
        self.lastUpdated = lastUpdated
    }

    var isGameOver: Bool { hunger <= 0 && happiness <= 0 && energy <= 0 }
    var nextLevelExperience: Int { level * 100 }

    mutating func update(for elapsed: TimeInterval, now: Date = Date()) {
        guard elapsed > 0 else { return }
        let minutes = elapsed / 60
        hunger = Self.clamp(hunger - minutes * 0.8)
        happiness = Self.clamp(happiness - minutes * 0.35)
        energy = Self.clamp(energy - minutes * 0.5)
        lastUpdated = now
    }

    mutating func feed() { hunger = Self.clamp(hunger + 25) }
    mutating func play() { happiness = Self.clamp(happiness + 18); energy = Self.clamp(energy - 8) }
    mutating func sleep() { energy = Self.clamp(energy + 25) }

    mutating func addExperience(_ amount: Int) {
        experience += max(0, amount)
        while experience >= nextLevelExperience {
            experience -= nextLevelExperience
            level += 1
        }
    }

    private static func clamp(_ value: Double) -> Double { min(100, max(0, value)) }
}
