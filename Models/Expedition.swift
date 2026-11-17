import Foundation

enum ExpeditionRoute: String, CaseIterable, Codable, Hashable {
    case chocoboTrail
    case goblinMarket
    case crystalCavern

    var title: String {
        switch self {
        case .chocoboTrail: return "Sendero chocobo"
        case .goblinMarket: return "Mercado goblin"
        case .crystalCavern: return "Caverna cristalina"
        }
    }

    var symbol: String {
        switch self {
        case .chocoboTrail: return "🌿"
        case .goblinMarket: return "🏮"
        case .crystalCavern: return "💎"
        }
    }

    var description: String {
        switch self {
        case .chocoboTrail: return "Un paseo seguro entre hierbas Gysahl."
        case .goblinMarket: return "Un encargo rápido con comerciantes viajeros."
        case .crystalCavern: return "Una búsqueda peligrosa de cristales y tesoros."
        }
    }

    var duration: TimeInterval {
        switch self {
        case .chocoboTrail: return 60
        case .goblinMarket: return 180
        case .crystalCavern: return 360
        }
    }

    var minimumLevel: Int {
        switch self {
        case .chocoboTrail: return 1
        case .goblinMarket: return 2
        case .crystalCavern: return 4
        }
    }

    var minimumEnergy: Double {
        switch self {
        case .chocoboTrail: return 25
        case .goblinMarket: return 45
        case .crystalCavern: return 65
        }
    }

    var energyCost: Double {
        switch self {
        case .chocoboTrail: return 6
        case .goblinMarket: return 12
        case .crystalCavern: return 18
        }
    }

    var gilReward: Int {
        switch self {
        case .chocoboTrail: return 20
        case .goblinMarket: return 55
        case .crystalCavern: return 110
        }
    }

    var experienceReward: Int {
        switch self {
        case .chocoboTrail: return 12
        case .goblinMarket: return 35
        case .crystalCavern: return 75
        }
    }

    var loot: ConsumableItem {
        switch self {
        case .chocoboTrail: return .gysahlGreens
        case .goblinMarket: return .potion
        case .crystalCavern: return .ether
        }
    }
}

struct ActiveExpedition: Codable, Equatable {
    let route: ExpeditionRoute
    let startedAt: Date
    let finishesAt: Date

    init(route: ExpeditionRoute, startedAt: Date) {
        self.route = route
        self.startedAt = startedAt
        finishesAt = startedAt.addingTimeInterval(route.duration)
    }

    func remainingTime(at date: Date = Date()) -> TimeInterval {
        max(0, finishesAt.timeIntervalSince(date))
    }

    func progress(at date: Date = Date()) -> Double {
        let elapsed = date.timeIntervalSince(startedAt)
        return min(1, max(0, elapsed / route.duration))
    }

    func isReady(at date: Date = Date()) -> Bool {
        remainingTime(at: date) == 0
    }
}
