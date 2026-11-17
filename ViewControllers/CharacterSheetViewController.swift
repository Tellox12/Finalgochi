import UIKit

final class CharacterSheetViewController: UIViewController {
    let gameManager: GameManager
    var onClose: (() -> Void)?

    private let titleLabel: UILabel = {
        ScreenKit.label("CRÓNICA DEL COMPAÑERO", size: 12, color: ScreenKit.gold, weight: .bold)
    }()
    private let spriteView: PixelPetSpriteView = {
        let view = PixelPetSpriteView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private let nameLabel: UILabel = { ScreenKit.label("", size: 25, color: .white, weight: .bold) }()
    private let levelLabel: UILabel = { ScreenKit.label("", size: 13, color: ScreenKit.accent, weight: .semibold) }()
    private let experienceLabel: UILabel = {
        let label = ScreenKit.label("", size: 12, color: ScreenKit.mutedText, weight: .medium)
        label.textAlignment = .left
        return label
    }()
    private let experienceProgress: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.trackTintColor = UIColor.white.withAlphaComponent(0.10)
        progress.progressTintColor = ScreenKit.gold
        return progress
    }()
    private let hungerRow: SheetStatRow = { SheetStatRow(title: "Hambre", tint: UIColor(red: 1, green: 0.61, blue: 0.35, alpha: 1)) }()
    private let happinessRow: SheetStatRow = { SheetStatRow(title: "Felicidad", tint: UIColor(red: 1, green: 0.45, blue: 0.64, alpha: 1)) }()
    private let energyRow: SheetStatRow = { SheetStatRow(title: "Energía", tint: ScreenKit.accent) }()
    private let accessoryLabel: UILabel = {
        let label = ScreenKit.label("", size: 14, color: .white)
        label.textAlignment = .left
        return label
    }()
    private let inventoryLabel: UILabel = { ScreenKit.label("", size: 13, color: ScreenKit.mutedText) }()
    private let characterCard: UIView = { ScreenKit.card() }()
    private let statsCard: UIView = { ScreenKit.card() }()
    private let belongingsCard: UIView = { ScreenKit.card() }()
    private let closeButton: UIButton = { ScreenKit.button("Volver al hábitat") }()

    private lazy var characterStack: UIStackView = {
        let stack = ScreenKit.stack([spriteView, nameLabel, levelLabel, experienceLabel, experienceProgress], spacing: 8)
        stack.alignment = .center
        return stack
    }()
    private lazy var statsStack: UIStackView = {
        ScreenKit.stack([hungerRow, happinessRow, energyRow], spacing: 14)
    }()
    private lazy var belongingsStack: UIStackView = {
        ScreenKit.stack([accessoryLabel, inventoryLabel], spacing: 10)
    }()
    private lazy var contentStack: UIStackView = {
        ScreenKit.stack([titleLabel, characterCard, statsCard, belongingsCard, closeButton], spacing: 15)
    }()

    init(gameManager: GameManager) {
        self.gameManager = gameManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no está disponible") }

    override func viewDidLoad() {
        super.viewDidLoad()
        ScreenKit.configure(self, title: "Ficha")
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        characterCard.addSubview(characterStack)
        statsCard.addSubview(statsStack)
        belongingsCard.addSubview(belongingsStack)
        NSLayoutConstraint.activate([
            characterStack.topAnchor.constraint(equalTo: characterCard.topAnchor, constant: 16),
            characterStack.leadingAnchor.constraint(equalTo: characterCard.leadingAnchor, constant: 18),
            characterStack.trailingAnchor.constraint(equalTo: characterCard.trailingAnchor, constant: -18),
            characterStack.bottomAnchor.constraint(equalTo: characterCard.bottomAnchor, constant: -16),
            spriteView.widthAnchor.constraint(equalToConstant: 108),
            spriteView.heightAnchor.constraint(equalToConstant: 108),
            experienceProgress.widthAnchor.constraint(equalTo: characterStack.widthAnchor),
            experienceProgress.heightAnchor.constraint(equalToConstant: 7),
            statsStack.topAnchor.constraint(equalTo: statsCard.topAnchor, constant: 18),
            statsStack.leadingAnchor.constraint(equalTo: statsCard.leadingAnchor, constant: 18),
            statsStack.trailingAnchor.constraint(equalTo: statsCard.trailingAnchor, constant: -18),
            statsStack.bottomAnchor.constraint(equalTo: statsCard.bottomAnchor, constant: -18),
            belongingsStack.topAnchor.constraint(equalTo: belongingsCard.topAnchor, constant: 18),
            belongingsStack.leadingAnchor.constraint(equalTo: belongingsCard.leadingAnchor, constant: 18),
            belongingsStack.trailingAnchor.constraint(equalTo: belongingsCard.trailingAnchor, constant: -18),
            belongingsStack.bottomAnchor.constraint(equalTo: belongingsCard.bottomAnchor, constant: -18)
        ])
        refresh()
        ScreenKit.installScrollable(contentStack, in: self)
        gameManager.onChange = { [weak self] in self?.refresh() }
    }

    private func refresh() {
        guard let pet = gameManager.pet else { return }
        spriteView.kind = pet.kind
        spriteView.mood = pet.mood
        spriteView.equippedItems = gameManager.activeEquipment
        nameLabel.text = pet.kind.displayName
        levelLabel.text = "NIVEL \(pet.level)  ·  \(pet.mood.title)"
        experienceLabel.text = "EXPERIENCIA  \(pet.experience) / \(pet.nextLevelExperience)"
        experienceProgress.setProgress(Float(pet.experience) / Float(max(1, pet.nextLevelExperience)), animated: true)
        hungerRow.update(value: pet.hunger)
        happinessRow.update(value: pet.happiness)
        energyRow.update(value: pet.energy)
        let equippedSpellNames = gameManager.equippedMateria.map(\.name).joined(separator: " · ")
        accessoryLabel.text = "EQUIPO   \(gameManager.equipmentSummary)\nMATERIAS   \(equippedSpellNames.isEmpty ? "Ninguna" : equippedSpellNames)   ·   PM \(gameManager.magicPoints)/\(GameManager.maximumMagicPoints)\n◈ \(gameManager.gil) GIL"
        inventoryLabel.text = "MOCHILA\n" + ConsumableItem.allCases
            .map { "\($0.emoji)  \($0.name)     ×\(gameManager.inventory[$0, default: 0])" }
            .joined(separator: "\n")
        inventoryLabel.textAlignment = .left
    }

    @objc private func close() { onClose?() }
}

private final class SheetStatRow: UIView {
    private let titleLabel: UILabel = {
        let label = ScreenKit.label("", size: 13, color: ScreenKit.mutedText, weight: .semibold)
        label.textAlignment = .left
        return label
    }()
    private let valueLabel: UILabel = {
        let label = ScreenKit.label("0%", size: 13, color: .white, weight: .bold)
        label.textAlignment = .right
        return label
    }()
    private let progressView: UIProgressView = {
        let view = UIProgressView(progressViewStyle: .default)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.trackTintColor = UIColor.white.withAlphaComponent(0.10)
        return view
    }()
    private lazy var labelsStack: UIStackView = { ScreenKit.horizontalStack([titleLabel, valueLabel]) }()
    private lazy var contentStack: UIStackView = { ScreenKit.stack([labelsStack, progressView], spacing: 7) }()

    init(title: String, tint: UIColor) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title.uppercased()
        progressView.progressTintColor = tint
        addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 7)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no está disponible") }

    func update(value: Double) {
        let safeValue = min(100, max(0, value))
        valueLabel.text = "\(Int(safeValue))%"
        progressView.setProgress(Float(safeValue / 100), animated: true)
    }
}
