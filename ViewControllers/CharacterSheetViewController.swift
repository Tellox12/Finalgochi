import UIKit

final class CharacterSheetViewController: UIViewController {
    let gameManager: GameManager
    var onClose: (() -> Void)?

    private var observerToken: UUID?

    private let titleLabel = ScreenKit.sectionTitle("CRÓNICA DEL COMPAÑERO", color: ScreenKit.gold)
    private let spriteView: PixelPetSpriteView = {
        let view = PixelPetSpriteView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private let nameLabel = ScreenKit.label("", size: 25, color: .white, weight: .bold, textStyle: .title2)
    private let levelLabel: UILabel = {
        let label = ScreenKit.label("", size: 12.5, color: ScreenKit.accent, weight: .semibold, textStyle: .subheadline)
        label.textAlignment = .left
        return label
    }()
    private let nameTextField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.backgroundColor = ScreenKit.background.withAlphaComponent(0.7)
        field.textColor = .white
        field.tintColor = ScreenKit.accent
        field.font = ScreenKit.roundedFont(size: 16, weight: .medium)
        field.adjustsFontForContentSizeCategory = true
        field.textAlignment = .center
        field.autocorrectionType = .no
        field.autocapitalizationType = .words
        field.returnKeyType = .done
        field.clearButtonMode = .whileEditing
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.white.withAlphaComponent(0.1).cgColor
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
        field.leftViewMode = .always
        field.attributedPlaceholder = NSAttributedString(
            string: "Nombre del compañero",
            attributes: [.foregroundColor: ScreenKit.faintText]
        )
        field.accessibilityLabel = "Nombre de la mascota"
        return field
    }()
    private let renameButton = ScreenKit.button("Guardar nombre", symbol: "checkmark", style: .primary)
    private let renameFeedbackLabel: UILabel = {
        let label = ScreenKit.label("Puedes usar hasta 16 caracteres", size: 11, color: ScreenKit.mutedText, textStyle: .caption1)
        label.textAlignment = .left
        return label
    }()
    private let experienceLabel: UILabel = {
        let label = ScreenKit.label("", size: 11.5, color: ScreenKit.mutedText, weight: .medium, textStyle: .caption1)
        label.textAlignment = .left
        return label
    }()
    private let experienceProgress: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.trackTintColor = UIColor.white.withAlphaComponent(0.08)
        progress.progressTintColor = ScreenKit.gold
        progress.layer.cornerRadius = 3
        progress.clipsToBounds = true
        return progress
    }()
    private let hungerRow = SheetStatRow(title: "Saciedad", symbol: "fork.knife", tint: ScreenKit.hunger)
    private let happinessRow = SheetStatRow(title: "Ánimo", symbol: "heart.fill", tint: ScreenKit.rose)
    private let energyRow = SheetStatRow(title: "Energía", symbol: "bolt.fill", tint: ScreenKit.sky)
    private let belongingsLabel: UILabel = {
        let label = ScreenKit.label("", size: 13, color: .white)
        label.textAlignment = .left
        return label
    }()
    private let collectionLabel: UILabel = {
        let label = ScreenKit.label("", size: 13, color: .white)
        label.textAlignment = .left
        return label
    }()
    private let achievementsStack: UIStackView = { ScreenKit.stack([], spacing: 8) }()
    private let characterCard: UIView = { ScreenKit.card() }()
    private let statsCard: UIView = { ScreenKit.card() }()
    private let belongingsCard: UIView = { ScreenKit.card() }()
    private let collectionCard: UIView = { ScreenKit.card() }()
    private let closeButton = ScreenKit.button("Volver al hábitat", symbol: "chevron.left", style: .ghost)

    private lazy var characterStack: UIStackView = {
        let stack = ScreenKit.stack([spriteView, nameLabel, levelLabel, nameTextField, renameButton, renameFeedbackLabel, experienceLabel, experienceProgress], spacing: 8)
        stack.alignment = .center
        return stack
    }()
    private lazy var statsStack: UIStackView = {
        ScreenKit.stack([ScreenKit.sectionTitle("ESTADO"), hungerRow, happinessRow, energyRow], spacing: 13)
    }()
    private lazy var belongingsStack: UIStackView = {
        ScreenKit.stack([ScreenKit.sectionTitle("PERTENENCIAS"), belongingsLabel], spacing: 10)
    }()
    private lazy var collectionStack: UIStackView = {
        ScreenKit.stack([ScreenKit.sectionTitle("COLECCIÓN Y LOGROS"), collectionLabel, ScreenKit.divider(), achievementsStack], spacing: 11)
    }()
    private lazy var contentStack: UIStackView = {
        ScreenKit.stack([titleLabel, characterCard, statsCard, belongingsCard, collectionCard, closeButton], spacing: 14)
    }()

    init(gameManager: GameManager) {
        self.gameManager = gameManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no está disponible") }

    override func viewDidLoad() {
        super.viewDidLoad()
        ScreenKit.configure(self, title: "Ficha")
        titleLabel.textAlignment = .left
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        renameButton.addTarget(self, action: #selector(saveName), for: .touchUpInside)
        nameTextField.delegate = self

        characterCard.addSubview(characterStack)
        statsCard.addSubview(statsStack)
        belongingsCard.addSubview(belongingsStack)
        collectionCard.addSubview(collectionStack)
        for achievement in GameAchievement.allCases {
            let row = AchievementRowView(achievement: achievement)
            achievementsStack.addArrangedSubview(row)
        }

        NSLayoutConstraint.activate([
            characterStack.topAnchor.constraint(equalTo: characterCard.topAnchor, constant: 18),
            characterStack.leadingAnchor.constraint(equalTo: characterCard.leadingAnchor, constant: 18),
            characterStack.trailingAnchor.constraint(equalTo: characterCard.trailingAnchor, constant: -18),
            characterStack.bottomAnchor.constraint(equalTo: characterCard.bottomAnchor, constant: -18),
            spriteView.widthAnchor.constraint(equalToConstant: 108),
            spriteView.heightAnchor.constraint(equalToConstant: 108),
            nameTextField.heightAnchor.constraint(equalToConstant: 46),
            nameTextField.widthAnchor.constraint(equalTo: characterStack.widthAnchor),
            renameButton.widthAnchor.constraint(equalTo: characterStack.widthAnchor),
            renameFeedbackLabel.widthAnchor.constraint(equalTo: characterStack.widthAnchor),
            experienceLabel.widthAnchor.constraint(equalTo: characterStack.widthAnchor),
            experienceProgress.widthAnchor.constraint(equalTo: characterStack.widthAnchor),
            experienceProgress.heightAnchor.constraint(equalToConstant: 6),
            statsStack.topAnchor.constraint(equalTo: statsCard.topAnchor, constant: 18),
            statsStack.leadingAnchor.constraint(equalTo: statsCard.leadingAnchor, constant: 18),
            statsStack.trailingAnchor.constraint(equalTo: statsCard.trailingAnchor, constant: -18),
            statsStack.bottomAnchor.constraint(equalTo: statsCard.bottomAnchor, constant: -18),
            belongingsStack.topAnchor.constraint(equalTo: belongingsCard.topAnchor, constant: 18),
            belongingsStack.leadingAnchor.constraint(equalTo: belongingsCard.leadingAnchor, constant: 18),
            belongingsStack.trailingAnchor.constraint(equalTo: belongingsCard.trailingAnchor, constant: -18),
            belongingsStack.bottomAnchor.constraint(equalTo: belongingsCard.bottomAnchor, constant: -18),
            collectionStack.topAnchor.constraint(equalTo: collectionCard.topAnchor, constant: 18),
            collectionStack.leadingAnchor.constraint(equalTo: collectionCard.leadingAnchor, constant: 18),
            collectionStack.trailingAnchor.constraint(equalTo: collectionCard.trailingAnchor, constant: -18),
            collectionStack.bottomAnchor.constraint(equalTo: collectionCard.bottomAnchor, constant: -18)
        ])

        ScreenKit.installScrollable(contentStack, in: self)
        observerToken = gameManager.addObserver { [weak self] in self?.refresh() }
        refresh()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        gameManager.updateElapsedTime()
        refresh()
    }

    deinit { gameManager.removeObserver(observerToken) }

    private func refresh() {
        guard let pet = gameManager.pet else { return }
        spriteView.kind = pet.kind
        spriteView.mood = pet.mood
        spriteView.evolutionStage = EvolutionStage(level: pet.level)
        spriteView.equippedItems = gameManager.activeEquipment
        nameLabel.text = pet.name
        let evolution = EvolutionStage(level: pet.level)
        levelLabel.text = "\(pet.kind.displayName.uppercased())  ·  NIVEL \(pet.level)\n\(evolution.title)  ·  \(pet.mood.title)"
        if !nameTextField.isFirstResponder { nameTextField.text = pet.name }
        experienceLabel.text = "EXPERIENCIA  \(pet.experience) / \(pet.nextLevelExperience)"
        experienceProgress.setProgress(Float(pet.experience) / Float(max(1, pet.nextLevelExperience)), animated: true)
        hungerRow.update(value: pet.hunger)
        happinessRow.update(value: pet.happiness)
        energyRow.update(value: pet.energy)

        let spellNames = gameManager.equippedMateria.map(\.name).joined(separator: " · ")
        let streakUnit = gameManager.dailyStreak.days == 1 ? "día" : "días"
        belongingsLabel.attributedText = NSMutableAttributedString(attributedString: lines([
            ("person.crop.circle.fill", "Equipo", gameManager.equipmentSummary),
            ("circle.hexagongrid.fill", "Materias", spellNames.isEmpty ? "Ninguna" : spellNames),
            ("sparkles", "Puntos de materia", "\(gameManager.magicPoints) / \(GameManager.maximumMagicPoints)"),
            ("diamond.fill", "Gil", "\(gameManager.gil)"),
            ("flame.fill", "Racha de cuidado", "\(gameManager.dailyStreak.days) \(streakUnit) · recompensa de hoy: \(gameManager.dailyStreak.lastReward) Gil"),
            ("shippingbox.fill", "Mochila", ConsumableItem.allCases.map { "\($0.name) ×\(gameManager.inventory[$0, default: 0])" }.joined(separator: "   ·   "))
        ]))

        let discovered = PetKind.allCases.filter { gameManager.progression.discoveredPets.contains($0) }
        let decor = gameManager.progression.equippedDecoration?.name ?? "Sin decoración equipada"
        collectionLabel.attributedText = lines([
            ("book.closed.fill", "Compañeros descubiertos", "\(discovered.count) / \(PetKind.allCases.count)"),
            ("house.fill", "Hábitat", "\(gameManager.progression.ownedDecorations.count) / \(HabitatDecoration.allCases.count) · \(decor)")
        ])

        for subview in achievementsStack.arrangedSubviews {
            guard let row = subview as? AchievementRowView else { continue }
            row.update(unlocked: gameManager.progression.unlockedAchievements.contains(row.achievement))
        }
    }

    private func lines(_ entries: [(String, String, String)]) -> NSAttributedString {
        let result = NSMutableAttributedString()
        for (index, entry) in entries.enumerated() {
            result.append(ScreenKit.symbolText(
                entry.0,
                text: "  \(entry.1)",
                size: 12.5,
                weight: .semibold,
                color: ScreenKit.accent,
                symbolColor: ScreenKit.accent,
                textStyle: .subheadline
            ))
            result.append(NSAttributedString(
                string: "\n\(entry.2)",
                attributes: [
                    .font: ScreenKit.roundedFont(size: 13, weight: .regular, textStyle: .subheadline),
                    .foregroundColor: UIColor.white
                ]
            ))
            if index < entries.count - 1 {
                result.append(NSAttributedString(string: "\n"))
            }
        }
        return result
    }

    @objc private func close() { onClose?() }

    @objc private func saveName() {
        guard let proposedName = nameTextField.text,
              gameManager.renamePet(to: proposedName) else {
            renameFeedbackLabel.text = "Escribe un nombre distinto para guardarlo."
            renameFeedbackLabel.textColor = ScreenKit.hunger
            return
        }
        nameTextField.resignFirstResponder()
        renameFeedbackLabel.text = "Nombre actualizado."
        renameFeedbackLabel.textColor = ScreenKit.mint
    }
}

extension CharacterSheetViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        saveName()
        return true
    }
}

// MARK: - Rows

private final class SheetStatRow: UIView {
    private let titleLabel: UILabel = {
        let label = ScreenKit.label("", size: 12, color: ScreenKit.mutedText, weight: .semibold, textStyle: .caption1)
        label.textAlignment = .left
        return label
    }()
    private let iconView: UIImageView
    private let valueLabel: UILabel = {
        let label = ScreenKit.label("0%", size: 12, color: .white, weight: .bold, textStyle: .caption1)
        label.textAlignment = .right
        return label
    }()
    private let progressView: UIProgressView = {
        let view = UIProgressView(progressViewStyle: .default)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.trackTintColor = UIColor.white.withAlphaComponent(0.08)
        view.layer.cornerRadius = 3
        view.clipsToBounds = true
        return view
    }()

    init(title: String, symbol: String, tint: UIColor) {
        iconView = ScreenKit.symbolLabel(symbol, size: 11, color: tint, weight: .bold)
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title.uppercased()
        progressView.progressTintColor = tint
        let labels = ScreenKit.horizontalStack([iconView, titleLabel, valueLabel], spacing: 7)
        labels.distribution = .fill
        let contentStack = ScreenKit.stack([labels, progressView], spacing: 7)
        addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 6),
            iconView.widthAnchor.constraint(equalToConstant: 15)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no está disponible") }

    func update(value: Double) {
        let safeValue = min(100, max(0, value))
        valueLabel.text = "\(Int(safeValue))%"
        progressView.setProgress(Float(safeValue / 100), animated: true)
    }
}

private final class AchievementRowView: UIView {
    let achievement: GameAchievement
    private let iconView: UIImageView
    private let titleLabel: UILabel = {
        let label = ScreenKit.label("", size: 12.5, color: .white, weight: .semibold, textStyle: .subheadline)
        label.textAlignment = .left
        return label
    }()
    private let detailLabel: UILabel = {
        let label = ScreenKit.label("", size: 11, color: ScreenKit.mutedText, textStyle: .caption1)
        label.textAlignment = .left
        return label
    }()
    private let rewardLabel: UILabel = {
        let label = ScreenKit.label("", size: 10.5, color: ScreenKit.gold, weight: .bold, textStyle: .caption2)
        label.textAlignment = .right
        return label
    }()

    init(achievement: GameAchievement) {
        self.achievement = achievement
        iconView = ScreenKit.symbolLabel(achievement.symbolName, size: 13, color: ScreenKit.faintText)
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = achievement.title
        detailLabel.text = achievement.detail
        let text = ScreenKit.stack([titleLabel, detailLabel], spacing: 2)
        let row = ScreenKit.horizontalStack([iconView, text, rewardLabel], spacing: 10)
        row.distribution = .fill
        addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            row.leadingAnchor.constraint(equalTo: leadingAnchor),
            row.trailingAnchor.constraint(equalTo: trailingAnchor),
            row.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
            iconView.widthAnchor.constraint(equalToConstant: 20)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no está disponible") }

    func update(unlocked: Bool) {
        iconView.image = ScreenKit.symbolImage(unlocked ? "checkmark.seal.fill" : achievement.symbolName, size: 13, color: unlocked ? ScreenKit.mint : ScreenKit.faintText)
        titleLabel.textColor = unlocked ? .white : ScreenKit.mutedText
        rewardLabel.text = unlocked ? "COMPLETADO" : "+\(achievement.reward) GIL"
        rewardLabel.textColor = unlocked ? ScreenKit.mint : ScreenKit.faintText
    }
}
