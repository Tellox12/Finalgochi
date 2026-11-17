import UIKit

final class ExpeditionsViewController: UIViewController {
    private let gameManager: GameManager
    var onClose: (() -> Void)?

    private var clockTimer: Timer?
    private var feedbackMessage = ""

    private let titleLabel: UILabel = {
        ScreenKit.label("TABLÓN DE EXPEDICIONES", size: 13, color: ScreenKit.gold, weight: .bold)
    }()
    private let introLabel: UILabel = {
        let label = ScreenKit.label("Elige una misión, prepara a tu compañero y vuelve por sus tesoros.", size: 15, color: ScreenKit.mutedText)
        label.textAlignment = .left
        return label
    }()
    private let companionLabel: UILabel = {
        let label = ScreenKit.label("", size: 13, color: .white, weight: .semibold)
        label.textAlignment = .left
        return label
    }()
    private let companionCard: UIView = { ScreenKit.card() }()
    private let activeTitleLabel: UILabel = {
        ScreenKit.label("EXPEDICIÓN EN CURSO", size: 12, color: ScreenKit.mint, weight: .bold)
    }()
    private let activeStatusLabel: UILabel = {
        ScreenKit.label("", size: 15, color: .white, weight: .semibold)
    }()
    private let activeProgressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.trackTintColor = UIColor.white.withAlphaComponent(0.10)
        progress.progressTintColor = ScreenKit.mint
        return progress
    }()
    private let claimButton: UIButton = { ScreenKit.button("🎁  Reclamar recompensa") }()
    private let activeCard: UIView = { ScreenKit.card() }()
    private let routesTitleLabel: UILabel = {
        ScreenKit.label("DESTINOS", size: 12, color: ScreenKit.gold, weight: .bold)
    }()
    private let meadowButton: UIButton = { ScreenKit.button("") }()
    private let marketButton: UIButton = { ScreenKit.button("") }()
    private let cavernButton: UIButton = { ScreenKit.button("") }()
    private let statusLabel: UILabel = {
        ScreenKit.label("", size: 12, color: ScreenKit.mutedText)
    }()
    private let closeButton: UIButton = { ScreenKit.button("Volver al hábitat") }()

    private lazy var activeStack: UIStackView = {
        ScreenKit.stack([activeTitleLabel, activeStatusLabel, activeProgressView, claimButton], spacing: 11)
    }()
    private lazy var companionStack: UIStackView = {
        ScreenKit.stack([companionLabel], spacing: 8)
    }()
    private lazy var contentStack: UIStackView = {
        ScreenKit.stack([titleLabel, introLabel, companionCard, activeCard, routesTitleLabel, meadowButton, marketButton, cavernButton, statusLabel, closeButton], spacing: 14)
    }()

    init(gameManager: GameManager) {
        self.gameManager = gameManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no está disponible") }

    override func viewDidLoad() {
        super.viewDidLoad()
        ScreenKit.configure(self, title: "Expediciones")
        meadowButton.addTarget(self, action: #selector(startMeadow), for: .touchUpInside)
        marketButton.addTarget(self, action: #selector(startMarket), for: .touchUpInside)
        cavernButton.addTarget(self, action: #selector(startCavern), for: .touchUpInside)
        claimButton.addTarget(self, action: #selector(claimReward), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)

        companionCard.addSubview(companionStack)
        activeCard.addSubview(activeStack)
        NSLayoutConstraint.activate([
            companionStack.topAnchor.constraint(equalTo: companionCard.topAnchor, constant: 16),
            companionStack.leadingAnchor.constraint(equalTo: companionCard.leadingAnchor, constant: 18),
            companionStack.trailingAnchor.constraint(equalTo: companionCard.trailingAnchor, constant: -18),
            companionStack.bottomAnchor.constraint(equalTo: companionCard.bottomAnchor, constant: -16),
            activeStack.topAnchor.constraint(equalTo: activeCard.topAnchor, constant: 16),
            activeStack.leadingAnchor.constraint(equalTo: activeCard.leadingAnchor, constant: 18),
            activeStack.trailingAnchor.constraint(equalTo: activeCard.trailingAnchor, constant: -18),
            activeStack.bottomAnchor.constraint(equalTo: activeCard.bottomAnchor, constant: -16),
            activeProgressView.heightAnchor.constraint(equalToConstant: 7)
        ])

        configureRouteButtons()
        ScreenKit.installScrollable(contentStack, in: self)
        gameManager.onChange = { [weak self] in self?.refresh() }
        refresh()
        clockTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        gameManager.updateElapsedTime()
        refresh()
    }

    deinit { clockTimer?.invalidate() }

    private func configureRouteButtons() {
        configure(meadowButton, for: .chocoboTrail)
        configure(marketButton, for: .goblinMarket)
        configure(cavernButton, for: .crystalCavern)
    }

    private func configure(_ button: UIButton, for route: ExpeditionRoute) {
        let minutes = Int(route.duration / 60)
        let durationText = minutes == 0 ? "1 min" : "\(minutes) min"
        let title = "\(route.symbol)  \(route.title)\n\(route.description)\n\(durationText)  ·  +\(route.gilReward) Gil  ·  +\(route.experienceReward) EXP  ·  \(route.loot.emoji)\nNivel \(route.minimumLevel)+  ·  Energía \(Int(route.minimumEnergy))+"
        ScreenKit.setTitle(title, on: button)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        button.titleLabel?.textAlignment = .left
        button.titleLabel?.numberOfLines = 0
        button.contentHorizontalAlignment = .leading
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 100).isActive = true
    }

    private func refresh() {
        guard let pet = gameManager.pet else { return }
        companionLabel.text = "\(pet.kind.emoji)  \(pet.name) · Nivel \(pet.level)\n✦ Ánimo \(Int(pet.happiness))%    ☾ Energía \(Int(pet.energy))%    🍖 Saciedad \(Int(pet.hunger))%"
        meadowButton.isEnabled = gameManager.canStartExpedition(.chocoboTrail)
        marketButton.isEnabled = gameManager.canStartExpedition(.goblinMarket)
        cavernButton.isEnabled = gameManager.canStartExpedition(.crystalCavern)
        for button in [meadowButton, marketButton, cavernButton] {
            button.alpha = button.isEnabled ? 1 : 0.42
        }

        if let expedition = gameManager.activeExpedition {
            activeCard.isHidden = false
            activeStatusLabel.text = "\(expedition.route.symbol)  \(expedition.route.title)\n\(expedition.isReady() ? "¡Tu compañero regresó!" : "Regresa en \(formattedTime(expedition.remainingTime()))")"
            activeProgressView.setProgress(Float(expedition.progress()), animated: true)
            claimButton.isEnabled = expedition.isReady()
            claimButton.alpha = claimButton.isEnabled ? 1 : 0.45
            statusLabel.text = "La recompensa incluye Gil, experiencia y \(expedition.route.loot.name)."
        } else {
            activeCard.isHidden = true
            activeProgressView.setProgress(0, animated: false)
            statusLabel.text = feedbackMessage.isEmpty ? availabilityMessage(for: pet) : feedbackMessage
        }
    }

    private func availabilityMessage(for pet: PetModel) -> String {
        if pet.isSleeping { return "Despiértalo antes de partir de aventura." }
        if pet.isGameOver { return "Tu compañero necesita cuidados antes de salir." }
        if pet.energy < ExpeditionRoute.chocoboTrail.minimumEnergy { return "Necesita descansar para tener al menos 25 de energía." }
        if pet.hunger < 20 || pet.happiness < 20 { return "Cuida su saciedad y ánimo antes de enviarlo de viaje." }
        return "Una expedición puede durar mientras la app está cerrada. Reclama el botín al volver."
    }

    private func formattedTime(_ interval: TimeInterval) -> String {
        let seconds = max(0, Int(ceil(interval)))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    @objc private func startMeadow() { start(.chocoboTrail) }
    @objc private func startMarket() { start(.goblinMarket) }
    @objc private func startCavern() { start(.crystalCavern) }

    private func start(_ route: ExpeditionRoute) {
        let didStart = gameManager.startExpedition(route)
        feedbackMessage = didStart
            ? "\(route.symbol) ¡\(gameManager.pet?.name ?? "Tu compañero") salió a \(route.title.lowercased())!"
            : "No cumple los requisitos para esta ruta."
        if didStart, let petName = gameManager.pet?.name {
            LocalNotificationManager.scheduleExpeditionReturn(after: route.duration, petName: petName, routeName: route.title)
        }
        refresh()
    }

    @objc private func claimReward() {
        guard let route = gameManager.activeExpedition?.route,
              gameManager.claimExpedition() else { return }
        LocalNotificationManager.clearExpeditionReturn()
        feedbackMessage = "¡Recompensa! +\(route.gilReward) Gil, +\(route.experienceReward) EXP y \(route.loot.emoji)."
        refresh()
    }

    @objc private func close() { onClose?() }
}
