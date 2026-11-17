import UIKit

final class HomeViewController: UIViewController {
    let gameManager: GameManager
    var onOpenActions: (() -> Void)?
    var onOpenInventory: (() -> Void)?
    var onOpenCharacterSheet: (() -> Void)?
    var onOpenShop: (() -> Void)?
    var onOpenSettings: (() -> Void)?
    var onOpenExpeditions: (() -> Void)?
    var onGameOver: (() -> Void)?

    private let sectionLabel: UILabel = {
        ScreenKit.label("MOOGLE GARDENS  /  HÁBITAT", size: 12, color: ScreenKit.mutedText, weight: .bold)
    }()
    private let gilLabel: UILabel = {
        let label = ScreenKit.label("", size: 15, color: ScreenKit.gold, weight: .bold)
        label.backgroundColor = ScreenKit.panel
        label.layer.cornerRadius = 14
        label.layer.masksToBounds = true
        return label
    }()
    private let petSpriteView: PixelPetSpriteView = {
        let spriteView = PixelPetSpriteView()
        spriteView.translatesAutoresizingMaskIntoConstraints = false
        return spriteView
    }()
    private let nameLabel: UILabel = {
        let label = ScreenKit.label("", size: 22, color: .white, weight: .bold)
        label.textAlignment = .left
        return label
    }()
    private let accessoryLabel: UILabel = {
        let label = ScreenKit.label("", size: 12, color: ScreenKit.gold, weight: .semibold)
        label.textAlignment = .left
        return label
    }()
    private let sleepStatusLabel: UILabel = {
        let label = ScreenKit.label("", size: 11, color: ScreenKit.mint, weight: .bold)
        label.textAlignment = .left
        return label
    }()
    private let petCard: UIView = { ScreenKit.card() }()
    private let habitatView: HabitatSceneView = { HabitatSceneView() }()
    private let moodLabel: UILabel = {
        let label = ScreenKit.label("", size: 12, color: .white, weight: .bold)
        label.textAlignment = .left
        return label
    }()
    private let questsTitleLabel: UILabel = {
        let label = ScreenKit.label("ENCARGOS DE HOY", size: 12, color: ScreenKit.gold, weight: .bold)
        label.textAlignment = .left
        return label
    }()
    private let feedQuestRow: DailyQuestRowView = { DailyQuestRowView() }()
    private let playQuestRow: DailyQuestRowView = { DailyQuestRowView() }()
    private let sleepQuestRow: DailyQuestRowView = { DailyQuestRowView() }()
    private let expeditionQuestRow: DailyQuestRowView = { DailyQuestRowView() }()
    private let questsCard: UIView = { ScreenKit.card() }()
    private let statsCard: UIView = { ScreenKit.card() }()
    private let statsTitleLabel: UILabel = {
        let label = ScreenKit.label("ESTADO DEL COMPAÑERO", size: 12, color: ScreenKit.mutedText, weight: .bold)
        label.textAlignment = .left
        return label
    }()

    private let hungerMeter: StatusMeterView = {
        StatusMeterView(title: "SACIEDAD", tint: UIColor(red: 1, green: 0.61, blue: 0.35, alpha: 1))
    }()
    private let happinessMeter: StatusMeterView = {
        StatusMeterView(title: "ÁNIMO", tint: UIColor(red: 1, green: 0.45, blue: 0.64, alpha: 1))
    }()
    private let energyMeter: StatusMeterView = {
        StatusMeterView(title: "ENERGÍA", tint: ScreenKit.accent)
    }()

    private let actionsButton: UIButton = { ScreenKit.button("⚔️  ABRIR COMANDOS") }()
    private let inventoryButton: UIButton = { ScreenKit.button("🎒  Inventario") }()
    private let sheetButton: UIButton = { ScreenKit.button("📜  Estado") }()
    private let shopButton: UIButton = { ScreenKit.button("🛍️  Tienda") }()
    private let settingsButton: UIButton = { ScreenKit.button("⚙️  Ajustes") }()
    private let expeditionsButton: UIButton = { ScreenKit.button("🧭  Expediciones") }()

    private lazy var headerStack: UIStackView = {
        let stack = ScreenKit.horizontalStack([sectionLabel, gilLabel])
        stack.alignment = .center
        return stack
    }()
    private lazy var petCardStack: UIStackView = {
        let stack = ScreenKit.horizontalStack([petSpriteView, petInfoStack])
        stack.distribution = .fill
        stack.alignment = .center
        return stack
    }()
    private lazy var petInfoStack: UIStackView = {
        ScreenKit.stack([nameLabel, moodLabel, accessoryLabel, sleepStatusLabel], spacing: 6)
    }()
    private lazy var statsStack: UIStackView = {
        ScreenKit.stack([statsTitleLabel, hungerMeter, happinessMeter, energyMeter], spacing: 13)
    }()
    private lazy var questsStack: UIStackView = {
        ScreenKit.stack([questsTitleLabel, feedQuestRow, playQuestRow, sleepQuestRow, expeditionQuestRow], spacing: 12)
    }()
    private lazy var utilityRowOne: UIStackView = {
        let stack = ScreenKit.horizontalStack([inventoryButton, sheetButton])
        stack.distribution = .fillEqually
        return stack
    }()
    private lazy var utilityRowTwo: UIStackView = {
        let stack = ScreenKit.horizontalStack([shopButton, settingsButton])
        stack.distribution = .fillEqually
        return stack
    }()
    private lazy var contentStack: UIStackView = {
        ScreenKit.stack([headerStack, petCard, statsCard, questsCard, actionsButton, utilityRowOne, utilityRowTwo, expeditionsButton], spacing: 15)
    }()

    init(gameManager: GameManager) {
        self.gameManager = gameManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no está disponible") }

    override func viewDidLoad() {
        super.viewDidLoad()
        ScreenKit.configure(self, title: "Hábitat")
        configureCards()
        configureButtons()
        ScreenKit.installScrollable(contentStack, in: self)

        gameManager.onChange = { [weak self] in self?.refresh() }
        gameManager.onGameOver = { [weak self] in self?.onGameOver?() }
        refresh()

        if gameManager.pet?.isGameOver == true {
            DispatchQueue.main.async { [weak self] in self?.onGameOver?() }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        gameManager.updateElapsedTime()
        if let expedition = gameManager.activeExpedition {
            let title = expedition.isReady() ? "🎁  Botín listo · \(expedition.route.title)" : "🧭  Expedición · \(expedition.route.title)"
            ScreenKit.setTitle(title, on: expeditionsButton)
        } else {
            ScreenKit.setTitle("🧭  Expediciones", on: expeditionsButton)
        }
        petSpriteView.transform = .identity
        UIView.animate(withDuration: 1.8, delay: 0, options: [.autoreverse, .repeat, .allowUserInteraction, .beginFromCurrentState], animations: {
            self.petSpriteView.transform = CGAffineTransform(translationX: 0, y: -5)
        }, completion: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        petSpriteView.layer.removeAllAnimations()
        petSpriteView.transform = .identity
    }

    private func configureCards() {
        petCard.addSubview(petCardStack)
        petCard.insertSubview(habitatView, at: 0)
        statsCard.addSubview(statsStack)
        questsCard.addSubview(questsStack)

        NSLayoutConstraint.activate([
            habitatView.topAnchor.constraint(equalTo: petCard.topAnchor),
            habitatView.leadingAnchor.constraint(equalTo: petCard.leadingAnchor),
            habitatView.trailingAnchor.constraint(equalTo: petCard.trailingAnchor),
            habitatView.bottomAnchor.constraint(equalTo: petCard.bottomAnchor),
            petCardStack.topAnchor.constraint(equalTo: petCard.topAnchor, constant: 18),
            petCardStack.leadingAnchor.constraint(equalTo: petCard.leadingAnchor, constant: 20),
            petCardStack.trailingAnchor.constraint(equalTo: petCard.trailingAnchor, constant: -20),
            petCardStack.bottomAnchor.constraint(equalTo: petCard.bottomAnchor, constant: -18),
            petCard.heightAnchor.constraint(greaterThanOrEqualToConstant: 176),
            petSpriteView.widthAnchor.constraint(equalToConstant: 120),
            petSpriteView.heightAnchor.constraint(equalToConstant: 120),
            statsStack.topAnchor.constraint(equalTo: statsCard.topAnchor, constant: 18),
            statsStack.leadingAnchor.constraint(equalTo: statsCard.leadingAnchor, constant: 18),
            statsStack.trailingAnchor.constraint(equalTo: statsCard.trailingAnchor, constant: -18),
            statsStack.bottomAnchor.constraint(equalTo: statsCard.bottomAnchor, constant: -18),
            questsStack.topAnchor.constraint(equalTo: questsCard.topAnchor, constant: 18),
            questsStack.leadingAnchor.constraint(equalTo: questsCard.leadingAnchor, constant: 18),
            questsStack.trailingAnchor.constraint(equalTo: questsCard.trailingAnchor, constant: -18),
            questsStack.bottomAnchor.constraint(equalTo: questsCard.bottomAnchor, constant: -18)
        ])
    }

    private func configureButtons() {
        actionsButton.addTarget(self, action: #selector(openActions), for: .touchUpInside)
        inventoryButton.addTarget(self, action: #selector(openInventory), for: .touchUpInside)
        sheetButton.addTarget(self, action: #selector(openSheet), for: .touchUpInside)
        shopButton.addTarget(self, action: #selector(openShop), for: .touchUpInside)
        settingsButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        expeditionsButton.addTarget(self, action: #selector(openExpeditions), for: .touchUpInside)

        ScreenKit.setBackground(UIColor(red: 0.19, green: 0.37, blue: 0.55, alpha: 1), on: actionsButton)
        actionsButton.layer.borderWidth = 1
        actionsButton.layer.borderColor = ScreenKit.accent.withAlphaComponent(0.35).cgColor
        NSLayoutConstraint.activate([
            actionsButton.heightAnchor.constraint(equalToConstant: 58)
        ])
    }

    private func refresh() {
        guard let pet = gameManager.pet else { return }
        petSpriteView.kind = pet.kind
        petSpriteView.mood = pet.mood
        petSpriteView.equippedItems = gameManager.activeEquipment
        let phase = WorldPhase.current()
        habitatView.phase = phase
        sectionLabel.text = "MOOGLE GARDENS  /  \(phase.title)"
        moodLabel.text = "\(pet.mood.symbol)  \(pet.mood.title)"
        for quest in gameManager.dailyQuests.quests {
            switch quest.kind {
            case .feed: feedQuestRow.update(quest)
            case .play: playQuestRow.update(quest)
            case .sleep: sleepQuestRow.update(quest)
            case .expedition: expeditionQuestRow.update(quest)
            }
        }
        nameLabel.text = "\(pet.name)  ·  NIVEL \(pet.level)"
        accessoryLabel.text = "EQUIPO  ·  \(gameManager.equipmentSummary)"
        sleepStatusLabel.text = pet.isSleeping ? "✦  DESCANSANDO  ✦" : ""
        gilLabel.text = "  ◈  \(gameManager.gil) GIL  "
        hungerMeter.update(value: pet.hunger)
        happinessMeter.update(value: pet.happiness)
        energyMeter.update(value: pet.energy)
    }

    @objc private func openActions() { onOpenActions?() }
    @objc private func openInventory() { onOpenInventory?() }
    @objc private func openSheet() { onOpenCharacterSheet?() }
    @objc private func openShop() { onOpenShop?() }
    @objc private func openSettings() { onOpenSettings?() }
    @objc private func openExpeditions() { onOpenExpeditions?() }
}

private final class StatusMeterView: UIView {
    private var normalTint: UIColor = ScreenKit.accent
    private let titleLabel: UILabel = {
        let label = ScreenKit.label("", size: 11, color: ScreenKit.mutedText, weight: .bold)
        label.textAlignment = .left
        return label
    }()
    private let valueLabel: UILabel = {
        let label = ScreenKit.label("0%", size: 12, color: .white, weight: .semibold)
        label.textAlignment = .right
        return label
    }()
    private let progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.trackTintColor = UIColor.white.withAlphaComponent(0.10)
        progress.layer.cornerRadius = 4
        progress.clipsToBounds = true
        return progress
    }()
    private lazy var labelsStack: UIStackView = {
        ScreenKit.horizontalStack([titleLabel, valueLabel])
    }()
    private lazy var contentStack: UIStackView = {
        ScreenKit.stack([labelsStack, progressView], spacing: 7)
    }()

    init(title: String, tint: UIColor) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        normalTint = tint
        progressView.progressTintColor = tint
        addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 8),
            heightAnchor.constraint(equalToConstant: 38)
        ])
        isAccessibilityElement = true
        accessibilityLabel = title
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no está disponible") }

    func update(value: Double) {
        let safeValue = min(100, max(0, value))
        valueLabel.text = "\(Int(safeValue))%"
        progressView.setProgress(Float(safeValue / 100), animated: true)
        progressView.progressTintColor = safeValue < 25 ? .systemRed : (safeValue < 50 ? .systemOrange : normalTint)
        accessibilityValue = "\(Int(safeValue)) por ciento"
    }
}

private final class DailyQuestRowView: UIView {
    private let titleLabel: UILabel = {
        let label = ScreenKit.label("", size: 13, color: .white, weight: .medium)
        label.textAlignment = .left
        return label
    }()
    private let progressLabel: UILabel = {
        let label = ScreenKit.label("", size: 11, color: ScreenKit.mutedText, weight: .bold)
        label.textAlignment = .right
        return label
    }()
    private let progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.trackTintColor = UIColor.white.withAlphaComponent(0.10)
        progress.progressTintColor = ScreenKit.mint
        return progress
    }()
    private lazy var headerStack: UIStackView = {
        let stack = ScreenKit.horizontalStack([titleLabel, progressLabel])
        stack.distribution = .fill
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        progressLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        return stack
    }()
    private lazy var contentStack: UIStackView = {
        ScreenKit.stack([headerStack, progressView], spacing: 6)
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 5)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no está disponible") }

    func update(_ quest: DailyQuest) {
        titleLabel.text = "\(quest.kind.symbol)  \(quest.kind.title)"
        progressLabel.text = quest.rewardClaimed ? "✓ +\(quest.kind.gilReward) GIL" : "\(min(quest.progress, quest.kind.target))/\(quest.kind.target)"
        progressView.setProgress(Float(quest.progress) / Float(quest.kind.target), animated: true)
        accessibilityLabel = quest.summary
        accessibilityValue = quest.rewardClaimed ? "Completada, recompensa recibida" : "\(quest.progress) de \(quest.kind.target)"
        isAccessibilityElement = true
    }
}
