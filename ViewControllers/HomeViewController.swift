import UIKit

final class HomeViewController: UIViewController {
    let gameManager: GameManager
    var onOpenSettings: (() -> Void)?
    var onOpenExpeditions: (() -> Void)?
    var onQuickFeed: (() -> Void)?
    var onQuickPlay: (() -> Void)?
    var onQuickSleep: (() -> Void)?

    private var observerToken: UUID?
    private var lastAnimatedMood: PetMood?
    private var temporaryHint: String?

    private let sectionLabel = ScreenKit.sectionTitle("MOOGLE GARDENS  /  HÁBITAT", color: ScreenKit.faintText)
    private let streakLabel: UILabel = {
        let label = ScreenKit.label("", size: 11.5, color: ScreenKit.gold, weight: .semibold, textStyle: .caption1)
        label.textAlignment = .left
        return label
    }()
    private let gilLabel = ScreenKit.pill("0 GIL", color: ScreenKit.gold)

    private let petCard: UIView = { ScreenKit.card() }()
    private let habitatView = HabitatSceneView()
    private let petAuraView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ScreenKit.accent.withAlphaComponent(0.10)
        view.layer.cornerRadius = 62
        view.layer.cornerCurve = .continuous
        view.layer.borderWidth = 1
        view.layer.borderColor = ScreenKit.accent.withAlphaComponent(0.28).cgColor
        view.layer.shadowColor = ScreenKit.accent.cgColor
        view.layer.shadowOpacity = 0.22
        view.layer.shadowRadius = 22
        view.layer.shadowOffset = .zero
        return view
    }()
    private let petSpriteView: PixelPetSpriteView = {
        let view = PixelPetSpriteView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private let nameLabel: UILabel = {
        let label = ScreenKit.label("", size: 22, color: .white, weight: .bold, textStyle: .title2)
        label.textAlignment = .left
        return label
    }()
    private let moodLabel = ScreenKit.pill("", color: ScreenKit.mint)
    private let careHintLabel: UILabel = {
        let label = ScreenKit.label("", size: 12.5, color: ScreenKit.mutedText, textStyle: .subheadline)
        label.textAlignment = .left
        label.numberOfLines = 2
        return label
    }()
    private let accessoryLabel: UILabel = {
        let label = ScreenKit.label("", size: 11.5, color: ScreenKit.gold, weight: .medium, textStyle: .caption1)
        label.textAlignment = .left
        return label
    }()
    private let sleepStatusLabel: UILabel = {
        let label = ScreenKit.label("", size: 11, color: ScreenKit.sky, weight: .bold, textStyle: .caption2)
        label.textAlignment = .left
        return label
    }()
    private let levelProgressLabel: UILabel = {
        let label = ScreenKit.label("", size: 11, color: ScreenKit.mutedText, weight: .semibold, textStyle: .caption1)
        label.textAlignment = .left
        return label
    }()
    private let levelProgressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.trackTintColor = UIColor.white.withAlphaComponent(0.08)
        progress.progressTintColor = ScreenKit.gold
        progress.layer.cornerRadius = 3
        progress.clipsToBounds = true
        return progress
    }()

    private let statusCard: UIView = { ScreenKit.card() }()
    private let statusTitle = ScreenKit.sectionTitle("ESTADO DEL COMPAÑERO")
    private let hungerMeter = StatusMeterView(title: "SACIEDAD", symbol: "fork.knife", tint: ScreenKit.hunger)
    private let happinessMeter = StatusMeterView(title: "ÁNIMO", symbol: "heart.fill", tint: ScreenKit.rose)
    private let energyMeter = StatusMeterView(title: "ENERGÍA", symbol: "bolt.fill", tint: ScreenKit.sky)

    private let quickCard: UIView = { ScreenKit.card() }()
    private let quickTitle = ScreenKit.sectionTitle("CUIDADO RÁPIDO")
    private let quickFeedButton = QuickActionButton(symbol: "fork.knife", title: "Alimentar")
    private let quickPlayButton = QuickActionButton(symbol: "gamecontroller.fill", title: "Jugar")
    private let quickSleepButton = QuickActionButton(symbol: "moon.stars.fill", title: "Dormir")

    private let expeditionsControl = MenuCardControl()
    private let questsCard: UIView = { ScreenKit.card() }()
    private let questsTitleLabel = ScreenKit.sectionTitle("ENCARGOS DE HOY", color: ScreenKit.gold)
    private let feedQuestRow = DailyQuestRowView()
    private let playQuestRow = DailyQuestRowView()
    private let sleepQuestRow = DailyQuestRowView()
    private let expeditionQuestRow = DailyQuestRowView()

    private lazy var settingsButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = ScreenKit.panel
        button.layer.cornerRadius = 15
        button.layer.cornerCurve = .continuous
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.06).cgColor
        button.setImage(ScreenKit.symbolImage("gearshape.fill", size: 17, color: ScreenKit.mutedText), for: .normal)
        button.accessibilityLabel = "Ajustes"
        return button
    }()

    private lazy var headerStack: UIStackView = {
        let stack = ScreenKit.headerRow(title: sectionLabel, trailing: [gilLabel, settingsButton])
        stack.alignment = .center
        return stack
    }()
    private lazy var petInfoStack: UIStackView = {
        let stack = ScreenKit.stack([nameLabel, moodLabel, careHintLabel, accessoryLabel, sleepStatusLabel, levelProgressLabel, levelProgressView], spacing: 7)
        stack.alignment = .fill
        stack.setCustomSpacing(10, after: sleepStatusLabel)
        return stack
    }()
    private lazy var petRowStack: UIStackView = {
        let stack = ScreenKit.horizontalStack([petAuraView, petInfoStack], spacing: 16)
        stack.distribution = .fill
        stack.alignment = .center
        return stack
    }()
    private lazy var statusStack: UIStackView = {
        ScreenKit.stack([statusTitle, hungerMeter, happinessMeter, energyMeter], spacing: 12)
    }()
    private lazy var quickRow: UIStackView = {
        let stack = ScreenKit.horizontalStack([quickFeedButton, quickPlayButton, quickSleepButton], spacing: 10)
        stack.distribution = .fillEqually
        stack.alignment = .fill
        return stack
    }()
    private lazy var quickStack: UIStackView = {
        ScreenKit.stack([quickTitle, quickRow], spacing: 12)
    }()
    private lazy var questsStack: UIStackView = {
        ScreenKit.stack([questsTitleLabel, feedQuestRow, playQuestRow, sleepQuestRow, expeditionQuestRow], spacing: 13)
    }()
    private lazy var contentStack: UIStackView = {
        ScreenKit.stack([headerStack, streakLabel, petCard, statusCard, quickCard, expeditionsControl, questsCard], spacing: 13)
    }()

    init(gameManager: GameManager) {
        self.gameManager = gameManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no está disponible") }

    override func viewDidLoad() {
        super.viewDidLoad()
        ScreenKit.configure(self, title: "Hábitat")
        buildLayout()
        configureActions()
        ScreenKit.installScrollable(contentStack, in: self)

        observerToken = gameManager.addObserver { [weak self] in self?.refresh() }
        NotificationCenter.default.addObserver(self, selector: #selector(reduceMotionDidChange(_:)), name: UIAccessibility.reduceMotionStatusDidChangeNotification, object: nil)
        refresh()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        gameManager.updateElapsedTime()
        refresh()
    }

    deinit {
        gameManager.removeObserver(observerToken)
        NotificationCenter.default.removeObserver(self)
    }

    func showMiniGameResult(success: Bool) {
        temporaryHint = success
            ? "Victoria: tu compañero ganó experiencia y Gil."
            : "La práctica también cuenta: recibiste una pequeña recompensa."
        refresh()
        UIAccessibility.post(notification: .announcement, argument: temporaryHint)
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) { [weak self] in
            guard let self, self.viewIfLoaded?.window != nil else { return }
            self.temporaryHint = nil
            self.refresh()
        }
    }

    private func buildLayout() {
        petCard.layer.borderColor = ScreenKit.accent.withAlphaComponent(0.22).cgColor
        questsCard.layer.borderColor = ScreenKit.gold.withAlphaComponent(0.14).cgColor

        petAuraView.addSubview(petSpriteView)
        petCard.insertSubview(habitatView, at: 0)
        petCard.addSubview(petRowStack)
        statusCard.addSubview(statusStack)
        quickCard.addSubview(quickStack)
        questsCard.addSubview(questsStack)

        NSLayoutConstraint.activate([
            habitatView.topAnchor.constraint(equalTo: petCard.topAnchor),
            habitatView.leadingAnchor.constraint(equalTo: petCard.leadingAnchor),
            habitatView.trailingAnchor.constraint(equalTo: petCard.trailingAnchor),
            habitatView.bottomAnchor.constraint(equalTo: petCard.bottomAnchor),

            petRowStack.topAnchor.constraint(equalTo: petCard.topAnchor, constant: 20),
            petRowStack.leadingAnchor.constraint(equalTo: petCard.leadingAnchor, constant: 20),
            petRowStack.trailingAnchor.constraint(equalTo: petCard.trailingAnchor, constant: -20),
            petRowStack.bottomAnchor.constraint(equalTo: petCard.bottomAnchor, constant: -20),
            petCard.heightAnchor.constraint(greaterThanOrEqualToConstant: 210),
            petAuraView.widthAnchor.constraint(equalToConstant: 124),
            petAuraView.heightAnchor.constraint(equalToConstant: 124),
            petSpriteView.centerXAnchor.constraint(equalTo: petAuraView.centerXAnchor),
            petSpriteView.centerYAnchor.constraint(equalTo: petAuraView.centerYAnchor),
            petSpriteView.widthAnchor.constraint(equalToConstant: 112),
            petSpriteView.heightAnchor.constraint(equalToConstant: 112),

            statusStack.topAnchor.constraint(equalTo: statusCard.topAnchor, constant: 16),
            statusStack.leadingAnchor.constraint(equalTo: statusCard.leadingAnchor, constant: 18),
            statusStack.trailingAnchor.constraint(equalTo: statusCard.trailingAnchor, constant: -18),
            statusStack.bottomAnchor.constraint(equalTo: statusCard.bottomAnchor, constant: -18),

            quickStack.topAnchor.constraint(equalTo: quickCard.topAnchor, constant: 16),
            quickStack.leadingAnchor.constraint(equalTo: quickCard.leadingAnchor, constant: 18),
            quickStack.trailingAnchor.constraint(equalTo: quickCard.trailingAnchor, constant: -18),
            quickStack.bottomAnchor.constraint(equalTo: quickCard.bottomAnchor, constant: -18),

            questsStack.topAnchor.constraint(equalTo: questsCard.topAnchor, constant: 16),
            questsStack.leadingAnchor.constraint(equalTo: questsCard.leadingAnchor, constant: 18),
            questsStack.trailingAnchor.constraint(equalTo: questsCard.trailingAnchor, constant: -18),
            questsStack.bottomAnchor.constraint(equalTo: questsCard.bottomAnchor, constant: -18),

            levelProgressView.heightAnchor.constraint(equalToConstant: 5),
            settingsButton.widthAnchor.constraint(equalToConstant: 44),
            settingsButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func configureActions() {
        settingsButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        quickFeedButton.addTarget(self, action: #selector(quickFeed), for: .touchUpInside)
        quickPlayButton.addTarget(self, action: #selector(quickPlay), for: .touchUpInside)
        quickSleepButton.addTarget(self, action: #selector(quickSleep), for: .touchUpInside)
        expeditionsControl.addTarget(self, action: #selector(openExpeditions), for: .touchUpInside)
        expeditionsControl.update(
            symbolName: "map.fill",
            title: "Expediciones",
            subtitle: "Envía a tu compañero a buscar tesoros.",
            tint: ScreenKit.sky
        )
    }

    private func refresh() {
        guard let pet = gameManager.pet else { return }
        petSpriteView.kind = pet.kind
        petSpriteView.mood = pet.mood
        petSpriteView.evolutionStage = EvolutionStage(level: pet.level)
        petSpriteView.equippedItems = gameManager.activeEquipment

        let phase = WorldPhase.current()
        habitatView.phase = phase
        habitatView.decoration = gameManager.progression.equippedDecoration
        sectionLabel.text = "MOOGLE GARDENS  /  \(phase.title)"

        nameLabel.text = pet.name
        moodLabel.attributedText = ScreenKit.symbolText(
            pet.mood.symbolName,
            text: "  \(pet.mood.title)  ",
            size: 11.5,
            weight: .semibold,
            color: ScreenKit.mint,
            textStyle: .caption1
        )
        careHintLabel.text = careHint(for: pet)
        careHintLabel.textColor = pet.isCritical ? ScreenKit.hunger : ScreenKit.mutedText
        accessoryLabel.text = gameManager.activeEquipment.isEmpty
            ? "Sin equipo"
            : "Equipo · \(gameManager.equipmentSummary)"
        sleepStatusLabel.attributedText = pet.isSleeping
            ? ScreenKit.symbolText("moon.zzz.fill", text: "DESCANSANDO", size: 10.5, weight: .bold, color: ScreenKit.sky, textStyle: .caption2)
            : nil
        levelProgressLabel.text = "NIVEL \(pet.level)  ·  \(pet.experience) / \(pet.nextLevelExperience) EXP"
        levelProgressView.setProgress(Float(pet.experience) / Float(max(1, pet.nextLevelExperience)), animated: true)

        gilLabel.attributedText = ScreenKit.symbolText("diamond.fill", text: " \(gameManager.gil) GIL ", size: 12, weight: .bold, color: ScreenKit.gold, textStyle: .caption1)
        let streakUnit = gameManager.dailyStreak.days == 1 ? "día" : "días"
        streakLabel.attributedText = ScreenKit.symbolText(
            "flame.fill",
            text: "  Racha de cuidado · \(gameManager.dailyStreak.days) \(streakUnit) · +\(gameManager.dailyStreak.lastReward) Gil hoy",
            size: 11.5,
            weight: .semibold,
            color: ScreenKit.gold,
            textStyle: .caption1
        )

        for quest in gameManager.dailyQuests.quests {
            switch quest.kind {
            case .feed: feedQuestRow.update(quest)
            case .play: playQuestRow.update(quest)
            case .sleep: sleepQuestRow.update(quest)
            case .expedition: expeditionQuestRow.update(quest)
            }
        }

        let rationCount = gameManager.inventory[.ration, default: 0]
        quickFeedButton.update(
            symbol: "fork.knife",
            title: rationCount > 0 ? "Ración ×\(rationCount)" : "Mochila",
            detail: "Saciedad",
            tint: ScreenKit.hunger
        )
        quickPlayButton.update(symbol: "gamecontroller.fill", title: "Jugar", detail: "Ánimo", tint: ScreenKit.rose)
        quickSleepButton.update(
            symbol: pet.isSleeping ? "sun.max.fill" : "moon.stars.fill",
            title: pet.isSleeping ? "Despertar" : "Dormir",
            detail: pet.isSleeping ? "Terminar descanso" : "Energía",
            tint: ScreenKit.sky
        )

        quickFeedButton.isEnabled = rationCount == 0 || gameManager.canUse(.ration)
        quickPlayButton.isEnabled = gameManager.canPlayMiniGame
        quickSleepButton.isEnabled = pet.isSleeping || (!pet.isGameOver && pet.energy < 100)

        if let expedition = gameManager.activeExpedition {
            expeditionsControl.update(
                symbolName: expedition.isReady() ? "shippingbox.fill" : "map.fill",
                title: expedition.isReady() ? "Botín listo" : "Expedición en curso",
                subtitle: expedition.isReady() ? "Reclama la recompensa de \(expedition.route.title)." : "\(expedition.route.title) · regresa en \(formatted(expedition.remainingTime()))",
                footnote: expedition.isReady() ? "TOCA PARA RECLAMAR" : nil,
                tint: expedition.isReady() ? ScreenKit.gold : ScreenKit.sky,
                selected: expedition.isReady()
            )
        } else {
            expeditionsControl.update(
                symbolName: "map.fill",
                title: "Expediciones",
                subtitle: "Envía a tu compañero a buscar tesoros.",
                tint: ScreenKit.sky
            )
        }

        hungerMeter.update(value: pet.hunger)
        happinessMeter.update(value: pet.happiness)
        energyMeter.update(value: pet.energy)
        updatePetAnimation(for: pet.mood)
    }

    private func careHint(for pet: PetModel) -> String {
        if let temporaryHint { return temporaryHint }
        if pet.isSleeping { return "Descansa. La energía se recupera poco a poco." }
        if pet.hunger < 35 { return "Tiene hambre. Una ración le devolverá las fuerzas." }
        if pet.energy < 30 { return "Está cansado. Déjalo dormir un rato." }
        if pet.happiness < 35 { return "Necesita un momento contigo. Juega una partida." }
        return "Todo marcha bien. ¿Qué aventura vivirán hoy?"
    }

    private func formatted(_ interval: TimeInterval) -> String {
        let seconds = max(0, Int(ceil(interval)))
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 { return "\(hours) h \(minutes) min" }
        return "\(minutes) min"
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
}

// MARK: - Status meter

private final class StatusMeterView: UIView {
    private var normalTint: UIColor = ScreenKit.accent
    private let titleLabel: UILabel = {
        let label = ScreenKit.label("", size: 11, color: ScreenKit.mutedText, weight: .semibold, textStyle: .caption1)
        label.textAlignment = .left
        return label
    }()
    private let iconView: UIImageView
    private let valueLabel: UILabel = {
        let label = ScreenKit.label("0%", size: 12, color: .white, weight: .semibold, textStyle: .caption1)
        label.textAlignment = .right
        return label
    }()
    private let progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.trackTintColor = UIColor.white.withAlphaComponent(0.08)
        progress.layer.cornerRadius = 4
        progress.clipsToBounds = true
        return progress
    }()

    init(title: String, symbol: String, tint: UIColor) {
        iconView = ScreenKit.symbolLabel(symbol, size: 12, color: tint, weight: .bold)
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        normalTint = tint
        progressView.progressTintColor = tint

        let labels = ScreenKit.horizontalStack([iconView, titleLabel, valueLabel], spacing: 7)
        labels.distribution = .fill
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        valueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        let contentStack = ScreenKit.stack([labels, progressView], spacing: 7)
        addSubview(contentStack)

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 7),
            iconView.widthAnchor.constraint(equalToConstant: 15)
        ])
        isAccessibilityElement = true
        accessibilityLabel = title
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no está disponible") }

    func update(value: Double) {
        let safeValue = min(100, max(0, value))
        valueLabel.text = "\(Int(safeValue))%"
        progressView.setProgress(Float(safeValue / 100), animated: true)
        progressView.progressTintColor = safeValue < 25 ? ScreenKit.danger : (safeValue < 50 ? ScreenKit.hunger : normalTint)
        accessibilityValue = "\(Int(safeValue)) por ciento"
    }
}

// MARK: - Quick action button

private final class QuickActionButton: UIControl {
    private let iconView: UIImageView
    private let titleLabel: UILabel
    private let detailLabel: UILabel
    private var tint: UIColor = ScreenKit.accent

    init(symbol: String, title: String) {
        iconView = ScreenKit.symbolLabel(symbol, size: 19, color: ScreenKit.accent)
        titleLabel = ScreenKit.label(title, size: 12.5, color: .white, weight: .semibold, textStyle: .caption1)
        detailLabel = ScreenKit.label("", size: 10, color: ScreenKit.faintText, textStyle: .caption2)

        super.init(frame: .zero)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.8
        detailLabel.textAlignment = .center
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = ScreenKit.panelElevated
        layer.cornerRadius = 16
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.withAlphaComponent(0.05).cgColor
        isAccessibilityElement = true
        accessibilityTraits = .button

        let stack = ScreenKit.stack([iconView, titleLabel, detailLabel], spacing: 5)
        stack.alignment = .center
        stack.isUserInteractionEnabled = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 84)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no está disponible") }

    func update(symbol: String, title: String, detail: String, tint: UIColor) {
        self.tint = tint
        iconView.image = ScreenKit.symbolImage(symbol, size: 19, color: tint)
        titleLabel.text = title
        detailLabel.text = detail
        accessibilityLabel = "\(title). \(detail)"
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.12) {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.97, y: 0.97) : .identity
            }
        }
    }

    override var isEnabled: Bool {
        didSet { alpha = isEnabled ? 1 : 0.4 }
    }
}

// MARK: - Daily quest row

private final class DailyQuestRowView: UIView {
    private let iconView: UIImageView = ScreenKit.symbolLabel("circle.fill", size: 11, color: ScreenKit.mint)
    private let titleLabel: UILabel = {
        let label = ScreenKit.label("", size: 13, color: .white, weight: .medium, textStyle: .subheadline)
        label.textAlignment = .left
        return label
    }()
    private let progressLabel: UILabel = {
        let label = ScreenKit.label("", size: 11, color: ScreenKit.mutedText, weight: .semibold, textStyle: .caption1)
        label.textAlignment = .right
        return label
    }()
    private let progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.trackTintColor = UIColor.white.withAlphaComponent(0.07)
        progress.progressTintColor = ScreenKit.mint
        progress.layer.cornerRadius = 2.5
        progress.clipsToBounds = true
        return progress
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false

        let header = ScreenKit.horizontalStack([iconView, titleLabel, progressLabel], spacing: 8)
        header.distribution = .fill
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        progressLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        let contentStack = ScreenKit.stack([header, progressView], spacing: 7)
        addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 4),
            iconView.widthAnchor.constraint(equalToConstant: 15)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no está disponible") }

    func update(_ quest: DailyQuest) {
        iconView.image = ScreenKit.symbolImage(quest.kind.symbolName, size: 11, color: quest.rewardClaimed ? ScreenKit.faintText : ScreenKit.mint)
        titleLabel.text = quest.kind.title
        titleLabel.textColor = quest.rewardClaimed ? ScreenKit.faintText : .white
        progressLabel.attributedText = quest.rewardClaimed
            ? ScreenKit.symbolText("checkmark.circle.fill", text: " +\(quest.kind.gilReward) Gil", size: 10.5, weight: .bold, color: ScreenKit.mint, textStyle: .caption2)
            : NSAttributedString(string: "\(min(quest.progress, quest.kind.target))/\(quest.kind.target)", attributes: [
                .font: ScreenKit.roundedFont(size: 11, weight: .semibold, textStyle: .caption1),
                .foregroundColor: ScreenKit.mutedText
            ])
        progressView.setProgress(Float(quest.progress) / Float(quest.kind.target), animated: true)
        progressView.progressTintColor = quest.rewardClaimed ? ScreenKit.faintText : ScreenKit.mint
        accessibilityLabel = quest.summary
        accessibilityValue = quest.rewardClaimed ? "Completada, recompensa recibida" : "\(quest.progress) de \(quest.kind.target)"
        isAccessibilityElement = true
    }
}
