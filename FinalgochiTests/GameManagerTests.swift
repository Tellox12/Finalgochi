import XCTest
@testable import Finalgochi

final class GameManagerTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!
    private var manager: GameManager!

    override func setUp() {
        super.setUp()
        suiteName = "finalgochi.tests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
        manager = GameManager(defaults: defaults)
    }

    override func tearDown() {
        manager = nil
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testCreatePetUnlocksFirstFriendAndPersists() {
        manager.createPet(.chocobo)
        XCTAssertEqual(manager.pet?.kind, .chocobo)
        XCTAssertTrue(manager.progression.unlockedAchievements.contains(.firstFriend))
        XCTAssertGreaterThanOrEqual(manager.gil, 50)
    }

    func testConsumableIsNotWastedWhenPetIsFull() {
        manager.createPet(.moogle)
        // Hunger starts at 85: the first ration fills it, the second one must not be consumed.
        XCTAssertTrue(manager.use(.ration))
        let stockAfterFirst = manager.inventory[.ration, default: 0]
        XCTAssertFalse(manager.use(.ration))
        XCTAssertEqual(manager.inventory[.ration, default: 0], stockAfterFirst)
    }

    func testBuyingConsumablesNeverExceedsInventoryLimitOrOverdrawsGil() {
        manager.createPet(.cactilio)
        let startingGil = manager.gil
        let price = ConsumableItem.ration.price
        XCTAssertTrue(manager.buy(.ration, quantity: 10_000))
        // Buying everything affordable may leave change smaller than one item.
        XCTAssertEqual(manager.gil, startingGil % price)
        XCTAssertLessThan(manager.gil, price)
        XCTAssertLessThanOrEqual(manager.inventory[.ration, default: 0], 999)
        XCTAssertEqual(manager.inventory[.ration, default: 0], 2 + startingGil / price)
    }

    func testOfflineElapsedIsCappedAtTwelveHours() {
        manager.createPet(.moogle)
        guard let pet = manager.pet else { return XCTFail("Missing pet") }

        manager.updateElapsedTime(now: pet.lastUpdated.addingTimeInterval(48 * 60 * 60))

        XCTAssertEqual(manager.pet?.lastUpdated.timeIntervalSince1970 ?? 0, pet.lastUpdated.addingTimeInterval(48 * 60 * 60).timeIntervalSince1970, accuracy: 1)
        XCTAssertEqual(manager.pet?.hunger ?? -1, 0, accuracy: 0.01)
        XCTAssertGreaterThan(manager.pet?.happiness ?? 0, 0)
        XCTAssertGreaterThan(manager.pet?.energy ?? 0, 0)
        XCTAssertFalse(manager.pet?.isGameOver ?? true)
    }

    func testImportRebasesOldTimestampsAndDoesNotKillPet() throws {
        manager.createPet(.chocobo)
        guard let pet = manager.pet else { return XCTFail("Missing pet") }

        // Rewind the saved timestamp to simulate a backup stored weeks ago.
        let oldDate = pet.lastUpdated.addingTimeInterval(-30 * 24 * 60 * 60)
        var oldPet = pet
        oldPet.lastUpdated = oldDate
        oldPet.isSleeping = false
        oldPet.sleepStartedAt = nil
        defaults.set(try JSONEncoder().encode(oldPet), forKey: "finalgochi.pet")

        guard let data = manager.exportSave() else { return XCTFail("Missing export") }
        let now = Date()
        XCTAssertTrue(manager.importSave(data, now: now))
        XCTAssertEqual(manager.pet?.lastUpdated.timeIntervalSince1970 ?? 0, now.timeIntervalSince1970, accuracy: 1)
        XCTAssertFalse(manager.pet?.isGameOver ?? true)
    }

    func testImportRejectsGarbage() {
        manager.createPet(.moogle)
        XCTAssertFalse(manager.importSave(Data("not a save".utf8)))
        XCTAssertNotNil(manager.pet)
    }

    func testResetClearsSaveAndStreak() {
        manager.createPet(.moogle)
        _ = manager.claimDailyLogin()
        XCTAssertGreaterThan(manager.dailyStreak.days, 0)

        manager.reset()

        XCTAssertNil(manager.pet)
        XCTAssertEqual(manager.dailyStreak.days, 0)
        XCTAssertEqual(manager.gil, 50)
        XCTAssertEqual(manager.inventory[.ration], 2)
        XCTAssertEqual(defaults.object(forKey: "finalgochi.pet") as? Data, nil)
    }

    func testPlayMiniGameRequiresMinimumEnergy() {
        manager.createPet(.moogle)
        guard var pet = manager.pet else { return XCTFail("Missing pet") }
        pet.energy = 4
        pet.lastUpdated = Date()
        defaults.set(try? JSONEncoder().encode(pet), forKey: "finalgochi.pet")

        // Use a fresh manager so the low-energy pet is loaded from storage.
        let reloaded = GameManager(defaults: defaults)
        XCTAssertFalse(reloaded.canPlayMiniGame)
        XCTAssertFalse(reloaded.playMiniGame(success: true))
    }

    func testMateriaLimitsAndCasting() {
        manager.createPet(.moogle)
        XCTAssertTrue(manager.ownedMateria.contains(.cure))
        XCTAssertTrue(manager.equippedMateria.contains(.cure))

        manager.addGil(1_000)
        XCTAssertTrue(manager.buy(.fire))
        XCTAssertTrue(manager.buy(.haste))
        XCTAssertTrue(manager.toggleMateria(.fire))
        XCTAssertFalse(manager.toggleMateria(.haste)) // Only two slots.
        XCTAssertTrue(manager.equippedMateria.contains(.fire))
        XCTAssertTrue(manager.castMateria(.fire))
        XCTAssertLessThan(manager.magicPoints, GameManager.maximumMagicPoints)
    }

    func testExpeditionReportsRemainingTimeAndCanBeClaimed() {
        manager.createPet(.moogle)
        guard var pet = manager.pet else { return XCTFail("Missing pet") }
        pet.energy = 100
        pet.hunger = 100
        pet.happiness = 100
        pet.lastUpdated = Date()
        defaults.set(try? JSONEncoder().encode(pet), forKey: "finalgochi.pet")
        manager = GameManager(defaults: defaults)

        let start = Date()
        XCTAssertTrue(manager.startExpedition(.chocoboTrail, at: start))
        XCTAssertFalse(manager.claimExpedition(at: start))
        XCTAssertTrue(manager.claimExpedition(at: start.addingTimeInterval(ExpeditionRoute.chocoboTrail.duration + 1)))
        XCTAssertNil(manager.activeExpedition)
        XCTAssertGreaterThan(manager.progression.completedExpeditions, 0)
    }
}
