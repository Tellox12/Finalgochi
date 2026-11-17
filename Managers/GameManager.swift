import Foundation

final class GameManager {
    private enum Key {
        static let pet = "finalgochi.pet"
        static let gil = "finalgochi.gil"
        static let items = "finalgochi.items"
    }

    private let defaults: UserDefaults
    private var timer: Timer?
    private(set) var pet: PetModel?
    private(set) var gil: Int
    private(set) var ownedItems: Set<StoreItem>
    var onChange: (() -> Void)?
    var onGameOver: (() -> Void)?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        gil = defaults.object(forKey: Key.gil) as? Int ?? 50
        let savedItems = (try? JSONDecoder().decode([StoreItem].self, from: defaults.data(forKey: Key.items) ?? Data())) ?? []
        ownedItems = Set(savedItems)
        if let data = defaults.data(forKey: Key.pet), let savedPet = try? JSONDecoder().decode(PetModel.self, from: data) {
            pet = savedPet
            updateElapsedTime()
            startTimer()
        }
    }

    deinit { timer?.invalidate() }

    func createPet(_ kind: PetKind) {
        pet = PetModel(kind: kind)
        persist()
        startTimer()
        onChange?()
    }

    func reset() {
        timer?.invalidate(); timer = nil
        pet = nil; gil = 50; ownedItems = []
        defaults.removeObject(forKey: Key.pet)
        defaults.set(gil, forKey: Key.gil)
        defaults.removeObject(forKey: Key.items)
        onChange?()
    }

    func feed() { changePet { $0.feed() } }
    func sleep() { changePet { $0.sleep() } }

    func playMiniGame(success: Bool) {
        changePet { $0.play(); $0.addExperience(success ? 20 : 5) }
        gil += success ? 25 : 5
        persist(); onChange?()
    }

    func buy(_ item: StoreItem) -> Bool {
        guard gil >= item.price, !ownedItems.contains(item) else { return false }
        gil -= item.price
        ownedItems.insert(item)
        persist(); onChange?()
        return true
    }

    func updateElapsedTime(now: Date = Date()) {
        guard var current = pet else { return }
        current.update(for: now.timeIntervalSince(current.lastUpdated), now: now)
        pet = current
        persist(); onChange?()
        if current.isGameOver { timer?.invalidate(); timer = nil; onGameOver?() }
    }

    private func changePet(_ action: (inout PetModel) -> Void) {
        guard var current = pet else { return }
        action(&current); pet = current
        persist(); onChange?()
        if current.isGameOver { onGameOver?() }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.updateElapsedTime()
        }
    }

    private func persist() {
        if let pet, let data = try? JSONEncoder().encode(pet) { defaults.set(data, forKey: Key.pet) }
        defaults.set(gil, forKey: Key.gil)
        if let data = try? JSONEncoder().encode(ownedItems.sorted { $0.rawValue < $1.rawValue }) { defaults.set(data, forKey: Key.items) }
    }
}
