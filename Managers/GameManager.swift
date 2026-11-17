import Foundation

final class GameManager {
    private enum Key {
        static let pet = "finalgochi.pet"
        static let gil = "finalgochi.gil"
        static let accessories = "finalgochi.items"
        static let equippedAccessory = "finalgochi.equippedAccessory"
        static let inventory = "finalgochi.inventory.v1"
    }

    private let defaults: UserDefaults
    private var timer: Timer?
    private(set) var pet: PetModel?
    private(set) var gil: Int
    private(set) var ownedItems: Set<StoreItem>
    private(set) var equippedAccessory: StoreItem?
    private(set) var inventory: [ConsumableItem: Int]

    var onChange: (() -> Void)?
    var onGameOver: (() -> Void)?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        gil = defaults.object(forKey: Key.gil) as? Int ?? 50

        let savedAccessories = Self.decode([StoreItem].self, from: defaults.data(forKey: Key.accessories)) ?? []
        ownedItems = Set(savedAccessories)
        if let rawValue = defaults.string(forKey: Key.equippedAccessory),
           let accessory = StoreItem(rawValue: rawValue),
           ownedItems.contains(accessory) {
            equippedAccessory = accessory
        } else {
            equippedAccessory = nil
        }

        if let savedInventory = Self.decode([ConsumableItem: Int].self, from: defaults.data(forKey: Key.inventory)) {
            inventory = savedInventory.filter { $0.value > 0 }
        } else {
            // Initial stock also gives existing prototype saves a one-time inventory migration.
            inventory = [.ration: 2, .potion: 1]
        }

        if let savedPet = Self.decode(PetModel.self, from: defaults.data(forKey: Key.pet)) {
            pet = savedPet
            updateElapsedTime()
            startTimer()
        }

        if defaults.data(forKey: Key.inventory) == nil {
            persist()
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
        timer?.invalidate()
        timer = nil
        pet = nil
        gil = 50
        ownedItems = []
        equippedAccessory = nil
        inventory = [.ration: 2, .potion: 1]

        defaults.removeObject(forKey: Key.pet)
        persist()
        onChange?()
    }

    func feed() {
        _ = use(.ration)
    }

    func sleep() {
        guard var current = pet else { return }
        let now = Date()
        current.update(for: now.timeIntervalSince(current.lastUpdated), now: now)
        guard !current.isSleeping, current.energy < 100 else {
            commit(current)
            return
        }
        current.startSleeping(at: now)
        commit(current)
    }

    func wake() {
        guard var current = pet, current.isSleeping else { return }
        let now = Date()
        current.update(for: now.timeIntervalSince(current.lastUpdated), now: now)
        if current.isSleeping { current.wake(at: now) }
        commit(current)
    }

    func playMiniGame(success: Bool) {
        guard var current = pet else { return }
        let wasGameOver = current.isGameOver
        current.play()
        current.addExperience(success ? 20 : 5)
        pet = current
        gil += success ? 25 : 5
        persist()
        onChange?()
        notifyGameOverIfNeeded(wasGameOver: wasGameOver, current: current)
    }

    func use(_ item: ConsumableItem) -> Bool {
        guard let quantity = inventory[item], quantity > 0,
              var current = pet else { return false }

        let wasGameOver = current.isGameOver
        switch item {
        case .ration:
            current.feed(amount: 25)
        case .gysahlGreens:
            current.feed(amount: 45)
            current.increaseHappiness(by: 5)
        case .potion:
            current.restoreEnergy(by: 30)
        case .ether:
            current.increaseHappiness(by: 30)
        }

        inventory[item] = quantity - 1
        if inventory[item] == 0 { inventory.removeValue(forKey: item) }
        pet = current
        persist()
        onChange?()
        notifyGameOverIfNeeded(wasGameOver: wasGameOver, current: current)
        return true
    }

    func buy(_ item: StoreItem) -> Bool {
        guard gil >= item.price, !ownedItems.contains(item) else { return false }
        gil -= item.price
        ownedItems.insert(item)
        persist()
        onChange?()
        return true
    }

    func buy(_ item: ConsumableItem, quantity: Int = 1) -> Bool {
        guard quantity > 0 else { return false }
        let totalPrice = item.price * quantity
        guard gil >= totalPrice else { return false }
        gil -= totalPrice
        inventory[item, default: 0] += quantity
        persist()
        onChange?()
        return true
    }

    func equip(_ item: StoreItem?) -> Bool {
        guard let item else {
            equippedAccessory = nil
            persist()
            onChange?()
            return true
        }
        guard ownedItems.contains(item) else { return false }
        equippedAccessory = item
        persist()
        onChange?()
        return true
    }

    func addGil(_ amount: Int) {
        gil = max(0, gil + amount)
        persist()
        onChange?()
    }

    func updateElapsedTime(now: Date = Date()) {
        guard var current = pet else { return }
        let wasGameOver = current.isGameOver
        current.update(for: now.timeIntervalSince(current.lastUpdated), now: now)
        pet = current
        persist()
        onChange?()
        notifyGameOverIfNeeded(wasGameOver: wasGameOver, current: current)
    }

    private func commit(_ current: PetModel) {
        let wasGameOver = pet?.isGameOver ?? false
        pet = current
        persist()
        onChange?()
        notifyGameOverIfNeeded(wasGameOver: wasGameOver, current: current)
    }

    private func notifyGameOverIfNeeded(wasGameOver: Bool, current: PetModel) {
        guard !wasGameOver, current.isGameOver else { return }
        timer?.invalidate()
        timer = nil
        onGameOver?()
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.updateElapsedTime()
        }
    }

    private func persist() {
        if let pet, let data = try? JSONEncoder().encode(pet) {
            defaults.set(data, forKey: Key.pet)
        }
        defaults.set(gil, forKey: Key.gil)
        if let data = try? JSONEncoder().encode(ownedItems.sorted { $0.rawValue < $1.rawValue }) {
            defaults.set(data, forKey: Key.accessories)
        }
        if let equippedAccessory {
            defaults.set(equippedAccessory.rawValue, forKey: Key.equippedAccessory)
        } else {
            defaults.removeObject(forKey: Key.equippedAccessory)
        }
        if let data = try? JSONEncoder().encode(inventory) {
            defaults.set(data, forKey: Key.inventory)
        }
    }

    private static func decode<Value: Decodable>(_ type: Value.Type, from data: Data?) -> Value? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
