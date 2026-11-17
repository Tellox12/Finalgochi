import Foundation

struct DailyStreak: Codable, Equatable {
    private(set) var days = 0
    private(set) var lastClaimedDay: Date?
    private(set) var lastReward = 0

    init() {}

    private enum CodingKeys: String, CodingKey {
        case days, lastClaimedDay, lastReward
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        days = min(365, max(0, try values.decodeIfPresent(Int.self, forKey: .days) ?? 0))
        lastClaimedDay = try values.decodeIfPresent(Date.self, forKey: .lastClaimedDay)
        lastReward = min(50, max(0, try values.decodeIfPresent(Int.self, forKey: .lastReward) ?? 0))
    }

    @discardableResult
    mutating func claim(at date: Date = Date(), calendar: Calendar = .current) -> Int? {
        let today = calendar.startOfDay(for: date)
        if let lastClaimedDay, calendar.isDate(lastClaimedDay, inSameDayAs: today) { return nil }

        if let lastClaimedDay {
            let dayGap = calendar.dateComponents([.day], from: calendar.startOfDay(for: lastClaimedDay), to: today).day ?? 0
            guard dayGap > 0 else { return nil }
            days = dayGap == 1 ? min(days + 1, 365) : 1
        } else {
            days = 1
        }

        lastClaimedDay = today
        lastReward = 20 + min(days - 1, 6) * 5
        return lastReward
    }
}
