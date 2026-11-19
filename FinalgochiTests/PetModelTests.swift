import XCTest
@testable import Finalgochi

final class PetModelTests: XCTestCase {
    func testAwakeDecaySurvivesHalfADay() {
        var pet = PetModel(kind: .moogle, hunger: 100, happiness: 100, energy: 100, lastUpdated: Date(timeIntervalSince1970: 0))
        pet.update(for: 12 * 60 * 60, now: Date(timeIntervalSince1970: 12 * 60 * 60))
        XCTAssertFalse(pet.isGameOver)
        XCTAssertEqual(pet.hunger, 0, accuracy: 0.01)
        XCTAssertGreaterThan(pet.happiness, 0)
        XCTAssertGreaterThan(pet.energy, 0)
    }

    func testHungerTakesAtLeastElevenHoursToEmpty() {
        var pet = PetModel(kind: .cactilio, hunger: 100, happiness: 100, energy: 100)
        let start = Date(timeIntervalSince1970: 0)
        pet.lastUpdated = start
        pet.update(for: 10 * 60 * 60, now: start.addingTimeInterval(10 * 60 * 60))
        XCTAssertGreaterThan(pet.hunger, 0)
        XCTAssertFalse(pet.isGameOver)
    }

    func testSleepingRecoversEnergyAndWakesAfterEightHours() {
        let start = Date(timeIntervalSince1970: 1_000)
        var pet = PetModel(kind: .chocobo, hunger: 100, happiness: 100, energy: 10, lastUpdated: start)
        pet.startSleeping(at: start)
        pet.update(for: PetModel.sleepDuration, now: start.addingTimeInterval(PetModel.sleepDuration))
        XCTAssertEqual(pet.energy, 100, accuracy: 0.01)
        XCTAssertFalse(pet.isSleeping)
        XCTAssertNil(pet.sleepStartedAt)
        XCTAssertGreaterThan(pet.hunger, 80)
    }

    func testSleepingThenAwakeTimeIsSplitCorrectly() {
        let start = Date(timeIntervalSince1970: 5_000)
        var pet = PetModel(kind: .moogle, hunger: 100, happiness: 100, energy: 0, lastUpdated: start)
        pet.startSleeping(at: start)
        pet.update(for: 10 * 60 * 60, now: start.addingTimeInterval(10 * 60 * 60))
        XCTAssertFalse(pet.isSleeping)
        // Two awake hours after eight sleeping hours should drain energy again.
        XCTAssertEqual(pet.energy, 100 - 2 * 60 * 0.11, accuracy: 0.1)
        XCTAssertLessThan(pet.energy, 100)
    }

    func testExperienceLevelsUpMultipleTimes() {
        var pet = PetModel(kind: .moogle, level: 1)
        pet.addExperience(350)
        XCTAssertEqual(pet.level, 3)
        XCTAssertEqual(pet.experience, 50)
    }

    func testRenameRejectsEmptyAndLongClamps() {
        var pet = PetModel(kind: .moogle)
        XCTAssertFalse(pet.rename(to: "   "))
        XCTAssertTrue(pet.rename(to: "Kupo"))
        XCTAssertEqual(pet.name, "Kupo")
        XCTAssertTrue(pet.rename(to: "UnNombreDemasiadoLargoParaElJuego"))
        XCTAssertEqual(pet.name.count, 16)
    }
}
