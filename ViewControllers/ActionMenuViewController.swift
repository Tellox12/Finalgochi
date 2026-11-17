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
    private let titleLabel: UILabel = { ScreenKit.label("¿Qué hacemos?", size: 27, color: ScreenKit.accent, weight: .bold) }()
    private let petStateLabel: UILabel = {
        let label = ScreenKit.label("", size: 12, color: ScreenKit.mutedText)
        label.textAlignment = .left
        return label
    }()
    private let petSpriteView: PixelPetSpriteView = {
        let view = PixelPetSpriteView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private let petStateCard: UIView = { ScreenKit.card() }()
    private let feedButton: UIButton = { ScreenKit.button("🍖  Alimentar") }()
    private let playButton: UIButton = { ScreenKit.button("🎯  Jugar") }()
    private let sleepButton: UIButton = { ScreenKit.button("🛌  Dormir") }()
    private let statusButton: UIButton = { ScreenKit.button("📊  Estado") }()
    private let materiaButton: UIButton = { ScreenKit.button("🔮  Materia y habilidades") }()
    private let expeditionsButton: UIButton = { ScreenKit.button("🧭  Salir de expedición") }()
    private let closeButton: UIButton = { ScreenKit.button("Volver") }()
    private lazy var petStateStack: UIStackView = {
        let stack = ScreenKit.horizontalStack([petSpriteView, petStateLabel])
        stack.distribution = .fill
        stack.alignment = .center
        return stack
    }()
    private lazy var contentStack: UIStackView = {
        ScreenKit.stack([titleLabel, petStateCard, feedButton, playButton, sleepButton, expeditionsButton, materiaButton, statusButton, closeButton], spacing: 12)
    }()

    init(gameManager: GameManager) {
        self.gameManager = gameManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no está disponible") }

    override func viewDidLoad() {
        super.viewDidLoad()
        ScreenKit.configure(self, title: "Comandos")
        feedButton.addTarget(self, action: #selector(feed), for: .touchUpInside)
        playButton.addTarget(self, action: #selector(play), for: .touchUpInside)
        sleepButton.addTarget(self, action: #selector(sleep), for: .touchUpInside)
        statusButton.addTarget(self, action: #selector(status), for: .touchUpInside)
        materiaButton.addTarget(self, action: #selector(openMateria), for: .touchUpInside)
        expeditionsButton.addTarget(self, action: #selector(openExpeditions), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        petStateCard.addSubview(petStateStack)
        NSLayoutConstraint.activate([
            petStateStack.topAnchor.constraint(equalTo: petStateCard.topAnchor, constant: 14),
            petStateStack.leadingAnchor.constraint(equalTo: petStateCard.leadingAnchor, constant: 16),
            petStateStack.trailingAnchor.constraint(equalTo: petStateCard.trailingAnchor, constant: -16),
            petStateStack.bottomAnchor.constraint(equalTo: petStateCard.bottomAnchor, constant: -14),
            petSpriteView.widthAnchor.constraint(equalToConstant: 64),
            petSpriteView.heightAnchor.constraint(equalToConstant: 64)
        ])
        ScreenKit.setBackground(UIColor(red: 0.46, green: 0.27, blue: 0.25, alpha: 1), on: feedButton)
        ScreenKit.setBackground(UIColor(red: 0.28, green: 0.30, blue: 0.53, alpha: 1), on: playButton)
        ScreenKit.setBackground(UIColor(red: 0.20, green: 0.37, blue: 0.40, alpha: 1), on: sleepButton)
        ScreenKit.installScrollable(contentStack, in: self)
        gameManager.onChange = { [weak self] in self?.refresh() }
        refresh()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        gameManager.onChange = { [weak self] in self?.refresh() }
        refresh()
    }

    private func refresh() {
        guard let pet = gameManager.pet else { return }
        petSpriteView.kind = pet.kind
        petSpriteView.mood = pet.mood
        petSpriteView.equippedItems = gameManager.activeEquipment
        petStateLabel.text = "\(pet.name) · NIVEL \(pet.level)\n\(pet.mood.symbol)  \(pet.mood.title)\n🍖 Saciedad \(Int(pet.hunger))%   ✦ Ánimo \(Int(pet.happiness))%\n☾ Energía \(Int(pet.energy))%"
        ScreenKit.setTitle(pet.isSleeping ? "☀️  Despertar" : "🛌  Dormir", on: sleepButton)
        ScreenKit.setTitle("🔮  Materia  ·  \(gameManager.equippedMateria.count)/\(GameManager.maximumEquippedMateria)  ·  \(gameManager.magicPoints) PM", on: materiaButton)
        sleepButton.isEnabled = pet.isSleeping || (!pet.isGameOver && pet.energy < 100)
        playButton.isEnabled = !pet.isSleeping && !pet.isGameOver && pet.energy >= 8
        sleepButton.alpha = sleepButton.isEnabled ? 1 : 0.45
        playButton.alpha = playButton.isEnabled ? 1 : 0.45
    }

    @objc private func feed() { onFeed?() }
    @objc private func play() { onPlay?() }
    @objc private func sleep() { onSleep?() }
    @objc private func status() { onShowStatus?() }
    @objc private func openMateria() { onOpenMateria?() }
    @objc private func openExpeditions() { onOpenExpeditions?() }
    @objc private func close() { onClose?() }
}
