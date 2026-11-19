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
        static let progression = "finalgochi.progression.v1"
        static let dailyStreak = "finalgochi.dailyStreak.v1"
        static let schemaVersion = "finalgochi.saveSchemaVersion"

        static let all = [
            pet, gil, accessories, equippedAccessory, equipment, inventory, quests, materia,
            equippedMateria, magicPoints, magicUpdatedAt, activeExpedition, progression, dailyStreak
        ]
    }

    static let currentSchemaVersion = 1
    static let maximumOfflineInterval: TimeInterval = 12 * 60 * 60

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
    private(set) var progression: ProgressionState
    private(set) var dailyStreak: DailyStreak
    private var lastMagicUpdatedAt: Date
    private var lastPersistedAt = Date.distantPast
    private var observers: [UUID: () -> Void] = [:]

    static let maximumMagicPoints = 100
    static let maximumEquippedMateria = 2
    static let maximumGil = 999_999
    static let maximumSaveFileSize = 2_000_000

    var equippedAccessory: StoreItem? {
        EquipmentSlot.allCases.compactMap { equippedItems[$0] }.first
    }

    var activeEquipment: [StoreItem] {
        EquipmentSlot.allCases.compactMap { equippedItems[$0] }
    }

    var equipmentSummary: String {
        let items = activeEquipment
        return items.isEmpty ? "Sin equipo" : items.map(\.name).joined(separator: "  ·  ")
    }

    var canPlayMiniGame: Bool {
        guard let pet else { return false }
        return !pet.isSleeping && !pet.isGameOver && pet.energy >= 8
    }

    var onGameOver: (() -> Void)?

    @discardableResult
    func addObserver(_ observer: @escaping () -> Void) -> UUID {
        let id = UUID()
        observers[id] = observer
        return id
    }

    func removeObserver(_ id: UUID?) {
        guard let id else { return }
        observers.removeValue(forKey: id)
    }

    private func notifyObservers() {
        for observer in Array(observers.values) { observer() }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let storedSchema = defaults.object(forKey: Key.schemaVersion) as? Int ?? 0
        if storedSchema == 0 {
            defaults.set(Self.currentSchemaVersion, forKey: Key.schemaVersion)
        }
        gil = min(Self.maximumGil, max(0, defaults.object(forKey: Key.gil) as? Int ?? 50))
        dailyQuests = Self.decode(DailyQuestBoard.self, from: defaults.data(forKey: Key.quests)) ?? DailyQuestBoard()
        activeExpedition = Self.decode(ActiveExpedition.self, from: defaults.data(forKey: Key.activeExpedition))
        progression = Self.normalizedProgression(Self.decode(ProgressionState.self, from: defaults.data(forKey: Key.progression)) ?? ProgressionState())
        dailyStreak = Self.decode(DailyStreak.self, from: defaults.data(forKey: Key.dailyStreak)) ?? DailyStreak()

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
            inventory = savedInventory.filter { $0.value > 0 }.mapValues { min(999, $0) }
        } else {
            // Initial stock also gives existing prototype saves a one-time inventory migration.
            inventory = [.ration: 2, .potion: 1]
        }

        if let savedPet = Self.decode(PetModel.self, from: defaults.data(forKey: Key.pet)) {
            pet = savedPet
            progression.discoveredPets.insert(savedPet.kind)
            _ = claimDailyLogin()
            updateElapsedTime()
            if pet?.isGameOver != true { startTimer() }
        }

        if defaults.data(forKey: Key.inventory) == nil {
            persist()
        }
        refreshDailyQuestsIfNeeded()
        lastPersistedAt = Date()
    }

    deinit { timer?.invalidate() }

    func createPet(_ kind: PetKind) {
        pet = PetModel(kind: kind)
        progression.discoveredPets.insert(kind)
        _ = claimDailyLogin()
        unlock(.firstFriend)
        persist()
        startTimer()
        notifyObservers()
    }

    @discardableResult
    func renamePet(to name: String) -> Bool {
        guard var current = pet, current.rename(to: name) else { return false }
        pet = current
        persist()
        notifyObservers()
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
        progression = ProgressionState()
        ownedMateria = [.cure]
        equippedMateria = [.cure]
        magicPoints = Self.maximumMagicPoints
        lastMagicUpdatedAt = Date()
        dailyStreak = DailyStreak()

        for key in Key.all { defaults.removeObject(forKey: key) }
        persist()
        notifyObservers()
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
        notifyObservers()
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
        progression.discoveredPets.insert(route.discoveredPet)
        current.addExperience(Int((Double(route.experienceReward) * careModifiers.experienceGainMultiplier).rounded()))
        pet = current
        progression.completedExpeditions += 1
        awardGil(route.gilReward)
        inventory[route.loot] = min(999, inventory[route.loot, default: 0] + 1)
        activeExpedition = nil
        recordQuest(.expedition)
        persist()
        notifyObservers()
        return true
    }

    func sleep() {
        guard var current = pet, !current.isGameOver else { return }
        let now = Date()
        current.update(for: min(Self.maximumOfflineInterval, now.timeIntervalSince(current.lastUpdated)), now: now, modifiers: careModifiers)
        guard !current.isGameOver, !current.isSleeping, current.energy < 100 else {
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
        current.update(for: min(Self.maximumOfflineInterval, now.timeIntervalSince(current.lastUpdated)), now: now, modifiers: careModifiers)
        if current.isSleeping { current.wake(at: now) }
        commit(current)
    }

    @discardableResult
    func playMiniGame(success: Bool) -> Bool {
        updateElapsedTime()
        guard canPlayMiniGame, var current = pet else { return false }
        current.play()
        let baseExperience = success ? 20 : 5
        current.addExperience(Int((Double(baseExperience) * careModifiers.experienceGainMultiplier).rounded()))
        pet = current
        if success { progression.wonMiniGames += 1 }
        awardGil(success ? 25 : 5)
        recordQuest(.play)
        persist()
        notifyObservers()
        return true
    }

    /// Anything above this counts as full. A freshly decayed stat sits a hair below 100, and
    /// without the margin the game would let the player waste an item to recover fractions of a point.
    private static let fullStatMargin = 0.5
    private static var fullStatThreshold: Double { 100 - fullStatMargin }

    /// Whether using the consumable right now would have any effect. Prevents wasting items on a full pet.
    func canUse(_ item: ConsumableItem) -> Bool {
        guard inventory[item, default: 0] > 0, let pet, !pet.isSleeping, !pet.isGameOver else { return false }
        let threshold = Self.fullStatThreshold
        switch item {
        case .ration, .gysahlGreens: return pet.hunger < threshold
        case .potion: return pet.energy < threshold
        case .ether: return pet.happiness < threshold
        }
    }

    func use(_ item: ConsumableItem) -> Bool {
        updateElapsedTime()
        guard canUse(item), let quantity = inventory[item], quantity > 0,
              var current = pet else { return false }

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
        notifyObservers()
        return true
    }

    func buy(_ item: StoreItem) -> Bool {
        guard gil >= item.price, !ownedItems.contains(item) else { return false }
        gil -= item.price
        ownedItems.insert(item)
        unlock(.fashionista)
        persist()
        notifyObservers()
        return true
    }

    func buy(_ item: ConsumableItem, quantity: Int = 1) -> Bool {
        guard quantity > 0, item.price > 0 else { return false }
        let availableSpace = max(0, 999 - inventory[item, default: 0])
        guard availableSpace > 0 else { return false }
        let affordable = gil / item.price
        let bought = min(quantity, min(availableSpace, affordable))
        guard bought > 0 else { return false }
        gil -= item.price * bought
        inventory[item] = inventory[item, default: 0] + bought
        persist()
        notifyObservers()
        return true
    }

    func buy(_ materia: Materia) -> Bool {
        guard !ownedMateria.contains(materia), gil >= materia.price else { return false }
        gil -= materia.price
        ownedMateria.insert(materia)
        if ownedMateria.count >= 3 { unlock(.materiaCollector) }
        persist()
        notifyObservers()
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
        notifyObservers()
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
        notifyObservers()
        notifyGameOverIfNeeded(wasGameOver: wasGameOver, current: current)
        return true
    }

    func canCastMateria(_ materia: Materia) -> Bool {
        guard equippedMateria.contains(materia), magicPoints >= materia.magicCost,
              let pet, !pet.isSleeping, !pet.isGameOver else { return false }
        let threshold = Self.fullStatThreshold
        switch materia {
        case .cure: return pet.energy < threshold || pet.happiness < threshold
        case .fire: return true
        case .haste: return pet.energy < threshold
        case .regen: return pet.hunger < threshold || pet.happiness < threshold
        }
    }

    func equip(_ item: StoreItem) -> Bool {
        updateElapsedTime()
        guard ownedItems.contains(item) else { return false }
        equippedItems[item.slot] = item
        persist()
        notifyObservers()
        return true
    }

    func unequip(_ slot: EquipmentSlot) {
        updateElapsedTime()
        equippedItems.removeValue(forKey: slot)
        persist()
        notifyObservers()
    }

    func addGil(_ amount: Int) {
        awardGil(amount)
        persist()
        notifyObservers()
    }

    @discardableResult
    func claimDailyLogin(at date: Date = Date()) -> Int? {
        guard pet != nil else { return nil }
        var updatedStreak = dailyStreak
        guard let reward = updatedStreak.claim(at: date) else { return nil }
        dailyStreak = updatedStreak
        awardGil(reward)
        persist()
        notifyObservers()
        return reward
    }

    @discardableResult
    func buy(_ decoration: HabitatDecoration) -> Bool {
        guard !progression.ownedDecorations.contains(decoration), gil >= decoration.price else { return false }
        gil -= decoration.price
        progression.ownedDecorations.insert(decoration)
        persist()
        notifyObservers()
        return true
    }

    @discardableResult
    func equip(_ decoration: HabitatDecoration?) -> Bool {
        if let decoration, !progression.ownedDecorations.contains(decoration) { return false }
        progression.equippedDecoration = decoration
        persist()
        notifyObservers()
        return true
    }

    func exportSave() -> Data? {
        guard pet != nil else { return nil }
        var values: [String: Data] = [:]
        for key in Key.all + [Key.schemaVersion] {
            guard let value = defaults.object(forKey: key),
                  let data = try? PropertyListSerialization.data(fromPropertyList: value, format: .binary, options: 0) else { continue }
            values[key] = data
        }
        return try? JSONEncoder().encode(GameSaveArchive(values: values))
    }

    @discardableResult
    func importSave(_ data: Data, now: Date = Date()) -> Bool {
        guard data.count <= Self.maximumSaveFileSize else { return false }
        guard let archive = try? JSONDecoder().decode(GameSaveArchive.self, from: data), archive.formatVersion == 2 else { return false }
        let allowedKeys = Set(Key.all + [Key.schemaVersion])
        guard archive.values[Key.pet] != nil,
              !archive.values.isEmpty,
              Set(archive.values.keys).isSubset(of: allowedKeys) else { return false }

        var decodedValues: [String: Any] = [:]
        for (key, encodedValue) in archive.values {
            guard let value = try? PropertyListSerialization.propertyList(from: encodedValue, options: [], format: nil) else { return false }
            decodedValues[key] = value
        }

        guard let petData = decodedValues[Key.pet] as? Data,
              var importedPet = Self.decode(PetModel.self, from: petData),
              let savedGil = decodedValues[Key.gil] as? Int else { return false }

        let importedSchema = decodedValues[Key.schemaVersion] as? Int ?? 0
        guard importedSchema <= Self.currentSchemaVersion else { return false }

        // Rebase the imported timestamps so an old backup does not age or kill the pet on import.
        importedPet.lastUpdated = now
        if importedPet.isSleeping {
            importedPet.sleepStartedAt = now
        } else {
            importedPet.sleepStartedAt = nil
        }
        guard let rebasedPetData = try? JSONEncoder().encode(importedPet) else { return false }

        for key in allowedKeys where !decodedValues.keys.contains(key) {
            defaults.removeObject(forKey: key)
        }
        for (key, value) in decodedValues { defaults.set(value, forKey: key) }
        defaults.set(rebasedPetData, forKey: Key.pet)
        defaults.set(Self.currentSchemaVersion, forKey: Key.schemaVersion)

        timer?.invalidate()
        timer = nil
        pet = importedPet
        gil = min(Self.maximumGil, max(0, savedGil))
        ownedItems = Set(Self.decode([StoreItem].self, from: defaults.data(forKey: Key.accessories)) ?? [])
        let importedEquipment = Self.decode([EquipmentSlot: StoreItem].self, from: defaults.data(forKey: Key.equipment)) ?? [:]
        equippedItems = importedEquipment.reduce(into: [EquipmentSlot: StoreItem]()) { result, entry in
            guard entry.key == entry.value.slot, ownedItems.contains(entry.value) else { return }
            result[entry.key] = entry.value
        }
        inventory = (Self.decode([ConsumableItem: Int].self, from: defaults.data(forKey: Key.inventory)) ?? [:])
            .filter { $0.value > 0 }
            .mapValues { min(999, $0) }
        dailyQuests = Self.decode(DailyQuestBoard.self, from: defaults.data(forKey: Key.quests)) ?? DailyQuestBoard()
        ownedMateria = Set(Self.decode([Materia].self, from: defaults.data(forKey: Key.materia)) ?? [.cure])
        equippedMateria = Array((Self.decode([Materia].self, from: defaults.data(forKey: Key.equippedMateria)) ?? [.cure]).filter { ownedMateria.contains($0) }.prefix(Self.maximumEquippedMateria))
        magicPoints = min(Self.maximumMagicPoints, max(0, defaults.object(forKey: Key.magicPoints) as? Int ?? Self.maximumMagicPoints))
        lastMagicUpdatedAt = now
        progression = Self.normalizedProgression(Self.decode(ProgressionState.self, from: defaults.data(forKey: Key.progression)) ?? ProgressionState())
        dailyStreak = Self.decode(DailyStreak.self, from: defaults.data(forKey: Key.dailyStreak)) ?? DailyStreak()
        activeExpedition = Self.decode(ActiveExpedition.self, from: defaults.data(forKey: Key.activeExpedition))
        if var expedition = activeExpedition, !expedition.isReady(at: now) {
            let remaining = expedition.remainingTime(at: now)
            expedition = ActiveExpedition(route: expedition.route, startedAt: now.addingTimeInterval(-(expedition.route.duration - remaining)))
            activeExpedition = expedition
        }

        lastPersistedAt = .distantPast
        persist()
        if pet?.isGameOver != true { startTimer() }
        notifyObservers()
        return true
    }

    /// Forces a synchronous persistence pass. Call this when the app moves to the background.
    func saveNow() {
        persist()
    }

    func updateElapsedTime(now: Date = Date()) {
        refreshDailyQuestsIfNeeded()
        regenerateMagic(at: now)
        guard var current = pet else { return }
        let wasGameOver = current.isGameOver
        let elapsed = min(Self.maximumOfflineInterval, max(0, now.timeIntervalSince(current.lastUpdated)))
        current.update(for: elapsed, now: now, modifiers: careModifiers)
        pet = current
        persistIfNeeded()
        notifyObservers()
        notifyGameOverIfNeeded(wasGameOver: wasGameOver, current: current)
    }

    private func commit(_ current: PetModel) {
        let wasGameOver = pet?.isGameOver ?? false
        pet = current
        persist()
        notifyObservers()
        notifyGameOverIfNeeded(wasGameOver: wasGameOver, current: current)
    }

    private func notifyGameOverIfNeeded(wasGameOver: Bool, current: PetModel) {
        guard !wasGameOver, current.isGameOver else { return }
        timer?.invalidate()
        timer = nil
        persist()
        onGameOver?()
    }

    private func unlock(_ achievement: GameAchievement) {
        guard progression.unlockedAchievements.insert(achievement).inserted else { return }
        awardGil(achievement.reward)
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.updateElapsedTime()
        }
    }

    private func persist() {
        evaluateAchievements()
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
        if let data = try? JSONEncoder().encode(progression) { defaults.set(data, forKey: Key.progression) }
        if let data = try? JSONEncoder().encode(dailyStreak) { defaults.set(data, forKey: Key.dailyStreak) }
        defaults.set(Self.currentSchemaVersion, forKey: Key.schemaVersion)
        lastPersistedAt = Date()
    }

    private func persistIfNeeded() {
        guard Date().timeIntervalSince(lastPersistedAt) >= 20 else { return }
        persist()
    }

    private func evaluateAchievements() {
        if !progression.discoveredPets.isEmpty { unlock(.firstFriend) }
        if !ownedItems.isEmpty { unlock(.fashionista) }
        if ownedMateria.count >= 3 { unlock(.materiaCollector) }
        if (pet?.level ?? 0) >= 5 { unlock(.levelFive) }
        if progression.completedExpeditions >= 5 { unlock(.expeditionVeteran) }
        if progression.wonMiniGames >= 10 { unlock(.reflexMaster) }
        if progression.discoveredPets.count >= PetKind.allCases.count { unlock(.bestiary) }
    }

    private func awardGil(_ amount: Int) {
        let (sum, overflow) = gil.addingReportingOverflow(amount)
        if overflow {
            gil = amount >= 0 ? Self.maximumGil : 0
        } else {
            gil = min(Self.maximumGil, max(0, sum))
        }
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
        if reward > 0 { awardGil(reward) }
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

    private static func normalizedProgression(_ source: ProgressionState) -> ProgressionState {
        var state = source
        state.completedExpeditions = min(999_999, max(0, state.completedExpeditions))
        state.wonMiniGames = min(999_999, max(0, state.wonMiniGames))
        if let decoration = state.equippedDecoration, !state.ownedDecorations.contains(decoration) {
            state.equippedDecoration = nil
        }
        return state
    }
}
