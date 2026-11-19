import XCTest
@testable import Finalgochi

final class ProgressionTests: XCTestCase {
    func testDailyQuestBoardCompletesFeedQuest() {
        var board = DailyQuestBoard()
        var reward = 0
        for _ in 0..<2 {
            reward += board.record(.feed)
        }
        XCTAssertEqual(reward, DailyQuestKind.feed.gilReward)
        XCTAssertEqual(board.record(.feed), 0)
        let quest = board.quests.first { $0.kind == .feed }
        XCTAssertEqual(quest?.progress, DailyQuestKind.feed.target)
        XCTAssertEqual(quest?.rewardClaimed, true)
    }

    func testDailyQuestBoardRollsOverOnNewDay() {
        let calendar = Calendar(identifier: .gregorian)
        let dayOne = Date(timeIntervalSince1970: 0)
        let dayTwo = dayOne.addingTimeInterval(48 * 60 * 60)
        var board = DailyQuestBoard(date: dayOne, calendar: calendar)
        _ = board.record(.play, at: dayOne, calendar: calendar)
        XCTAssertEqual(board.quests.first { $0.kind == .play }?.progress, 1)
        board.refreshIfNeeded(at: dayTwo, calendar: calendar)
        XCTAssertEqual(board.quests.first { $0.kind == .play }?.progress, 0)
    }

    func testDailyStreakRewardsOncePerDay() {
        let calendar = Calendar(identifier: .gregorian)
        let dayOne = Date(timeIntervalSince1970: 0)
        let dayTwo = dayOne.addingTimeInterval(24 * 60 * 60)
        var streak = DailyStreak()
        XCTAssertNotNil(streak.claim(at: dayOne, calendar: calendar))
        XCTAssertNil(streak.claim(at: dayOne.addingTimeInterval(60), calendar: calendar))
        XCTAssertNotNil(streak.claim(at: dayTwo, calendar: calendar))
        XCTAssertEqual(streak.days, 2)
    }

    func testActiveExpeditionBecomesReady() {
        let start = Date(timeIntervalSince1970: 10_000)
        let expedition = ActiveExpedition(route: .chocoboTrail, startedAt: start)
        XCTAssertFalse(expedition.isReady(at: start))
        XCTAssertTrue(expedition.isReady(at: start.addingTimeInterval(ExpeditionRoute.chocoboTrail.duration + 1)))
        XCTAssertEqual(expedition.remainingTime(at: start.addingTimeInterval(30)), 30, accuracy: 0.01)
    }

    func testEvolutionStageFromLevel() {
        XCTAssertEqual(EvolutionStage(level: 1), .hatchling)
        XCTAssertEqual(EvolutionStage(level: 5), .apprentice)
        XCTAssertEqual(EvolutionStage(level: 12), .veteran)
        XCTAssertEqual(EvolutionStage(level: 30), .legendary)
    }
}
