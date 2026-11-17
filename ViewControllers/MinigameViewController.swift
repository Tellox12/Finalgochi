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

    override func viewDidLoad() {
        super.viewDidLoad()
        ScreenKit.configure(self, title: "Minijuego")
        startButton.addTarget(self, action: #selector(startRound), for: .touchUpInside)
        targetButton.addTarget(self, action: #selector(tapTarget), for: .touchUpInside)
        ScreenKit.install(contentStack, in: self)
    }

    deinit { roundTimer?.invalidate() }

    @objc private func startRound() {
        isReady = false
        targetButton.isEnabled = true
        targetButton.backgroundColor = ScreenKit.panel
        targetButton.setTitle("🔮 Espera…", for: .normal)
        startButton.isEnabled = false
        let delay = Double.random(in: 1.2...3.2)
        roundTimer?.invalidate()
        roundTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.isReady = true
            self.targetButton.backgroundColor = .systemGreen
            self.targetButton.setTitle("¡TOCA!", for: .normal)
        }
    }

    @objc private func tapTarget() {
        guard isReady else {
            roundTimer?.invalidate()
            instructionLabel.text = "¡Demasiado pronto! Intenta otra vez."
            targetButton.isEnabled = false
            startButton.isEnabled = true
            return
        }
        roundTimer?.invalidate()
        onFinish?(true)
    }
}
