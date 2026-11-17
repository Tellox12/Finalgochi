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
    var isSleeping: Bool
    var sleepStartedAt: Date?

    init(kind: PetKind, hunger: Double = 85, happiness: Double = 85, energy: Double = 85, level: Int = 1, experience: Int = 0, lastUpdated: Date = Date(), isSleeping: Bool = false, sleepStartedAt: Date? = nil) {
        self.kind = kind
        self.hunger = Self.clamp(hunger)
        self.happiness = Self.clamp(happiness)
        self.energy = Self.clamp(energy)
        self.level = max(1, level)
        self.experience = max(0, experience)
        self.lastUpdated = lastUpdated
        self.isSleeping = isSleeping
        self.sleepStartedAt = sleepStartedAt
    }

    private enum CodingKeys: String, CodingKey {
        case kind, hunger, happiness, energy, level, experience, lastUpdated, isSleeping, sleepStartedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        kind = try container.decode(PetKind.self, forKey: .kind)
        hunger = Self.clamp(try container.decode(Double.self, forKey: .hunger))
        happiness = Self.clamp(try container.decode(Double.self, forKey: .happiness))
        energy = Self.clamp(try container.decode(Double.self, forKey: .energy))
        level = max(1, try container.decode(Int.self, forKey: .level))
        experience = max(0, try container.decode(Int.self, forKey: .experience))
        lastUpdated = try container.decode(Date.self, forKey: .lastUpdated)
        isSleeping = try container.decodeIfPresent(Bool.self, forKey: .isSleeping) ?? false
        sleepStartedAt = try container.decodeIfPresent(Date.self, forKey: .sleepStartedAt)
    }

    var isGameOver: Bool { hunger <= 0 && happiness <= 0 && energy <= 0 }
    var nextLevelExperience: Int { level * 100 }

    mutating func update(for elapsed: TimeInterval, now: Date = Date()) {
        guard elapsed > 0 else { return }
        let minutes = elapsed / 60
        if isSleeping {
            let minutesUntilRested = max(0, (100 - energy) / 1.8)
            let sleepingMinutes = min(minutes, minutesUntilRested)
            hunger = Self.clamp(hunger - sleepingMinutes * 0.4)
            happiness = Self.clamp(happiness - sleepingMinutes * 0.1)
            energy = Self.clamp(energy + sleepingMinutes * 1.8)

            let awakeMinutes = minutes - sleepingMinutes
            if awakeMinutes > 0 {
                isSleeping = false
                sleepStartedAt = nil
                hunger = Self.clamp(hunger - awakeMinutes * 0.8)
                happiness = Self.clamp(happiness - awakeMinutes * 0.35)
                energy = Self.clamp(energy - awakeMinutes * 0.5)
            }
        } else {
            hunger = Self.clamp(hunger - minutes * 0.8)
            happiness = Self.clamp(happiness - minutes * 0.35)
            energy = Self.clamp(energy - minutes * 0.5)
        }
        lastUpdated = now
    }

    mutating func feed(amount: Double = 25) { hunger = Self.clamp(hunger + max(0, amount)) }
    mutating func increaseHappiness(by amount: Double) { happiness = Self.clamp(happiness + max(0, amount)) }
    mutating func restoreEnergy(by amount: Double) { energy = Self.clamp(energy + max(0, amount)) }
    mutating func play() { happiness = Self.clamp(happiness + 18); energy = Self.clamp(energy - 8) }

    mutating func startSleeping(at date: Date = Date()) {
        guard !isSleeping else { return }
        isSleeping = true
        sleepStartedAt = date
        lastUpdated = date
    }

    mutating func wake(at date: Date = Date()) {
        guard isSleeping else { return }
        isSleeping = false
        sleepStartedAt = nil
        lastUpdated = date
    }

    mutating func addExperience(_ amount: Int) {
        experience += max(0, amount)
        while experience >= nextLevelExperience {
            experience -= nextLevelExperience
            level += 1
        }
    }

    private static func clamp(_ value: Double) -> Double { min(100, max(0, value)) }
}
