import UIKit

final class MinigameViewController: UIViewController {
    var onFinish: ((Bool) -> Void)?
    private let titleLabel: UILabel = { ScreenKit.label("¡Prueba de reflejos!", size: 27, color: ScreenKit.accent, weight: .bold) }()
    private let instructionLabel: UILabel = { ScreenKit.label("Toca el cristal cuando cambie a verde.", size: 17, color: .lightGray) }()
    private let targetButton: UIButton = {
        let button = ScreenKit.button("🔮 Espera…")
        button.isEnabled = false
        return button
    }()
    private let startButton: UIButton = { ScreenKit.button("Comenzar") }()
    private lazy var contentStack: UIStackView = {
        ScreenKit.stack([titleLabel, instructionLabel, targetButton, startButton], spacing: 18)
    }()
    private var isReady = false
    private var roundTimer: Timer?
    private var responseTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        ScreenKit.configure(self, title: "Minijuego")
        startButton.addTarget(self, action: #selector(startRound), for: .touchUpInside)
        targetButton.addTarget(self, action: #selector(tapTarget), for: .touchUpInside)
        ScreenKit.installScrollable(contentStack, in: self)
    }

    deinit {
        roundTimer?.invalidate()
        responseTimer?.invalidate()
    }

    @objc private func startRound() {
        isReady = false
        responseTimer?.invalidate()
        instructionLabel.text = "Toca el cristal en cuanto se ilumine."
        targetButton.isEnabled = true
        targetButton.transform = .identity
        ScreenKit.setBackground(ScreenKit.panel, on: targetButton)
        ScreenKit.setTitle("🔮 Espera…", on: targetButton)
        startButton.isEnabled = false
        ScreenKit.setTitle("Ronda en curso…", on: startButton)
        let delay = Double.random(in: 1.2...3.2)
        roundTimer?.invalidate()
        roundTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.isReady = true
            ScreenKit.setBackground(.systemGreen, on: self.targetButton)
            ScreenKit.setTitle("¡TOCA!", on: self.targetButton)
            UIView.animate(withDuration: 0.18, animations: {
                self.targetButton.transform = CGAffineTransform(scaleX: 1.04, y: 1.04)
            }, completion: { _ in
                UIView.animate(withDuration: 0.18, animations: {
                    self.targetButton.transform = .identity
                }, completion: nil)
            })
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
        ScreenKit.setTitle("¡Perfecto!", on: targetButton)
        onFinish?(true)
    }
}
