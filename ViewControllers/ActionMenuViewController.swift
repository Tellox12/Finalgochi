import UIKit

final class ActionMenuViewController: UIViewController {
    private let gameManager: GameManager
    var onFeed: (() -> Void)?
    var onPlay: (() -> Void)?
    var onSleep: (() -> Void)?
    var onOpenMateria: (() -> Void)?
    var onOpenExpeditions: (() -> Void)?
    var onShowStatus: (() -> Void)?
    var onClose: (() -> Void)?

    private var observerToken: UUID?

    private let titleLabel = ScreenKit.label("¿Qué hacemos?", size: 27, color: .white, weight: .bold, textStyle: .largeTitle)
    private let subtitleLabel: UILabel = {
        let label = ScreenKit.label("Elige un cuidado para tu compañero.", size: 14, color: ScreenKit.mutedText)
        label.textAlignment = .left
        return label
    }()
    private let petSpriteView: PixelPetSpriteView = {
        let view = PixelPetSpriteView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private let petStateLabel: UILabel = {
        let label = ScreenKit.label("", size: 13, color: ScreenKit.mutedText)
        label.textAlignment = .left
        return label
    }()
    private let petStateCard: UIView = { ScreenKit.card() }()
    private let feedButton = MenuCardControl()
    private let playButton = MenuCardControl()
    private let sleepButton = MenuCardControl()
    private let expeditionsButton = MenuCardControl()
    private let materiaButton = MenuCardControl()
    private let statusButton = MenuCardControl()
    private let closeButton = ScreenKit.button("Volver", symbol: "chevron.left", style: .ghost)

    private lazy var petStateStack: UIStackView = {
        let stack = ScreenKit.horizontalStack([petSpriteView, petStateLabel], spacing: 14)
        stack.distribution = .fill
        stack.alignment = .center
        return stack
    }()
    private lazy var contentStack: UIStackView = {
        ScreenKit.stack([titleLabel, subtitleLabel, petStateCard, feedButton, playButton, sleepButton, expeditionsButton, materiaButton, statusButton, closeButton], spacing: 11)
    }()

    init(gameManager: GameManager) {
        self.gameManager = gameManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no está disponible") }

    override func viewDidLoad() {
        super.viewDidLoad()
        ScreenKit.configure(self, title: "Acciones")
        titleLabel.textAlignment = .left
        feedButton.addTarget(self, action: #selector(feed), for: .touchUpInside)
        playButton.addTarget(self, action: #selector(play), for: .touchUpInside)
        sleepButton.addTarget(self, action: #selector(sleep), for: .touchUpInside)
        expeditionsButton.addTarget(self, action: #selector(openExpeditions), for: .touchUpInside)
        materiaButton.addTarget(self, action: #selector(openMateria), for: .touchUpInside)
        statusButton.addTarget(self, action: #selector(status), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)

        petStateCard.addSubview(petStateStack)
        NSLayoutConstraint.activate([
            petStateStack.topAnchor.constraint(equalTo: petStateCard.topAnchor, constant: 14),
            petStateStack.leadingAnchor.constraint(equalTo: petStateCard.leadingAnchor, constant: 16),
            petStateStack.trailingAnchor.constraint(equalTo: petStateCard.trailingAnchor, constant: -16),
            petStateStack.bottomAnchor.constraint(equalTo: petStateCard.bottomAnchor, constant: -14),
            petSpriteView.widthAnchor.constraint(equalToConstant: 68),
            petSpriteView.heightAnchor.constraint(equalToConstant: 68)
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
        petSpriteView.kind = pet.kind
        petSpriteView.mood = pet.mood
        petSpriteView.equippedItems = gameManager.activeEquipment
        petStateLabel.attributedText = statusText(for: pet)
        petStateLabel.textAlignment = .left

        feedButton.update(
            symbolName: "fork.knife",
            title: "Alimentar",
            subtitle: "Raciones, verduras y objetos de la mochila.",
            footnote: "Saciedad \(Int(pet.hunger))%",
            tint: ScreenKit.hunger
        )
        playButton.update(
            symbolName: "gamecontroller.fill",
            title: "Jugar",
            subtitle: "Un minijuego rápido sube el ánimo y da experiencia.",
            footnote: gameManager.canPlayMiniGame ? "Ánimo \(Int(pet.happiness))%" : "Cansa demasiado ahora mismo",
            tint: ScreenKit.rose
        )
        playButton.isEnabled = gameManager.canPlayMiniGame
        sleepButton.update(
            symbolName: pet.isSleeping ? "sun.max.fill" : "moon.stars.fill",
            title: pet.isSleeping ? "Despertar" : "Dormir",
            subtitle: pet.isSleeping ? "Terminar el descanso antes de tiempo." : "Ocho horas de descanso reparador.",
            footnote: pet.isSleeping ? "Descansando" : "Energía \(Int(pet.energy))%",
            tint: ScreenKit.sky
        )
        sleepButton.isEnabled = pet.isSleeping || (!pet.isGameOver && pet.energy < 100)
        expeditionsButton.update(
            symbolName: "map.fill",
            title: "Expediciones",
            subtitle: "Misiones con recompensas de Gil, experiencia y objetos.",
            tint: ScreenKit.sky
        )
        materiaButton.update(
            symbolName: "circle.hexagongrid.fill",
            title: "Materia y habilidades",
            subtitle: "Equipa pasivas y lanza magia con tus puntos de materia.",
            footnote: "\(gameManager.equippedMateria.count)/\(GameManager.maximumEquippedMateria) equipadas · \(gameManager.magicPoints) PM",
            tint: ScreenKit.accent
        )
        statusButton.update(
            symbolName: "chart.bar.fill",
            title: "Ficha del compañero",
            subtitle: "Estadísticas, colección, logros y racha de cuidado.",
            tint: ScreenKit.gold
        )
    }

    private func statusText(for pet: PetModel) -> NSAttributedString {
        let result = NSMutableAttributedString()
        result.append(NSAttributedString(
            string: "\(pet.name) · Nivel \(pet.level)\n",
            attributes: [
                .font: ScreenKit.roundedFont(size: 15, weight: .bold, textStyle: .headline),
                .foregroundColor: UIColor.white
            ]
        ))
        result.append(ScreenKit.symbolText(
            pet.mood.symbolName,
            text: "  \(pet.mood.title)",
            size: 12,
            weight: .semibold,
            color: ScreenKit.mint,
            textStyle: .caption1
        ))
        result.append(NSAttributedString(
            string: "\nSaciedad \(Int(pet.hunger))%   ·   Ánimo \(Int(pet.happiness))%   ·   Energía \(Int(pet.energy))%",
            attributes: [
                .font: ScreenKit.roundedFont(size: 11.5, weight: .medium, textStyle: .caption1),
                .foregroundColor: ScreenKit.mutedText
            ]
        ))
        return result
    }

    @objc private func feed() { onFeed?() }
    @objc private func play() { onPlay?() }
    @objc private func sleep() { onSleep?() }
    @objc private func status() { onShowStatus?() }
    @objc private func openMateria() { onOpenMateria?() }
    @objc private func openExpeditions() { onOpenExpeditions?() }
    @objc private func close() { onClose?() }
}
