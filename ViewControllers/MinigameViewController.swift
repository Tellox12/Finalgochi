import UIKit

final class MinigameViewController: UIViewController {
    /// Called once per finished round so the coordinator can apply rewards.
    var onResult: ((Bool) -> Void)?
    var onClose: (() -> Void)?

    private let titleLabel = ScreenKit.label("Prueba de reflejos", size: 27, color: .white, weight: .bold, textStyle: .largeTitle)
    private let instructionLabel: UILabel = {
        let label = ScreenKit.label("Toca el cristal cuando cambie a verde.", size: 14, color: ScreenKit.mutedText)
        label.textAlignment = .left
        return label
    }()
    private let modeControl: UISegmentedControl = {
        let control = UISegmentedControl(items: MiniGameMode.allCases.map(\.title))
        control.translatesAutoresizingMaskIntoConstraints = false
        control.selectedSegmentIndex = MiniGameMode.crystalReflex.rawValue
        control.selectedSegmentTintColor = ScreenKit.accentSoft
        control.setTitleTextAttributes([
            .foregroundColor: ScreenKit.mutedText,
            .font: ScreenKit.roundedFont(size: 12.5, weight: .semibold, textStyle: .caption1)
        ], for: .normal)
        control.setTitleTextAttributes([
            .foregroundColor: UIColor.white,
            .font: ScreenKit.roundedFont(size: 12.5, weight: .bold, textStyle: .caption1)
        ], for: .selected)
        control.accessibilityLabel = "Modo del minijuego"
        return control
    }()

    private let targetButton: UIButton = {
        let button = ScreenKit.button("", symbol: "diamond.fill", style: .secondary)
        button.isEnabled = false
        var configuration = button.configuration
        configuration?.contentInsets = NSDirectionalEdgeInsets(top: 34, leading: 24, bottom: 34, trailing: 24)
        configuration?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = ScreenKit.roundedFont(size: 20, weight: .bold, textStyle: .title3)
            return outgoing
        }
        button.configuration = configuration
        return button
    }()
    private let startButton = ScreenKit.button("Comenzar", symbol: "play.fill", style: .primary)
    private let closeButton = ScreenKit.button("Volver al hábitat", symbol: "chevron.left", style: .ghost)

    private let resultCard: UIView = { ScreenKit.card() }()
    private let resultIcon: UIImageView = ScreenKit.symbolLabel("sparkles", size: 26, color: ScreenKit.accent)
    private let resultLabel: UILabel = {
        let label = ScreenKit.label("", size: 14, color: .white, weight: .semibold, textStyle: .subheadline)
        label.textAlignment = .left
        return label
    }()

    private var isReady = false
    private var roundTimer: Timer?
    private var responseTimer: Timer?
    private var isSprint = false
    private var isMateriaSequence = false
    private var remainingTaps = 0
    private var signalIndex = 0
    private var roundResolved = false
    private let materiaSignals = ["flame.fill", "cross.case.fill", "bolt.fill", "sparkles"]

    private lazy var contentStack: UIStackView = {
        ScreenKit.stack([titleLabel, instructionLabel, modeControl, targetButton, resultCard, startButton, closeButton], spacing: 16)
    }()
    private lazy var resultStack: UIStackView = {
        let stack = ScreenKit.horizontalStack([resultIcon, resultLabel], spacing: 12)
        stack.distribution = .fill
        return stack
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        ScreenKit.configure(self, title: "Minijuego")
        titleLabel.textAlignment = .left
        startButton.addTarget(self, action: #selector(startRound), for: .touchUpInside)
        targetButton.addTarget(self, action: #selector(tapTarget), for: .touchUpInside)
        modeControl.addTarget(self, action: #selector(modeChanged), for: .valueChanged)
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)

        resultCard.addSubview(resultStack)
        NSLayoutConstraint.activate([
            resultStack.topAnchor.constraint(equalTo: resultCard.topAnchor, constant: 14),
            resultStack.leadingAnchor.constraint(equalTo: resultCard.leadingAnchor, constant: 16),
            resultStack.trailingAnchor.constraint(equalTo: resultCard.trailingAnchor, constant: -16),
            resultStack.bottomAnchor.constraint(equalTo: resultCard.bottomAnchor, constant: -14),
            resultIcon.widthAnchor.constraint(equalToConstant: 30),
            targetButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 132)
        ])
        resultCard.isHidden = true
        ScreenKit.installScrollable(contentStack, in: self)
        updateModeHint()
    }

    deinit {
        roundTimer?.invalidate()
        responseTimer?.invalidate()
    }

    @objc private func startRound() {
        roundTimer?.invalidate()
        responseTimer?.invalidate()
        isReady = false
        roundResolved = false
        resultCard.isHidden = true
        isSprint = modeControl.selectedSegmentIndex == MiniGameMode.chocoboSprint.rawValue
        isMateriaSequence = modeControl.selectedSegmentIndex == MiniGameMode.materiaRush.rawValue
        targetButton.isEnabled = isSprint
        targetButton.transform = .identity
        ScreenKit.setBackground(ScreenKit.panel, on: targetButton)
        ScreenKit.setTitle("", on: targetButton)
        setTargetSymbol("diamond.fill", tint: ScreenKit.faintText)
        startButton.isEnabled = false
        ScreenKit.setTitle(isSprint ? "Sprint en curso…" : (isMateriaSequence ? "Canalizando…" : "Ronda en curso…"), on: startButton)

        if isSprint {
            remainingTaps = 5
            isReady = true
            instructionLabel.text = "Cinco zancadas antes de que acabe el tiempo."
            ScreenKit.setTitle("¡CORRE!  ·  \(remainingTaps)", on: targetButton)
            setTargetSymbol("bird.fill", tint: ScreenKit.gold)
            roundTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: false) { [weak self] _ in
                guard let self, self.isReady else { return }
                self.finishRound(success: false, message: "El chocobo necesita más velocidad.")
            }
            return
        }

        if isMateriaSequence {
            signalIndex = 0
            instructionLabel.text = "Lanza tres materias justo cuando aparezcan."
            ScreenKit.setTitle("Canalizando…", on: targetButton)
            setTargetSymbol("sparkles", tint: ScreenKit.rose)
            scheduleMateriaSignal()
            return
        }

        instructionLabel.text = "Toca el cristal en cuanto se ilumine."
        targetButton.isEnabled = true
        ScreenKit.setTitle("Espera…", on: targetButton)
        setTargetSymbol("diamond.fill", tint: ScreenKit.faintText)
        let delay = Double.random(in: 1.2...3.2)
        roundTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.isReady = true
            ScreenKit.setBackground(ScreenKit.accentSoft, on: self.targetButton)
            ScreenKit.setTitle("¡TOCA!", on: self.targetButton)
            self.setTargetSymbol("sparkles", tint: .white)
            self.pulseTarget()
            self.responseTimer = Timer.scheduledTimer(withTimeInterval: 1.8, repeats: false) { [weak self] _ in
                guard let self, self.isReady else { return }
                self.isReady = false
                self.targetButton.isEnabled = false
                self.finishRound(success: false, message: "El cristal se apagó. ¡Prueba de nuevo!")
            }
        }
    }

    @objc private func tapTarget() {
        if isSprint {
            guard isReady else { return }
            remainingTaps -= 1
            if remainingTaps <= 0 {
                finishRound(success: true, message: "Sprint perfecto. Ganaste Gil y experiencia.")
            } else {
                ScreenKit.setTitle("¡CORRE!  ·  \(remainingTaps)", on: targetButton)
                pulseTarget()
            }
            return
        }

        if isMateriaSequence {
            guard isReady else { return }
            responseTimer?.invalidate()
            isReady = false
            signalIndex += 1
            guard signalIndex < 3 else {
                finishRound(success: true, message: "Secuencia completada. Ganaste Gil y experiencia.")
                return
            }
            targetButton.isEnabled = false
            ScreenKit.setBackground(ScreenKit.panel, on: targetButton)
            ScreenKit.setTitle("Bien…", on: targetButton)
            scheduleMateriaSignal()
            return
        }

        guard isReady else {
            roundTimer?.invalidate()
            finishRound(success: false, message: "Demasiado pronto. Mantén la calma e inténtalo otra vez.")
            return
        }
        roundTimer?.invalidate()
        responseTimer?.invalidate()
        finishRound(success: true, message: "¡Perfecto! Ganaste Gil y experiencia.")
    }

    @objc private func modeChanged() {
        roundTimer?.invalidate()
        responseTimer?.invalidate()
        isReady = false
        targetButton.isEnabled = false
        startButton.isEnabled = true
        resultCard.isHidden = true
        ScreenKit.setTitle("Comenzar", on: startButton)
        updateModeHint()
    }

    private func updateModeHint() {
        switch modeControl.selectedSegmentIndex {
        case MiniGameMode.chocoboSprint.rawValue:
            instructionLabel.text = "Pulsa cinco veces antes de cuatro segundos."
            ScreenKit.setTitle("Sprint", on: targetButton)
            setTargetSymbol("bird.fill", tint: ScreenKit.gold)
        case MiniGameMode.materiaRush.rawValue:
            instructionLabel.text = "Reacciona a tres señales mágicas."
            ScreenKit.setTitle("Materia", on: targetButton)
            setTargetSymbol("sparkles", tint: ScreenKit.rose)
        default:
            instructionLabel.text = "Toca el cristal cuando cambie a verde."
            ScreenKit.setTitle("Espera…", on: targetButton)
            setTargetSymbol("diamond.fill", tint: ScreenKit.faintText)
        }
        ScreenKit.setBackground(ScreenKit.panel, on: targetButton)
    }

    private func scheduleMateriaSignal() {
        roundTimer = Timer.scheduledTimer(withTimeInterval: Double.random(in: 0.65...1.45), repeats: false) { [weak self] _ in
            guard let self else { return }
            self.isReady = true
            self.targetButton.isEnabled = true
            let symbol = self.materiaSignals[self.signalIndex % self.materiaSignals.count]
            ScreenKit.setBackground(ScreenKit.accentSoft, on: self.targetButton)
            ScreenKit.setTitle("¡LANZA!", on: self.targetButton)
            self.setTargetSymbol(symbol, tint: .white)
            self.responseTimer = Timer.scheduledTimer(withTimeInterval: 1.25, repeats: false) { [weak self] _ in
                guard let self, self.isReady else { return }
                self.finishRound(success: false, message: "La señal se desvaneció. ¡Intenta otra vez!")
            }
        }
    }

    private func finishRound(success: Bool, message: String) {
        roundTimer?.invalidate()
        responseTimer?.invalidate()
        isReady = false
        targetButton.isEnabled = false
        startButton.isEnabled = true
        instructionLabel.text = message

        ScreenKit.setTitle(success ? "¡Victoria!" : "Fin de la ronda", on: targetButton)
        ScreenKit.setBackground(success ? ScreenKit.accentSoft : ScreenKit.panel, on: targetButton)
        setTargetSymbol(success ? "trophy.fill" : "hourglass", tint: success ? ScreenKit.gold : ScreenKit.faintText)

        resultCard.isHidden = false
        resultIcon.image = ScreenKit.symbolImage(success ? "checkmark.seal.fill" : "lightbulb.fill", size: 26, color: success ? ScreenKit.mint : ScreenKit.gold)
        resultLabel.text = success
            ? "Ronda superada. Tu compañero recibió experiencia y Gil."
            : "No pasa nada: la práctica también deja una pequeña recompensa."
        resultLabel.textColor = success ? ScreenKit.mint : ScreenKit.mutedText
        ScreenKit.setTitle("Jugar de nuevo", on: startButton)

        guard !roundResolved else { return }
        roundResolved = true
        onResult?(success)
        UIAccessibility.post(notification: .announcement, argument: success ? "Victoria" : "Fin de la ronda")
    }

    private func setTargetSymbol(_ name: String, tint: UIColor) {
        guard var configuration = targetButton.configuration else { return }
        configuration.image = ScreenKit.symbolImage(name, size: 26, color: tint)
        targetButton.configuration = configuration
    }

    private func pulseTarget() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        UIView.animate(withDuration: 0.12, animations: {
            self.targetButton.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        }) { _ in
            UIView.animate(withDuration: 0.16) { self.targetButton.transform = .identity }
        }
    }

    @objc private func close() { onClose?() }
}
