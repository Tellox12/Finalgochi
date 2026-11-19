import Foundation

enum DailyQuestKind: String, CaseIterable, Codable {
    case feed
    case play
    case sleep
    case expedition

    var title: String {
        switch self {
        case .feed: return "Dale de comer 2 veces"
        case .play: return "Juega una partida"
        case .sleep: return "Deja que descanse"
        case .expedition: return "Completa una expedición"
        }
    }

    var target: Int {
        switch self {
        case .feed: return 2
        case .play, .sleep, .expedition: return 1
        }
    }

    var gilReward: Int {
        switch self {
        case .feed: return 15
        case .play: return 20
        case .sleep: return 15
        case .expedition: return 30
        }
    }

    var symbolName: String {
        switch self {
        case .feed: return "fork.knife"
        case .play: return "gamecontroller.fill"
        case .sleep: return "moon.stars.fill"
        case .expedition: return "map.fill"
        }
    }
}

struct DailyQuest: Codable, Equatable, Identifiable {
    let kind: DailyQuestKind
    var progress: Int
    var rewardClaimed: Bool

    var id: String { kind.rawValue }
    var isComplete: Bool { progress >= kind.target }
    var summary: String {
        "\(kind.title)  \(min(progress, kind.target))/\(kind.target)"
    }

    init(kind: DailyQuestKind, progress: Int = 0, rewardClaimed: Bool = false) {
        self.kind = kind
        self.progress = min(kind.target, max(0, progress))
        self.rewardClaimed = rewardClaimed
    }

    mutating func advance() -> Int {
        guard !rewardClaimed else { return 0 }
        progress = min(kind.target, progress + 1)
        guard isComplete else { return 0 }
        rewardClaimed = true
        return kind.gilReward
    }
}

struct DailyQuestBoard: Codable, Equatable {
    private(set) var dayKey: String
    private(set) var quests: [DailyQuest]

    init(date: Date = Date(), calendar: Calendar = .current) {
        dayKey = Self.key(for: date, calendar: calendar)
        quests = DailyQuestKind.allCases.map { DailyQuest(kind: $0) }
    }

    mutating func record(_ kind: DailyQuestKind, at date: Date = Date(), calendar: Calendar = .current) -> Int {
        refreshIfNeeded(at: date, calendar: calendar)
        guard let index = quests.firstIndex(where: { $0.kind == kind }) else { return 0 }
        return quests[index].advance()
    }

    mutating func refreshIfNeeded(at date: Date = Date(), calendar: Calendar = .current) {
        let today = Self.key(for: date, calendar: calendar)
        if dayKey != today {
            dayKey = today
            quests = DailyQuestKind.allCases.map { DailyQuest(kind: $0) }
            return
        }

        for kind in DailyQuestKind.allCases where !quests.contains(where: { $0.kind == kind }) {
            quests.append(DailyQuest(kind: kind))
        }
    }

    private static func key(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
    }
}
