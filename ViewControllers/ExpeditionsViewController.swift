import UIKit

final class ExpeditionsViewController: UIViewController {
    private let gameManager: GameManager
    var onClose: (() -> Void)?

    private var observerToken: UUID?
    private var clockTimer: Timer?
    private var feedbackMessage = ""

    private let titleLabel = ScreenKit.label("Expediciones", size: 27, color: .white, weight: .bold, textStyle: .largeTitle)
    private let introLabel: UILabel = {
        let label = ScreenKit.label("Elige una misión, prepara a tu compañero y vuelve por sus tesoros.", size: 14, color: ScreenKit.mutedText)
        label.textAlignment = .left
        return label
    }()
    private let companionLabel: UILabel = {
        let label = ScreenKit.label("", size: 12.5, color: ScreenKit.mutedText)
        label.textAlignment = .left
        return label
    }()
    private let companionCard: UIView = { ScreenKit.card() }()
    private let activeTitleLabel = ScreenKit.sectionTitle("EXPEDICIÓN EN CURSO", color: ScreenKit.mint)
    private let activeStatusLabel: UILabel = {
        let label = ScreenKit.label("", size: 15, color: .white, weight: .semibold, textStyle: .headline)
        label.textAlignment = .left
        return label
    }()
    private let activeProgressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.trackTintColor = UIColor.white.withAlphaComponent(0.08)
        progress.progressTintColor = ScreenKit.mint
        progress.layer.cornerRadius = 3.5
        progress.clipsToBounds = true
        return progress
    }()
    private let claimButton = ScreenKit.button("Reclamar recompensa", symbol: "shippingbox.fill", style: .primary)
    private let activeCard: UIView = { ScreenKit.card() }()
    private let routesTitleLabel = ScreenKit.sectionTitle("DESTINOS", color: ScreenKit.gold)
    private let meadowRow = MenuCardControl()
    private let marketRow = MenuCardControl()
    private let cavernRow = MenuCardControl()
    private let statusLabel: UILabel = {
        let label = ScreenKit.label("", size: 12, color: ScreenKit.mutedText, textStyle: .caption1)
        label.textAlignment = .left
        return label
    }()
    private let closeButton = ScreenKit.button("Volver al hábitat", symbol: "chevron.left", style: .ghost)

    private lazy var activeStack: UIStackView = {
        ScreenKit.stack([activeTitleLabel, activeStatusLabel, activeProgressView, claimButton], spacing: 11)
    }()
    private lazy var companionStack: UIStackView = {
        ScreenKit.stack([companionLabel], spacing: 8)
    }()
    private lazy var contentStack: UIStackView = {
        ScreenKit.stack([titleLabel, introLabel, companionCard, activeCard, routesTitleLabel, meadowRow, marketRow, cavernRow, statusLabel, closeButton], spacing: 12)
    }()

    init(gameManager: GameManager) {
        self.gameManager = gameManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no está disponible") }

    override func viewDidLoad() {
        super.viewDidLoad()
        ScreenKit.configure(self, title: "Expediciones")
        titleLabel.textAlignment = .left
        meadowRow.addTarget(self, action: #selector(startMeadow), for: .touchUpInside)
        marketRow.addTarget(self, action: #selector(startMarket), for: .touchUpInside)
        cavernRow.addTarget(self, action: #selector(startCavern), for: .touchUpInside)
        claimButton.addTarget(self, action: #selector(claimReward), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)

        companionCard.addSubview(companionStack)
        activeCard.addSubview(activeStack)
        NSLayoutConstraint.activate([
            companionStack.topAnchor.constraint(equalTo: companionCard.topAnchor, constant: 15),
            companionStack.leadingAnchor.constraint(equalTo: companionCard.leadingAnchor, constant: 18),
            companionStack.trailingAnchor.constraint(equalTo: companionCard.trailingAnchor, constant: -18),
            companionStack.bottomAnchor.constraint(equalTo: companionCard.bottomAnchor, constant: -15),
            activeStack.topAnchor.constraint(equalTo: activeCard.topAnchor, constant: 16),
            activeStack.leadingAnchor.constraint(equalTo: activeCard.leadingAnchor, constant: 18),
            activeStack.trailingAnchor.constraint(equalTo: activeCard.trailingAnchor, constant: -18),
            activeStack.bottomAnchor.constraint(equalTo: activeCard.bottomAnchor, constant: -16),
            activeProgressView.heightAnchor.constraint(equalToConstant: 6)
        ])

        configureRoutes()
        ScreenKit.installScrollable(contentStack, in: self)
        observerToken = gameManager.addObserver { [weak self] in self?.refresh() }
        refresh()
        clockTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        gameManager.updateElapsedTime()
        refresh()
    }

    deinit {
        gameManager.removeObserver(observerToken)
        clockTimer?.invalidate()
    }

    private func configureRoutes() {
        updateRoute(meadowRow, route: .chocoboTrail, tint: ScreenKit.mint)
        updateRoute(marketRow, route: .goblinMarket, tint: ScreenKit.rose)
        updateRoute(cavernRow, route: .crystalCavern, tint: ScreenKit.sky)
    }

    private func updateRoute(_ control: MenuCardControl, route: ExpeditionRoute, tint: UIColor) {
        let minutes = Int(route.duration / 60)
        let durationText = minutes <= 1 ? "1 min" : "\(minutes) min"
        control.update(
            symbolName: route.symbolName,
            title: route.title,
            subtitle: route.description,
            footnote: "\(durationText) · +\(route.gilReward) Gil · +\(route.experienceReward) EXP · \(route.loot.name)",
            tint: tint
        )
        control.accessibilityLabel = "\(route.title). \(route.description). \(durationText). Nivel \(route.minimumLevel) o superior. Energía \(Int(route.minimumEnergy)) o superior."
    }

    private func refresh() {
        guard let pet = gameManager.pet else { return }
        companionLabel.attributedText = companionText(for: pet)
        for (control, route, tint) in [
            (meadowRow, ExpeditionRoute.chocoboTrail, ScreenKit.mint),
            (marketRow, ExpeditionRoute.goblinMarket, ScreenKit.rose),
            (cavernRow, ExpeditionRoute.crystalCavern, ScreenKit.sky)
        ] {
            let available = gameManager.canStartExpedition(route)
            control.isEnabled = available
            updateRoute(control, route: route, tint: available ? tint : ScreenKit.faintText)
        }

        if let expedition = gameManager.activeExpedition {
            activeCard.isHidden = false
            activeStatusLabel.text = expedition.isReady()
                ? "\(expedition.route.title) · tu compañero ya ha vuelto."
                : "\(expedition.route.title) · regresa en \(formattedTime(expedition.remainingTime()))"
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

    private func companionText(for pet: PetModel) -> NSAttributedString {
        let result = NSMutableAttributedString()
        result.append(NSAttributedString(
            string: "\(pet.name) · Nivel \(pet.level)\n",
            attributes: [
                .font: ScreenKit.roundedFont(size: 15, weight: .bold, textStyle: .headline),
                .foregroundColor: UIColor.white
            ]
        ))
        result.append(NSAttributedString(
            string: "Saciedad \(Int(pet.hunger))%   ·   Ánimo \(Int(pet.happiness))%   ·   Energía \(Int(pet.energy))%",
            attributes: [
                .font: ScreenKit.roundedFont(size: 11.5, weight: .medium, textStyle: .caption1),
                .foregroundColor: ScreenKit.mutedText
            ]
        ))
        return result
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
        if didStart, let petName = gameManager.pet?.name {
            feedbackMessage = "\(petName) salió hacia \(route.title.lowercased())."
            LocalNotificationManager.scheduleExpeditionReturn(after: route.duration, petName: petName, routeName: route.title)
        } else {
            feedbackMessage = "No cumple los requisitos para esta ruta."
        }
        refresh()
    }

    @objc private func claimReward() {
        guard let route = gameManager.activeExpedition?.route else { return }
        let hadDiscoveredSpecies = gameManager.progression.discoveredPets.contains(route.discoveredPet)
        guard gameManager.claimExpedition() else { return }
        LocalNotificationManager.clearExpeditionReturn()
        let discovery = route.discoveredPet
        let discoveryText = hadDiscoveredSpecies ? "" : " Nueva especie descubierta: \(discovery.displayName)."
        feedbackMessage = "Recompensa obtenida: +\(route.gilReward) Gil, +\(route.experienceReward) EXP y \(route.loot.name).\(discoveryText)"
        refresh()
    }

    @objc private func close() { onClose?() }
}
