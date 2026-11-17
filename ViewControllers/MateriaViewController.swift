import UIKit

final class MateriaViewController: UIViewController {
    let gameManager: GameManager
    var onClose: (() -> Void)?
    var onOpenShop: (() -> Void)?

    private let titleLabel: UILabel = { ScreenKit.label("Núcleo de materias", size: 27, color: ScreenKit.accent, weight: .bold) }()
    private let magicPointsLabel: UILabel = { ScreenKit.label("", size: 16, color: ScreenKit.gold, weight: .bold) }()
    private let slotsLabel: UILabel = { ScreenKit.label("", size: 12, color: ScreenKit.mutedText) }()
    private let messageLabel: UILabel = { ScreenKit.label("Equipa hasta dos materias. Sus pasivas se activan al equiparlas.", size: 13, color: ScreenKit.mutedText) }()
    private let shopButton: UIButton = { ScreenKit.button("Visitar bazar  ›") }()
    private let closeButton: UIButton = { ScreenKit.button("Volver al hábitat") }()
    private let cards: [Materia: MateriaCardView] = {
        Dictionary(uniqueKeysWithValues: Materia.allCases.map { ($0, MateriaCardView(materia: $0)) })
    }()
    private lazy var cardsStack: UIStackView = { ScreenKit.stack([], spacing: 13) }()
    private lazy var contentStack: UIStackView = {
        ScreenKit.stack([titleLabel, magicPointsLabel, slotsLabel, cardsStack, messageLabel, shopButton, closeButton], spacing: 14)
    }()

    init(gameManager: GameManager) {
        self.gameManager = gameManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no está disponible") }

    override func viewDidLoad() {
        super.viewDidLoad()
        ScreenKit.configure(self, title: "Materias")
        for materia in Materia.allCases {
            guard let card = cards[materia] else { continue }
            card.onToggle = { [weak self] in
                guard let self else { return }
                self.toggle(materia)
            }
            card.onCast = { [weak self] in
                guard let self else { return }
                self.cast(materia)
            }
            cardsStack.addArrangedSubview(card)
        }
        shopButton.addTarget(self, action: #selector(openShop), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        ScreenKit.installScrollable(contentStack, in: self)
        gameManager.onChange = { [weak self] in self?.refresh() }
        refresh()
    }

    private func refresh() {
        magicPointsLabel.text = "✦  PM  \(gameManager.magicPoints) / \(GameManager.maximumMagicPoints)"
        slotsLabel.text = "RANURAS ACTIVAS  \(gameManager.equippedMateria.count) / \(GameManager.maximumEquippedMateria)   ·   Recuperas 1 PM cada 3 min"
        let sleeping = gameManager.pet?.isSleeping ?? false
        for materia in Materia.allCases {
            cards[materia]?.update(
                isOwned: gameManager.ownedMateria.contains(materia),
                isEquipped: gameManager.equippedMateria.contains(materia),
                equippedCount: gameManager.equippedMateria.count,
                currentMagicPoints: gameManager.magicPoints,
                canCast: gameManager.canCastMateria(materia),
                isSleeping: sleeping
            )
        }
    }

    private func toggle(_ materia: Materia) {
        guard gameManager.ownedMateria.contains(materia) else {
            messageLabel.text = "Consigue esta materia en el bazar."
            return
        }
        if gameManager.toggleMateria(materia) {
            messageLabel.text = gameManager.equippedMateria.contains(materia)
                ? "\(materia.name) equipada: su efecto pasivo está activo."
                : "\(materia.name) retirada de las ranuras."
        } else {
            messageLabel.text = "Las dos ranuras están ocupadas. Retira una materia primero."
        }
        refresh()
    }

    private func cast(_ materia: Materia) {
        guard gameManager.castMateria(materia) else {
            if gameManager.pet?.isSleeping == true {
                messageLabel.text = "Tu compañero está durmiendo; espera a que despierte para lanzar magia."
            } else if !gameManager.equippedMateria.contains(materia) {
                messageLabel.text = "Equipa la materia antes de lanzar su habilidad."
            } else if gameManager.magicPoints >= materia.magicCost {
                messageLabel.text = "Esa habilidad no hace falta ahora; sus estadísticas ya están al máximo."
            } else {
                messageLabel.text = "No tienes PM suficientes. Se recuperan con el tiempo."
            }
            refresh()
            return
        }
        messageLabel.text = "\(materia.emoji)  ¡\(materia.name) lanzada!  −\(materia.magicCost) PM."
        refresh()
    }

    @objc private func openShop() { onOpenShop?() }
    @objc private func close() { onClose?() }
}

private final class MateriaCardView: UIView {
    private let materia: Materia
    var onToggle: (() -> Void)?
    var onCast: (() -> Void)?

    private let nameLabel: UILabel = {
        let label = ScreenKit.label("", size: 18, color: .white, weight: .bold)
        label.textAlignment = .left
        return label
    }()
    private let costLabel: UILabel = {
        let label = ScreenKit.label("", size: 11, color: ScreenKit.gold, weight: .bold)
        label.textAlignment = .right
        return label
    }()
    private let descriptionLabel: UILabel = {
        let label = ScreenKit.label("", size: 13, color: ScreenKit.mutedText)
        label.textAlignment = .left
        return label
    }()
    private let passiveLabel: UILabel = {
        let label = ScreenKit.label("", size: 11, color: ScreenKit.mint, weight: .medium)
        label.textAlignment = .left
        return label
    }()
    private let equipButton: UIButton = { ScreenKit.button("Equipar") }()
    private let castButton: UIButton = { ScreenKit.button("Lanzar") }()
    private lazy var headerStack: UIStackView = { ScreenKit.horizontalStack([nameLabel, costLabel]) }()
    private lazy var buttonStack: UIStackView = {
        let stack = ScreenKit.horizontalStack([equipButton, castButton])
        stack.distribution = .fillEqually
        return stack
    }()
    private lazy var contentStack: UIStackView = {
        ScreenKit.stack([headerStack, descriptionLabel, passiveLabel, buttonStack], spacing: 9)
    }()

    init(materia: Materia) {
        self.materia = materia
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = ScreenKit.panel
        layer.cornerRadius = 18
        layer.borderWidth = 1
        layer.borderColor = ScreenKit.accent.withAlphaComponent(0.17).cgColor
        nameLabel.text = "\(materia.emoji)  \(materia.name)"
        descriptionLabel.text = materia.description
        passiveLabel.text = "PASIVA  ·  \(materia.passiveDescription)"
        equipButton.addTarget(self, action: #selector(toggleTapped), for: .touchUpInside)
        castButton.addTarget(self, action: #selector(castTapped), for: .touchUpInside)
        addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: 15),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -15),
            equipButton.heightAnchor.constraint(equalToConstant: 44),
            castButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no está disponible") }

    func update(isOwned: Bool, isEquipped: Bool, equippedCount: Int, currentMagicPoints: Int, canCast: Bool, isSleeping: Bool) {
        costLabel.text = "\(materia.magicCost) PM"
        equipButton.isEnabled = isOwned && (isEquipped || equippedCount < GameManager.maximumEquippedMateria)
        equipButton.alpha = equipButton.isEnabled ? 1 : 0.45
        castButton.isEnabled = isOwned && isEquipped && canCast && !isSleeping
        castButton.alpha = castButton.isEnabled ? 1 : 0.45
        ScreenKit.setTitle(isOwned ? (isEquipped ? "Retirar" : "Equipar") : "En el bazar", on: equipButton)
        let castTitle: String
        if isSleeping {
            castTitle = "Está descansando"
        } else if currentMagicPoints < materia.magicCost {
            castTitle = "Faltan PM"
        } else if !canCast {
            castTitle = "Al máximo"
        } else {
            castTitle = "Lanzar  ·  \(materia.magicCost) PM"
        }
        ScreenKit.setTitle(castTitle, on: castButton)
        ScreenKit.setBackground(isEquipped ? UIColor(red: 0.16, green: 0.42, blue: 0.36, alpha: 1) : ScreenKit.panel, on: equipButton)
        let state = isOwned ? (isEquipped ? "EQUIPADA" : "EN COLECCIÓN") : "DISPONIBLE EN BAZAR"
        passiveLabel.text = "\(state)  ·  \(materia.passiveDescription)"
    }

    @objc private func toggleTapped() { onToggle?() }
    @objc private func castTapped() { onCast?() }
}
