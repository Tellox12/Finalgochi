import UIKit

final class MateriaViewController: UIViewController {
    let gameManager: GameManager
    var onClose: (() -> Void)?
    var onOpenShop: (() -> Void)?

    private var observerToken: UUID?

    private let titleLabel = ScreenKit.label("Núcleo de materias", size: 27, color: .white, weight: .bold, textStyle: .largeTitle)
    private let magicPointsLabel = ScreenKit.pill("100 / 100 PM", color: ScreenKit.sky)
    private let slotsLabel: UILabel = {
        let label = ScreenKit.label("", size: 12, color: ScreenKit.mutedText, textStyle: .caption1)
        label.textAlignment = .left
        return label
    }()
    private let messageLabel: UILabel = {
        let label = ScreenKit.label("Equipa hasta dos materias. Sus pasivas se activan al equiparlas.", size: 12.5, color: ScreenKit.mutedText)
        label.textAlignment = .left
        return label
    }()
    private let shopButton = MenuCardControl()
    private let closeButton = ScreenKit.button("Volver al hábitat", symbol: "chevron.left", style: .ghost)
    private let cards: [Materia: MateriaCardView] = {
        Dictionary(uniqueKeysWithValues: Materia.allCases.map { ($0, MateriaCardView(materia: $0)) })
    }()
    private lazy var cardsStack: UIStackView = { ScreenKit.stack([], spacing: 12) }()
    private lazy var topRow: UIStackView = {
        let stack = ScreenKit.headerRow(title: slotsLabel, trailing: [magicPointsLabel])
        stack.distribution = .fill
        return stack
    }()
    private lazy var contentStack: UIStackView = {
        ScreenKit.stack([titleLabel, topRow, cardsStack, messageLabel, shopButton, closeButton], spacing: 14)
    }()

    init(gameManager: GameManager) {
        self.gameManager = gameManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no está disponible") }

    override func viewDidLoad() {
        super.viewDidLoad()
        ScreenKit.configure(self, title: "Materias")
        titleLabel.textAlignment = .left
        for materia in Materia.allCases {
            guard let card = cards[materia] else { continue }
            card.onToggle = { [weak self] in self?.toggle(materia) }
            card.onCast = { [weak self] in self?.cast(materia) }
            cardsStack.addArrangedSubview(card)
        }
        shopButton.update(
            symbolName: "cart.fill",
            title: "Visitar el bazar",
            subtitle: "Consigue nuevas materias y equipo.",
            tint: ScreenKit.gold
        )
        shopButton.addTarget(self, action: #selector(openShop), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
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
        magicPointsLabel.attributedText = ScreenKit.symbolText(
            "sparkles",
            text: " \(gameManager.magicPoints) / \(GameManager.maximumMagicPoints) PM ",
            size: 12,
            weight: .bold,
            color: ScreenKit.sky,
            textStyle: .caption1
        )
        slotsLabel.text = "RANURAS ACTIVAS \(gameManager.equippedMateria.count) / \(GameManager.maximumEquippedMateria)  ·  +1 PM cada 3 min"
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
            show("Consigue esta materia en el bazar.", isError: true)
            return
        }
        if gameManager.toggleMateria(materia) {
            show(gameManager.equippedMateria.contains(materia)
                ? "\(materia.name) equipada: su efecto pasivo está activo."
                : "\(materia.name) retirada de las ranuras.")
        } else {
            show("Las dos ranuras están ocupadas. Retira una materia primero.", isError: true)
        }
        refresh()
    }

    private func cast(_ materia: Materia) {
        guard gameManager.castMateria(materia) else {
            if gameManager.pet?.isSleeping == true {
                show("Tu compañero está durmiendo; espera a que despierte para lanzar magia.", isError: true)
            } else if !gameManager.equippedMateria.contains(materia) {
                show("Equipa la materia antes de lanzar su habilidad.", isError: true)
            } else if gameManager.magicPoints >= materia.magicCost {
                show("Esa habilidad no hace falta ahora; sus estadísticas ya están al máximo.", isError: true)
            } else {
                show("No tienes PM suficientes. Se recuperan con el tiempo.", isError: true)
            }
            refresh()
            return
        }
        show("\(materia.name) lanzada. −\(materia.magicCost) PM.")
        refresh()
    }

    private func show(_ text: String, isError: Bool = false) {
        messageLabel.text = text
        messageLabel.textColor = isError ? ScreenKit.hunger : ScreenKit.mint
    }

    @objc private func openShop() { onOpenShop?() }
    @objc private func close() { onClose?() }
}

private final class MateriaCardView: UIView {
    private let materia: Materia
    var onToggle: (() -> Void)?
    var onCast: (() -> Void)?

    private let iconView: UIImageView
    private let nameLabel: UILabel = {
        let label = ScreenKit.label("", size: 17, color: .white, weight: .bold, textStyle: .headline)
        label.textAlignment = .left
        return label
    }()
    private let costLabel: UILabel = {
        let label = ScreenKit.label("", size: 11, color: ScreenKit.sky, weight: .bold, textStyle: .caption1)
        label.textAlignment = .right
        return label
    }()
    private let descriptionLabel: UILabel = {
        let label = ScreenKit.label("", size: 13, color: ScreenKit.mutedText)
        label.textAlignment = .left
        return label
    }()
    private let passiveLabel: UILabel = {
        let label = ScreenKit.label("", size: 11, color: ScreenKit.mint, weight: .medium, textStyle: .caption1)
        label.textAlignment = .left
        return label
    }()
    private let equipButton = ScreenKit.button("Equipar", symbol: "circle.grid.2x2.fill")
    private let castButton = ScreenKit.button("Lanzar", symbol: "wand.and.stars")
    private lazy var headerStack: UIStackView = {
        let stack = ScreenKit.horizontalStack([iconView, nameLabel, costLabel], spacing: 10)
        stack.distribution = .fill
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return stack
    }()
    private lazy var buttonStack: UIStackView = {
        let stack = ScreenKit.horizontalStack([equipButton, castButton], spacing: 10)
        stack.distribution = .fillEqually
        return stack
    }()
    private lazy var contentStack: UIStackView = {
        ScreenKit.stack([headerStack, descriptionLabel, passiveLabel, buttonStack], spacing: 10)
    }()

    init(materia: Materia) {
        self.materia = materia
        iconView = ScreenKit.symbolLabel(materia.symbolName, size: 20, color: ScreenKit.rose)
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = ScreenKit.panel
        layer.cornerRadius = 18
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = ScreenKit.accent.withAlphaComponent(0.12).cgColor
        nameLabel.text = materia.name
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
            iconView.widthAnchor.constraint(equalToConstant: 24),
            equipButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 42),
            castButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 42)
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
            castTitle = "Lanzar · \(materia.magicCost) PM"
        }
        ScreenKit.setTitle(castTitle, on: castButton)
        ScreenKit.setBackground(isEquipped ? ScreenKit.accentSoft : ScreenKit.panel, on: equipButton)
        let state = isOwned ? (isEquipped ? "EQUIPADA" : "EN COLECCIÓN") : "DISPONIBLE EN BAZAR"
        passiveLabel.text = "\(state)  ·  \(materia.passiveDescription)"
        iconView.image = ScreenKit.symbolImage(materia.symbolName, size: 20, color: isEquipped ? ScreenKit.mint : (isOwned ? ScreenKit.rose : ScreenKit.faintText))
    }

    @objc private func toggleTapped() { onToggle?() }
    @objc private func castTapped() { onCast?() }
}
