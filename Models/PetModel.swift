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

struct PetCareModifiers: Equatable {
    var hungerDecayMultiplier: Double
    var happinessDecayMultiplier: Double
    var energyDecayMultiplier: Double
    var sleepRecoveryMultiplier: Double
    var experienceGainMultiplier: Double

    init(hungerDecayMultiplier: Double = 1, happinessDecayMultiplier: Double = 1, energyDecayMultiplier: Double = 1, sleepRecoveryMultiplier: Double = 1, experienceGainMultiplier: Double = 1) {
        self.hungerDecayMultiplier = max(0.1, hungerDecayMultiplier)
        self.happinessDecayMultiplier = max(0.1, happinessDecayMultiplier)
        self.energyDecayMultiplier = max(0.1, energyDecayMultiplier)
        self.sleepRecoveryMultiplier = max(0.1, sleepRecoveryMultiplier)
        self.experienceGainMultiplier = max(0.1, experienceGainMultiplier)
    }

    func combined(with other: PetCareModifiers) -> PetCareModifiers {
        PetCareModifiers(
            hungerDecayMultiplier: hungerDecayMultiplier * other.hungerDecayMultiplier,
            happinessDecayMultiplier: happinessDecayMultiplier * other.happinessDecayMultiplier,
            energyDecayMultiplier: energyDecayMultiplier * other.energyDecayMultiplier,
            sleepRecoveryMultiplier: sleepRecoveryMultiplier * other.sleepRecoveryMultiplier,
            experienceGainMultiplier: experienceGainMultiplier * other.experienceGainMultiplier
        )
    }
}

struct PetModel: Codable, Equatable {
    var kind: PetKind
    var name: String
    var hunger: Double
    var happiness: Double
    var energy: Double
    var level: Int
    var experience: Int
    var lastUpdated: Date
    var isSleeping: Bool
    var sleepStartedAt: Date?

    init(kind: PetKind, name: String? = nil, hunger: Double = 85, happiness: Double = 85, energy: Double = 85, level: Int = 1, experience: Int = 0, lastUpdated: Date = Date(), isSleeping: Bool = false, sleepStartedAt: Date? = nil) {
        self.kind = kind
        self.name = Self.normalizedName(name, fallback: kind.displayName)
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
        case kind, name, hunger, happiness, energy, level, experience, lastUpdated, isSleeping, sleepStartedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        kind = try container.decode(PetKind.self, forKey: .kind)
        name = Self.normalizedName(try container.decodeIfPresent(String.self, forKey: .name), fallback: kind.displayName)
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
    var mood: PetMood {
        if isSleeping { return .sleeping }
        if energy < 25 { return .tired }
        if hunger < 30 { return .hungry }
        if happiness < 30 { return .sad }
        if happiness >= 75 { return .joyful }
        return .calm
    }

    mutating func update(for elapsed: TimeInterval, now: Date = Date(), modifiers: PetCareModifiers = PetCareModifiers()) {
        guard elapsed > 0 else { return }
        let minutes = elapsed / 60
        if isSleeping {
            let recoveryRate = 1.8 * modifiers.sleepRecoveryMultiplier
            let minutesUntilRested = max(0, (100 - energy) / recoveryRate)
            let sleepingMinutes = min(minutes, minutesUntilRested)
            hunger = Self.clamp(hunger - sleepingMinutes * 0.4 * modifiers.hungerDecayMultiplier)
            happiness = Self.clamp(happiness - sleepingMinutes * 0.1 * modifiers.happinessDecayMultiplier)
            energy = Self.clamp(energy + sleepingMinutes * recoveryRate)

            let awakeMinutes = minutes - sleepingMinutes
            if awakeMinutes > 0 {
                isSleeping = false
                sleepStartedAt = nil
                hunger = Self.clamp(hunger - awakeMinutes * 0.8 * modifiers.hungerDecayMultiplier)
                happiness = Self.clamp(happiness - awakeMinutes * 0.35 * modifiers.happinessDecayMultiplier)
                energy = Self.clamp(energy - awakeMinutes * 0.5 * modifiers.energyDecayMultiplier)
            }
        } else {
            hunger = Self.clamp(hunger - minutes * 0.8 * modifiers.hungerDecayMultiplier)
            happiness = Self.clamp(happiness - minutes * 0.35 * modifiers.happinessDecayMultiplier)
            energy = Self.clamp(energy - minutes * 0.5 * modifiers.energyDecayMultiplier)
        }
        lastUpdated = now
    }

    mutating func feed(amount: Double = 25) { hunger = Self.clamp(hunger + max(0, amount)) }

    @discardableResult
    mutating func rename(to newName: String) -> Bool {
        let normalized = Self.normalizedName(newName, fallback: "")
        guard !normalized.isEmpty, normalized != name else { return false }
        name = normalized
        return true
    }

    mutating func increaseHappiness(by amount: Double) { happiness = Self.clamp(happiness + max(0, amount)) }
    mutating func restoreEnergy(by amount: Double) { energy = Self.clamp(energy + max(0, amount)) }
    mutating func spendEnergy(_ amount: Double) { energy = Self.clamp(energy - max(0, amount)) }
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

    private static func normalizedName(_ value: String?, fallback: String) -> String {
        guard let value else { return fallback }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return fallback }
        return String(trimmed.prefix(16))
    }
}
