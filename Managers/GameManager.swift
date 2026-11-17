import Foundation

final class GameManager {
    private enum Key {
        static let pet = "finalgochi.pet"
        static let gil = "finalgochi.gil"
        static let accessories = "finalgochi.items"
        static let equippedAccessory = "finalgochi.equippedAccessory"
        static let equipment = "finalgochi.equipment.v2"
        static let inventory = "finalgochi.inventory.v1"
        static let quests = "finalgochi.dailyQuests.v1"
        static let materia = "finalgochi.materia.v1"
        static let equippedMateria = "finalgochi.equippedMateria.v1"
        static let magicPoints = "finalgochi.magicPoints.v1"
        static let magicUpdatedAt = "finalgochi.magicUpdatedAt.v1"
        static let activeExpedition = "finalgochi.activeExpedition.v1"
    }

    private let defaults: UserDefaults
    private var timer: Timer?
    private(set) var pet: PetModel?
    private(set) var gil: Int
    private(set) var ownedItems: Set<StoreItem>
    private(set) var equippedItems: [EquipmentSlot: StoreItem]
    private(set) var inventory: [ConsumableItem: Int]
    private(set) var dailyQuests: DailyQuestBoard
    private(set) var activeExpedition: ActiveExpedition?
    private(set) var ownedMateria: Set<Materia>
    private(set) var equippedMateria: [Materia]
    private(set) var magicPoints: Int
    private var lastMagicUpdatedAt: Date

    static let maximumMagicPoints = 100
    static let maximumEquippedMateria = 2

    var equippedAccessory: StoreItem? {
        EquipmentSlot.allCases.compactMap { equippedItems[$0] }.first
    }

    var activeEquipment: [StoreItem] {
        EquipmentSlot.allCases.compactMap { equippedItems[$0] }
    }

    var equipmentSummary: String {
        let items = activeEquipment
        return items.isEmpty ? "Sin equipo" : items.map { "\($0.emoji) \($0.name)" }.joined(separator: "  ·  ")
    }

    var onChange: (() -> Void)?
    var onGameOver: (() -> Void)?
    var onQuestReward: ((Int) -> Void)?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        gil = defaults.object(forKey: Key.gil) as? Int ?? 50
        dailyQuests = Self.decode(DailyQuestBoard.self, from: defaults.data(forKey: Key.quests)) ?? DailyQuestBoard()
        activeExpedition = Self.decode(ActiveExpedition.self, from: defaults.data(forKey: Key.activeExpedition))

        let savedAccessories = Self.decode([StoreItem].self, from: defaults.data(forKey: Key.accessories)) ?? []
        let loadedOwnedItems = Set(savedAccessories)
        ownedItems = loadedOwnedItems
        if let savedEquipment = Self.decode([EquipmentSlot: StoreItem].self, from: defaults.data(forKey: Key.equipment)) {
            equippedItems = savedEquipment.reduce(into: [EquipmentSlot: StoreItem]()) { result, entry in
                guard entry.key == entry.value.slot, loadedOwnedItems.contains(entry.value) else { return }
                result[entry.key] = entry.value
            }
        } else {
            equippedItems = [:]
            if let rawValue = defaults.string(forKey: Key.equippedAccessory),
               let oldItem = StoreItem(rawValue: rawValue),
               loadedOwnedItems.contains(oldItem) {
                equippedItems[oldItem.slot] = oldItem
            }
        }

        let loadedOwnedMateria = Set(Self.decode([Materia].self, from: defaults.data(forKey: Key.materia)) ?? [.cure])
        ownedMateria = loadedOwnedMateria
        let savedEquippedMateria = Self.decode([Materia].self, from: defaults.data(forKey: Key.equippedMateria)) ?? [.cure]
        equippedMateria = Array(savedEquippedMateria.filter { loadedOwnedMateria.contains($0) }.prefix(Self.maximumEquippedMateria))
        magicPoints = min(Self.maximumMagicPoints, max(0, defaults.object(forKey: Key.magicPoints) as? Int ?? Self.maximumMagicPoints))
        lastMagicUpdatedAt = defaults.object(forKey: Key.magicUpdatedAt) as? Date ?? Date()

        if let savedInventory = Self.decode([ConsumableItem: Int].self, from: defaults.data(forKey: Key.inventory)) {
            inventory = savedInventory.filter { $0.value > 0 }
        } else {
            // Initial stock also gives existing prototype saves a one-time inventory migration.
            inventory = [.ration: 2, .potion: 1]
        }

        if let savedPet = Self.decode(PetModel.self, from: defaults.data(forKey: Key.pet)) {
            pet = savedPet
            updateElapsedTime()
            if pet?.isGameOver != true { startTimer() }
        }

        if defaults.data(forKey: Key.inventory) == nil {
            persist()
        }
        refreshDailyQuestsIfNeeded()
    }

    deinit { timer?.invalidate() }

    func createPet(_ kind: PetKind) {
        pet = PetModel(kind: kind)
        persist()
        startTimer()
        onChange?()
    }

    @discardableResult
    func renamePet(to name: String) -> Bool {
        guard var current = pet, current.rename(to: name) else { return false }
        pet = current
        persist()
        onChange?()
        return true
    }

    func reset() {
        timer?.invalidate()
        timer = nil
        pet = nil
        gil = 50
        ownedItems = []
        equippedItems = [:]
        inventory = [.ration: 2, .potion: 1]
        dailyQuests = DailyQuestBoard()
        activeExpedition = nil
        ownedMateria = [.cure]
        equippedMateria = [.cure]
        magicPoints = Self.maximumMagicPoints
        lastMagicUpdatedAt = Date()

        defaults.removeObject(forKey: Key.pet)
        persist()
        onChange?()
    }

    @discardableResult
    func startExpedition(_ route: ExpeditionRoute, at date: Date = Date()) -> Bool {
        updateElapsedTime(now: date)
        guard canStartExpedition(route), var current = pet else { return false }

        current.spendEnergy(route.energyCost)
        current.lastUpdated = date
        pet = current
        activeExpedition = ActiveExpedition(route: route, startedAt: date)
        persist()
        onChange?()
        return true
    }

    func canStartExpedition(_ route: ExpeditionRoute) -> Bool {
        guard activeExpedition == nil, let pet,
              !pet.isSleeping, !pet.isGameOver,
              pet.level >= route.minimumLevel,
              pet.energy >= route.minimumEnergy,
              pet.hunger >= 20, pet.happiness >= 20 else { return false }
        return true
    }

    @discardableResult
    func claimExpedition(at date: Date = Date()) -> Bool {
        guard let expedition = activeExpedition, expedition.isReady(at: date) else { return false }
        updateElapsedTime(now: date)
        guard var current = pet, !current.isGameOver else { return false }

        let route = expedition.route
        current.addExperience(Int((Double(route.experienceReward) * careModifiers.experienceGainMultiplier).rounded()))
        pet = current
        gil += route.gilReward
        inventory[route.loot, default: 0] += 1
        activeExpedition = nil
        recordQuest(.expedition)
        persist()
        onChange?()
        return true
    }

    func feed() {
        _ = use(.ration)
    }

    func sleep() {
        guard var current = pet else { return }
        let now = Date()
        current.update(for: now.timeIntervalSince(current.lastUpdated), now: now, modifiers: careModifiers)
        guard !current.isSleeping, current.energy < 100 else {
            commit(current)
            return
        }
        current.startSleeping(at: now)
        recordQuest(.sleep)
        commit(current)
    }

    func wake() {
        guard var current = pet, current.isSleeping else { return }
        let now = Date()
        current.update(for: now.timeIntervalSince(current.lastUpdated), now: now, modifiers: careModifiers)
        if current.isSleeping { current.wake(at: now) }
        commit(current)
    }

    func playMiniGame(success: Bool) {
        guard var current = pet else { return }
        let wasGameOver = current.isGameOver
        current.play()
        let baseExperience = success ? 20 : 5
        current.addExperience(Int((Double(baseExperience) * careModifiers.experienceGainMultiplier).rounded()))
        pet = current
        gil += success ? 25 : 5
        recordQuest(.play)
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
            recordQuest(.feed)
        case .gysahlGreens:
            current.feed(amount: 45)
            current.increaseHappiness(by: 5)
            recordQuest(.feed)
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

    func buy(_ materia: Materia) -> Bool {
        guard !ownedMateria.contains(materia), gil >= materia.price else { return false }
        gil -= materia.price
        ownedMateria.insert(materia)
        persist()
        onChange?()
        return true
    }

    func toggleMateria(_ materia: Materia) -> Bool {
        updateElapsedTime()
        guard ownedMateria.contains(materia) else { return false }
        if let index = equippedMateria.firstIndex(of: materia) {
            equippedMateria.remove(at: index)
        } else {
            guard equippedMateria.count < Self.maximumEquippedMateria else { return false }
            equippedMateria.append(materia)
        }
        persist()
        onChange?()
        return true
    }

    @discardableResult
    func castMateria(_ materia: Materia) -> Bool {
        updateElapsedTime()
        guard canCastMateria(materia), var current = pet else { return false }

        let wasGameOver = current.isGameOver
        switch materia {
        case .cure:
            current.restoreEnergy(by: 25)
            current.increaseHappiness(by: 8)
        case .fire:
            current.increaseHappiness(by: 28)
            current.addExperience(15)
            current.spendEnergy(5)
        case .haste:
            current.restoreEnergy(by: 38)
        case .regen:
            current.feed(amount: 22)
            current.increaseHappiness(by: 8)
        }
        magicPoints -= materia.magicCost
        pet = current
        persist()
        onChange?()
        notifyGameOverIfNeeded(wasGameOver: wasGameOver, current: current)
        return true
    }

    func canCastMateria(_ materia: Materia) -> Bool {
        guard equippedMateria.contains(materia), magicPoints >= materia.magicCost,
              let pet, !pet.isSleeping, !pet.isGameOver else { return false }
        switch materia {
        case .cure: return pet.energy < 100 || pet.happiness < 100
        case .fire: return true
        case .haste: return pet.energy < 100
        case .regen: return pet.hunger < 100 || pet.happiness < 100
        }
    }

    func equip(_ item: StoreItem) -> Bool {
        updateElapsedTime()
        guard ownedItems.contains(item) else { return false }
        equippedItems[item.slot] = item
        persist()
        onChange?()
        return true
    }

    func unequip(_ slot: EquipmentSlot) {
        updateElapsedTime()
        equippedItems.removeValue(forKey: slot)
        persist()
        onChange?()
    }

    func equip(_ item: StoreItem?) -> Bool {
        guard let item else {
            unequip(.charm)
            return true
        }
        return equip(item)
    }

    func addGil(_ amount: Int) {
        gil = max(0, gil + amount)
        persist()
        onChange?()
    }

    func updateElapsedTime(now: Date = Date()) {
        refreshDailyQuestsIfNeeded()
        regenerateMagic(at: now)
        guard var current = pet else { return }
        let wasGameOver = current.isGameOver
        current.update(for: now.timeIntervalSince(current.lastUpdated), now: now, modifiers: careModifiers)
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
        if let data = try? JSONEncoder().encode(equippedItems) {
            defaults.set(data, forKey: Key.equipment)
        }
        if let equippedAccessory {
            defaults.set(equippedAccessory.rawValue, forKey: Key.equippedAccessory)
        } else {
            defaults.removeObject(forKey: Key.equippedAccessory)
        }
        if let data = try? JSONEncoder().encode(inventory) {
            defaults.set(data, forKey: Key.inventory)
        }
        if let data = try? JSONEncoder().encode(dailyQuests) {
            defaults.set(data, forKey: Key.quests)
        }
        if let activeExpedition, let data = try? JSONEncoder().encode(activeExpedition) {
            defaults.set(data, forKey: Key.activeExpedition)
        } else {
            defaults.removeObject(forKey: Key.activeExpedition)
        }
        if let data = try? JSONEncoder().encode(ownedMateria.sorted { $0.rawValue < $1.rawValue }) {
            defaults.set(data, forKey: Key.materia)
        }
        if let data = try? JSONEncoder().encode(equippedMateria) {
            defaults.set(data, forKey: Key.equippedMateria)
        }
        defaults.set(magicPoints, forKey: Key.magicPoints)
        defaults.set(lastMagicUpdatedAt, forKey: Key.magicUpdatedAt)
    }

    private var careModifiers: PetCareModifiers {
        let equipment = equippedItems.values.reduce(PetCareModifiers()) { $0.combined(with: $1.careModifiers) }
        return equippedMateria.reduce(equipment) { $0.combined(with: $1.passiveModifiers) }
    }

    private func regenerateMagic(at date: Date) {
        guard magicPoints < Self.maximumMagicPoints else {
            lastMagicUpdatedAt = date
            return
        }
        let elapsed = max(0, date.timeIntervalSince(lastMagicUpdatedAt))
        let regenerated = Int(elapsed / 180)
        guard regenerated > 0 else { return }
        magicPoints = min(Self.maximumMagicPoints, magicPoints + regenerated)
        lastMagicUpdatedAt = lastMagicUpdatedAt.addingTimeInterval(TimeInterval(regenerated * 180))
    }

    private func recordQuest(_ kind: DailyQuestKind) {
        let reward = dailyQuests.record(kind)
        if reward > 0 {
            gil += reward
            onQuestReward?(reward)
        }
        persist()
    }

    private func refreshDailyQuestsIfNeeded() {
        let previousBoard = dailyQuests
        dailyQuests.refreshIfNeeded()
        if dailyQuests != previousBoard { persist() }
    }

    private static func decode<Value: Decodable>(_ type: Value.Type, from data: Data?) -> Value? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
