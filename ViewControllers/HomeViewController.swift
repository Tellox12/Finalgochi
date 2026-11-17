import UIKit

final class HomeViewController: UIViewController {
    let gameManager: GameManager
    var onOpenActions: (() -> Void)?
    var onOpenInventory: (() -> Void)?
    var onOpenCharacterSheet: (() -> Void)?
    var onOpenShop: (() -> Void)?
    var onOpenSettings: (() -> Void)?
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
    private let nameLabel: UILabel = { ScreenKit.label("", size: 25, color: .white, weight: .bold) }()
    private let accessoryLabel: UILabel = { ScreenKit.label("", size: 13, color: ScreenKit.gold, weight: .semibold) }()
    private let sleepStatusLabel: UILabel = {
        ScreenKit.label("", size: 11, color: ScreenKit.mint, weight: .bold)
    }()
    private let petCard: UIView = { ScreenKit.card() }()
    private let statsCard: UIView = { ScreenKit.card() }()
    private let statsTitleLabel: UILabel = {
        let label = ScreenKit.label("ESTADO DEL COMPAÑERO", size: 12, color: ScreenKit.mutedText, weight: .bold)
        label.textAlignment = .left
        return label
    }()

    private let hungerMeter: StatusMeterView = {
        StatusMeterView(title: "HAMBRE", tint: UIColor(red: 1, green: 0.61, blue: 0.35, alpha: 1))
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

    private lazy var headerStack: UIStackView = {
        let stack = ScreenKit.horizontalStack([sectionLabel, gilLabel])
        stack.alignment = .center
        return stack
    }()
    private lazy var petCardStack: UIStackView = {
        let stack = ScreenKit.stack([petSpriteView, nameLabel, accessoryLabel, sleepStatusLabel], spacing: 6)
        stack.alignment = .center
        return stack
    }()
    private lazy var statsStack: UIStackView = {
        ScreenKit.stack([statsTitleLabel, hungerMeter, happinessMeter, energyMeter], spacing: 13)
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
        ScreenKit.stack([headerStack, petCard, statsCard, actionsButton, utilityRowOne, utilityRowTwo], spacing: 15)
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

    private func configureCards() {
        petCard.addSubview(petCardStack)
        statsCard.addSubview(statsStack)

        NSLayoutConstraint.activate([
            petCardStack.topAnchor.constraint(equalTo: petCard.topAnchor, constant: 18),
            petCardStack.leadingAnchor.constraint(equalTo: petCard.leadingAnchor, constant: 20),
            petCardStack.trailingAnchor.constraint(equalTo: petCard.trailingAnchor, constant: -20),
            petCardStack.bottomAnchor.constraint(equalTo: petCard.bottomAnchor, constant: -18),
            petCard.heightAnchor.constraint(greaterThanOrEqualToConstant: 210),
            petSpriteView.widthAnchor.constraint(equalToConstant: 148),
            petSpriteView.heightAnchor.constraint(equalToConstant: 148),
            statsStack.topAnchor.constraint(equalTo: statsCard.topAnchor, constant: 18),
            statsStack.leadingAnchor.constraint(equalTo: statsCard.leadingAnchor, constant: 18),
            statsStack.trailingAnchor.constraint(equalTo: statsCard.trailingAnchor, constant: -18),
            statsStack.bottomAnchor.constraint(equalTo: statsCard.bottomAnchor, constant: -18)
        ])
    }

    private func configureButtons() {
        actionsButton.addTarget(self, action: #selector(openActions), for: .touchUpInside)
        inventoryButton.addTarget(self, action: #selector(openInventory), for: .touchUpInside)
        sheetButton.addTarget(self, action: #selector(openSheet), for: .touchUpInside)
        shopButton.addTarget(self, action: #selector(openShop), for: .touchUpInside)
        settingsButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)

        actionsButton.backgroundColor = UIColor(red: 0.19, green: 0.37, blue: 0.55, alpha: 1)
        actionsButton.layer.borderWidth = 1
        actionsButton.layer.borderColor = ScreenKit.accent.withAlphaComponent(0.35).cgColor
        NSLayoutConstraint.activate([
            actionsButton.heightAnchor.constraint(equalToConstant: 58)
        ])
    }

    private func refresh() {
        guard let pet = gameManager.pet else { return }
        petSpriteView.kind = pet.kind
        nameLabel.text = "\(pet.kind.displayName)  ·  NIVEL \(pet.level)"
        accessoryLabel.text = gameManager.equippedAccessory.map { "\($0.emoji)  \($0.name) equipado" } ?? "SIN ACCESORIO EQUIPADO"
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
}

private final class StatusMeterView: UIView {
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
        accessibilityElement = true
        accessibilityLabel = title
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no está disponible") }

    func update(value: Double) {
        let safeValue = min(100, max(0, value))
        valueLabel.text = "\(Int(safeValue))%"
        progressView.setProgress(Float(safeValue / 100), animated: true)
        accessibilityValue = "\(Int(safeValue)) por ciento"
    }
}
