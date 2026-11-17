import UIKit

final class MinigameViewController: UIViewController {
    var onFinish: ((Bool) -> Void)?
    private let titleLabel: UILabel = { ScreenKit.label("¡Prueba de reflejos!", size: 27, color: ScreenKit.accent, weight: .bold) }()
    private let instructionLabel: UILabel = { ScreenKit.label("Toca el cristal cuando cambie a verde.", size: 17, color: .lightGray) }()
    private let modeControl: UISegmentedControl = {
        let control = UISegmentedControl(items: MiniGameMode.allCases.map(\.title))
        control.translatesAutoresizingMaskIntoConstraints = false
        control.selectedSegmentIndex = MiniGameMode.crystalReflex.rawValue
        control.selectedSegmentTintColor = ScreenKit.accent
        control.accessibilityLabel = "Modo del minijuego"
        return control
    }()
    private let targetButton: UIButton = {
        let button = ScreenKit.button("🔮 Espera…")
        button.isEnabled = false
        return button
    }()
    private let startButton: UIButton = { ScreenKit.button("Comenzar") }()
    private lazy var contentStack: UIStackView = {
        ScreenKit.stack([titleLabel, instructionLabel, modeControl, targetButton, startButton], spacing: 18)
    }()
    private var isReady = false
    private var roundTimer: Timer?
    private var responseTimer: Timer?
    private var isSprint = false
    private var isMateriaSequence = false
    private var remainingTaps = 0
    private var signalIndex = 0
    private let materiaSignals = ["🔥", "💚", "⚡", "🔮"]

    override func viewDidLoad() {
        super.viewDidLoad()
        ScreenKit.configure(self, title: "Minijuego")
        startButton.addTarget(self, action: #selector(startRound), for: .touchUpInside)
        targetButton.addTarget(self, action: #selector(tapTarget), for: .touchUpInside)
        modeControl.addTarget(self, action: #selector(modeChanged), for: .valueChanged)
        ScreenKit.installScrollable(contentStack, in: self)
    }

    deinit {
        roundTimer?.invalidate()
        responseTimer?.invalidate()
    }

    @objc private func startRound() {
        roundTimer?.invalidate()
        responseTimer?.invalidate()
        isReady = false
        isSprint = modeControl.selectedSegmentIndex == MiniGameMode.chocoboSprint.rawValue
        isMateriaSequence = modeControl.selectedSegmentIndex == MiniGameMode.materiaRush.rawValue
        targetButton.isEnabled = isSprint
        targetButton.transform = .identity
        ScreenKit.setBackground(ScreenKit.panel, on: targetButton)
        startButton.isEnabled = false

        if isSprint {
            remainingTaps = 5
            isReady = true
            instructionLabel.text = "¡Cinco zancadas antes de que acabe el tiempo!"
            ScreenKit.setTitle("🐤 ¡CORRE!  ·  \(remainingTaps)", on: targetButton)
            ScreenKit.setTitle("Sprint en curso…", on: startButton)
            roundTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: false) { [weak self] _ in
                guard let self, self.isReady else { return }
                self.finishRound(success: false, message: "El chocobo necesita más velocidad.")
            }
            return
        }

        if isMateriaSequence {
            signalIndex = 0
            instructionLabel.text = "Lanza tres materias justo cuando aparezcan."
            ScreenKit.setTitle("🔮 Canalizando…", on: targetButton)
            ScreenKit.setTitle("Canalizando…", on: startButton)
            scheduleMateriaSignal()
            return
        }

        instructionLabel.text = "Toca el cristal en cuanto se ilumine."
        targetButton.isEnabled = true
        ScreenKit.setTitle("🔮 Espera…", on: targetButton)
        ScreenKit.setTitle("Ronda en curso…", on: startButton)
        let delay = Double.random(in: 1.2...3.2)
        roundTimer?.invalidate()
        roundTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.isReady = true
            ScreenKit.setBackground(.systemGreen, on: self.targetButton)
            ScreenKit.setTitle("¡TOCA!", on: self.targetButton)
            if UIAccessibility.isReduceMotionEnabled {
                self.targetButton.transform = .identity
            } else {
                UIView.animate(withDuration: 0.18, animations: {
                    self.targetButton.transform = CGAffineTransform(scaleX: 1.04, y: 1.04)
                }, completion: { _ in
                    UIView.animate(withDuration: 0.18, animations: {
                        self.targetButton.transform = .identity
                    }, completion: nil)
                })
            }
            self.responseTimer = Timer.scheduledTimer(withTimeInterval: 1.8, repeats: false) { [weak self] _ in
                guard let self, self.isReady else { return }
                self.isReady = false
                self.targetButton.isEnabled = false
                self.startButton.isEnabled = true
                self.instructionLabel.text = "El cristal se apagó. ¡Prueba de nuevo!"
                ScreenKit.setTitle("Comenzar otra vez", on: self.startButton)
                ScreenKit.setTitle("⌛ Tiempo agotado", on: self.targetButton)
                ScreenKit.setBackground(ScreenKit.panel, on: self.targetButton)
            }
        }
    }

    @objc private func tapTarget() {
        if isSprint {
            remainingTaps -= 1
            if remainingTaps <= 0 {
                finishRound(success: true, message: "¡Sprint perfecto! Gil y experiencia ganados.")
            } else {
                ScreenKit.setTitle("🐤 ¡CORRE!  ·  \(remainingTaps)", on: targetButton)
                if !UIAccessibility.isReduceMotionEnabled {
                    UIView.animate(withDuration: 0.08, animations: { self.targetButton.transform = CGAffineTransform(scaleX: 0.94, y: 0.94) }) { _ in
                        UIView.animate(withDuration: 0.08) { self.targetButton.transform = .identity }
                    }
                }
            }
            return
        }

        if isMateriaSequence {
            guard isReady else { return }
            responseTimer?.invalidate()
            isReady = false
            signalIndex += 1
            guard signalIndex < 3 else {
                finishRound(success: true, message: "¡Secuencia completada! Gil y experiencia ganados.")
                return
            }
            targetButton.isEnabled = false
            ScreenKit.setTitle("✨ ¡Bien!", on: targetButton)
            scheduleMateriaSignal()
            return
        }

        guard isReady else {
            roundTimer?.invalidate()
            instructionLabel.text = "¡Demasiado pronto! Intenta otra vez."
            targetButton.isEnabled = false
            startButton.isEnabled = true
            ScreenKit.setTitle("Comenzar otra vez", on: startButton)
            return
        }
        roundTimer?.invalidate()
        responseTimer?.invalidate()
        finishRound(success: true, message: "¡Perfecto! Gil y experiencia ganados.")
    }

    @objc private func modeChanged() {
        roundTimer?.invalidate()
        responseTimer?.invalidate()
        isReady = false
        targetButton.isEnabled = false
        startButton.isEnabled = true
        switch modeControl.selectedSegmentIndex {
        case MiniGameMode.chocoboSprint.rawValue:
            instructionLabel.text = "Pulsa cinco veces antes de cuatro segundos."
            ScreenKit.setTitle("🐤 Sprint", on: targetButton)
        case MiniGameMode.materiaRush.rawValue:
            instructionLabel.text = "Reacciona a tres señales mágicas."
            ScreenKit.setTitle("🔮 Materia", on: targetButton)
        default:
            instructionLabel.text = "Toca el cristal cuando cambie a verde."
            ScreenKit.setTitle("🔮 Espera…", on: targetButton)
        }
        ScreenKit.setTitle("Comenzar", on: startButton)
    }

    private func scheduleMateriaSignal() {
        roundTimer = Timer.scheduledTimer(withTimeInterval: Double.random(in: 0.65...1.45), repeats: false) { [weak self] _ in
            guard let self else { return }
            self.isReady = true
            self.targetButton.isEnabled = true
            let symbol = self.materiaSignals[self.signalIndex % self.materiaSignals.count]
            ScreenKit.setBackground(ScreenKit.mint, on: self.targetButton)
            ScreenKit.setTitle("\(symbol)  ¡LANZA!", on: self.targetButton)
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
        ScreenKit.setTitle(success ? "🏆 ¡Victoria!" : "⏳ Fin de la ronda", on: targetButton)
        ScreenKit.setBackground(success ? ScreenKit.mint : ScreenKit.panel, on: targetButton)
        ScreenKit.setTitle("Jugar de nuevo", on: startButton)
        onFinish?(success)
    }
}
