import UIKit

final class HomeViewController: UIViewController {
    let gameManager: GameManager
    var onOpenSettings: (() -> Void)?
    var onOpenExpeditions: (() -> Void)?
    var onQuickFeed: (() -> Void)?
    var onQuickPlay: (() -> Void)?
    var onQuickSleep: (() -> Void)?
    var onGameOver: (() -> Void)?

    private var lastAnimatedMood: PetMood?

    private let sectionLabel: UILabel = {
        ScreenKit.label("MOOGLE GARDENS  /  HÁBITAT", size: 12, color: ScreenKit.mutedText, weight: .bold)
    }()
    private let gilLabel: UILabel = {
        let label = ScreenKit.label("", size: 15, color: ScreenKit.gold, weight: .bold)
        label.backgroundColor = ScreenKit.panel
        label.layer.cornerRadius = 14
        label.layer.masksToBounds = true
        label.layer.borderWidth = 1
        label.layer.borderColor = ScreenKit.gold.withAlphaComponent(0.22).cgColor
        label.font = .monospacedDigitSystemFont(ofSize: 14, weight: .bold)
        return label
    }()
    private let petAuraView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ScreenKit.accent.withAlphaComponent(0.10)
        view.layer.cornerRadius = 70
        view.layer.borderWidth = 1
        view.layer.borderColor = ScreenKit.accent.withAlphaComponent(0.26).cgColor
        view.layer.shadowColor = ScreenKit.accent.cgColor
        view.layer.shadowOpacity = 0.18
        view.layer.shadowRadius = 18
        return view
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
        label.backgroundColor = UIColor.white.withAlphaComponent(0.10)
        label.layer.cornerRadius = 10
        label.layer.masksToBounds = true
        return label
    }()
    private let careHintLabel: UILabel = {
        let label = ScreenKit.label("", size: 11, color: ScreenKit.mutedText, weight: .medium)
        label.textAlignment = .left
        label.numberOfLines = 2
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

    private let settingsButton: UIButton = { ScreenKit.button("⚙️") }()
    private let expeditionsButton: UIButton = { ScreenKit.button("🧭  Expediciones") }()
    private let quickActionsTitleLabel: UILabel = {
        ScreenKit.label("CUIDADO RÁPIDO", size: 12, color: ScreenKit.gold, weight: .bold)
    }()
    private let quickFeedButton: UIButton = { ScreenKit.button("🍖\nRación") }()
    private let quickPlayButton: UIButton = { ScreenKit.button("🎯\nJugar") }()
    private let quickSleepButton: UIButton = { ScreenKit.button("🌙\nDormir") }()
    private let quickActionsCard: UIView = { ScreenKit.card() }()
    private let levelProgressLabel: UILabel = {
        let label = ScreenKit.label("", size: 11, color: ScreenKit.gold, weight: .bold)
        label.textAlignment = .left
        return label
    }()
    private let levelProgressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.trackTintColor = UIColor.white.withAlphaComponent(0.10)
        progress.progressTintColor = ScreenKit.gold
        return progress
    }()

    private lazy var headerStack: UIStackView = {
        let stack = ScreenKit.horizontalStack([sectionLabel, gilLabel, settingsButton])
        stack.alignment = .center
        stack.distribution = .fill
        sectionLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return stack
    }()
    private lazy var petCardStack: UIStackView = {
        let stack = ScreenKit.horizontalStack([petAuraView, petInfoStack])
        stack.distribution = .fill
        stack.alignment = .center
        return stack
    }()
    private lazy var petInfoStack: UIStackView = {
        ScreenKit.stack([nameLabel, moodLabel, careHintLabel, accessoryLabel, sleepStatusLabel], spacing: 7)
    }()
    private lazy var statsStack: UIStackView = {
        ScreenKit.stack([statsTitleLabel, levelProgressLabel, levelProgressView, hungerMeter, happinessMeter, energyMeter], spacing: 11)
    }()
    private lazy var questsStack: UIStackView = {
        ScreenKit.stack([questsTitleLabel, feedQuestRow, playQuestRow, sleepQuestRow, expeditionQuestRow], spacing: 12)
    }()
    private lazy var quickActionsRow: UIStackView = {
        let stack = ScreenKit.horizontalStack([quickFeedButton, quickPlayButton, quickSleepButton])
        stack.distribution = .fillEqually
        stack.alignment = .fill
        stack.spacing = 8
        return stack
    }()
    private lazy var quickActionsStack: UIStackView = {
        ScreenKit.stack([quickActionsTitleLabel, quickActionsRow], spacing: 12)
    }()
    private lazy var contentStack: UIStackView = {
        ScreenKit.stack([headerStack, petCard, statsCard, quickActionsCard, expeditionsButton, questsCard], spacing: 15)
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
        quickActionsCard.addSubview(quickActionsStack)
        NSLayoutConstraint.activate([
            quickActionsStack.topAnchor.constraint(equalTo: quickActionsCard.topAnchor, constant: 16),
            quickActionsStack.leadingAnchor.constraint(equalTo: quickActionsCard.leadingAnchor, constant: 16),
            quickActionsStack.trailingAnchor.constraint(equalTo: quickActionsCard.trailingAnchor, constant: -16),
            quickActionsStack.bottomAnchor.constraint(equalTo: quickActionsCard.bottomAnchor, constant: -16),
            levelProgressView.heightAnchor.constraint(equalToConstant: 6),
            settingsButton.widthAnchor.constraint(equalToConstant: 42),
            settingsButton.heightAnchor.constraint(equalToConstant: 42)
        ])
        ScreenKit.installScrollable(contentStack, in: self)

        gameManager.onChange = { [weak self] in self?.refresh() }
        gameManager.onGameOver = { [weak self] in self?.onGameOver?() }
        NotificationCenter.default.addObserver(self, selector: #selector(reduceMotionDidChange), name: UIAccessibility.reduceMotionStatusDidChangeNotification, object: nil)
        refresh()

        if gameManager.pet?.isGameOver == true {
            DispatchQueue.main.async { [weak self] in self?.onGameOver?() }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        gameManager.onChange = { [weak self] in self?.refresh() }
        gameManager.onGameOver = { [weak self] in self?.onGameOver?() }
        gameManager.updateElapsedTime()
        refresh()
        updatePetAnimation(for: gameManager.pet?.mood ?? .calm)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        petSpriteView.layer.removeAllAnimations()
        petSpriteView.transform = .identity
        lastAnimatedMood = nil
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    private func configureCards() {
        petCard.layer.borderWidth = 1.5
        petCard.layer.borderColor = ScreenKit.accent.withAlphaComponent(0.28).cgColor
        questsCard.layer.borderColor = ScreenKit.gold.withAlphaComponent(0.16).cgColor
        petAuraView.addSubview(petSpriteView)
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
            petCard.heightAnchor.constraint(greaterThanOrEqualToConstant: 200),
            petAuraView.widthAnchor.constraint(equalToConstant: 140),
            petAuraView.heightAnchor.constraint(equalToConstant: 140),
            petSpriteView.centerXAnchor.constraint(equalTo: petAuraView.centerXAnchor),
            petSpriteView.centerYAnchor.constraint(equalTo: petAuraView.centerYAnchor),
            petSpriteView.widthAnchor.constraint(equalToConstant: 126),
            petSpriteView.heightAnchor.constraint(equalToConstant: 126),
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
        if var configuration = settingsButton.configuration {
            configuration.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
            configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = .systemFont(ofSize: 18, weight: .bold)
                return outgoing
            }
            settingsButton.configuration = configuration
        }
        settingsButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        settingsButton.accessibilityLabel = "Ajustes"
        quickFeedButton.accessibilityLabel = "Alimentar a la mascota"
        quickFeedButton.accessibilityHint = "Usa una ración o abre la mochila si no tienes ninguna."
        quickPlayButton.accessibilityLabel = "Jugar minijuego"
        quickSleepButton.accessibilityLabel = "Dormir o despertar a la mascota"
        expeditionsButton.addTarget(self, action: #selector(openExpeditions), for: .touchUpInside)
        quickFeedButton.addTarget(self, action: #selector(quickFeed), for: .touchUpInside)
        quickPlayButton.addTarget(self, action: #selector(quickPlay), for: .touchUpInside)
        quickSleepButton.addTarget(self, action: #selector(quickSleep), for: .touchUpInside)
        ScreenKit.setBackground(UIColor(red: 0.43, green: 0.35, blue: 0.62, alpha: 1), on: expeditionsButton)
        styleQuickAction(quickFeedButton, tint: UIColor(red: 0.43, green: 0.25, blue: 0.24, alpha: 1))
        styleQuickAction(quickPlayButton, tint: UIColor(red: 0.25, green: 0.31, blue: 0.53, alpha: 1))
        styleQuickAction(quickSleepButton, tint: UIColor(red: 0.20, green: 0.37, blue: 0.40, alpha: 1))
    }

    private func refresh() {
        guard let pet = gameManager.pet else { return }
        petSpriteView.kind = pet.kind
        petSpriteView.mood = pet.mood
        petSpriteView.equippedItems = gameManager.activeEquipment
        let phase = WorldPhase.current()
        habitatView.phase = phase
        sectionLabel.text = "MOOGLE GARDENS  /  \(phase.title)"
        moodLabel.text = "  \(pet.mood.symbol)  \(pet.mood.title)  "
        careHintLabel.text = careHint(for: pet)
        careHintLabel.textColor = pet.hunger < 30 || pet.happiness < 30 || pet.energy < 25 ? .systemOrange : ScreenKit.mutedText
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
        levelProgressLabel.text = "NIVEL \(pet.level)  ·  \(pet.experience) / \(pet.nextLevelExperience) EXP"
        levelProgressView.setProgress(Float(pet.experience) / Float(max(1, pet.nextLevelExperience)), animated: true)
        let rationCount = gameManager.inventory[.ration, default: 0]
        ScreenKit.setTitle(rationCount > 0 ? "🍖\nRación ×\(rationCount)" : "🎒\nMochila", on: quickFeedButton)
        ScreenKit.setTitle(pet.isSleeping ? "☀️\nDespertar" : "🌙\nDormir", on: quickSleepButton)
        quickFeedButton.isEnabled = pet.hunger < 100
        quickPlayButton.isEnabled = !pet.isSleeping && !pet.isGameOver && pet.energy >= 8
        quickSleepButton.isEnabled = pet.isSleeping || (!pet.isGameOver && pet.energy < 100)
        for button in [quickFeedButton, quickPlayButton, quickSleepButton] {
            button.alpha = button.isEnabled ? 1 : 0.4
        }
        if let expedition = gameManager.activeExpedition {
            let title = expedition.isReady() ? "🎁  Botín listo · \(expedition.route.title)" : "🧭  Expedición · \(expedition.route.title)"
            ScreenKit.setTitle(title, on: expeditionsButton)
        } else {
            ScreenKit.setTitle("🧭  Expediciones", on: expeditionsButton)
        }
        hungerMeter.update(value: pet.hunger)
        happinessMeter.update(value: pet.happiness)
        energyMeter.update(value: pet.energy)
        updatePetAnimation(for: pet.mood)
    }

    private func careHint(for pet: PetModel) -> String {
        if pet.isSleeping { return "Descansa; la energía se recupera poco a poco." }
        if pet.hunger < 35 { return "Tiene hambre. Una ración le devolverá fuerzas." }
        if pet.energy < 30 { return "Está cansado. Déjalo dormir para recuperarse." }
        if pet.happiness < 35 { return "Necesita un momento contigo. ¡Juega un rato!" }
        return "Todo marcha bien. ¿Qué aventura vivirán hoy?"
    }

    @objc private func openSettings() { onOpenSettings?() }
    @objc private func openExpeditions() { onOpenExpeditions?() }
    @objc private func quickFeed() { onQuickFeed?() }
    @objc private func quickPlay() { onQuickPlay?() }
    @objc private func quickSleep() { onQuickSleep?() }

    @objc private func reduceMotionDidChange(_ notification: Notification) {
        lastAnimatedMood = nil
        updatePetAnimation(for: gameManager.pet?.mood ?? .calm)
    }

    private func updatePetAnimation(for mood: PetMood) {
        guard viewIfLoaded?.window != nil, mood != lastAnimatedMood else { return }
        lastAnimatedMood = mood
        petSpriteView.layer.removeAllAnimations()
        petSpriteView.transform = .identity
        guard !UIAccessibility.isReduceMotionEnabled else { return }

        let duration: TimeInterval
        let target: CGAffineTransform
        switch mood {
        case .joyful:
            duration = 0.62
            target = CGAffineTransform(translationX: 0, y: -8).scaledBy(x: 1.04, y: 1.04)
        case .sleeping:
            duration = 2.0
            target = CGAffineTransform(scaleX: 1.035, y: 1.035)
        case .sad:
            duration = 2.3
            target = CGAffineTransform(translationX: 0, y: 1)
        case .hungry, .tired:
            duration = 1.45
            target = CGAffineTransform(translationX: 0, y: -2)
        case .calm:
            duration = 1.7
            target = CGAffineTransform(translationX: 0, y: -4)
        }

        UIView.animate(withDuration: duration, delay: 0, options: [.autoreverse, .repeat, .allowUserInteraction, .beginFromCurrentState], animations: {
            self.petSpriteView.transform = target
        }, completion: nil)
    }

    private func styleQuickAction(_ button: UIButton, tint: UIColor) {
        guard var configuration = button.configuration else { return }
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 9, leading: 6, bottom: 9, trailing: 6)
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 12, weight: .semibold)
            return outgoing
        }
        configuration.baseBackgroundColor = tint
        button.configuration = configuration
        button.titleLabel?.textAlignment = .center
        button.layer.shadowOpacity = 0.08
    }

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
