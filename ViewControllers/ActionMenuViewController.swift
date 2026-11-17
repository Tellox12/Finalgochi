import UIKit

final class ActionMenuViewController: UIViewController {
    private let gameManager: GameManager
    var onFeed: (() -> Void)?
    var onPlay: (() -> Void)?
    var onSleep: (() -> Void)?
    var onShowStatus: (() -> Void)?
    var onClose: (() -> Void)?
    private let titleLabel: UILabel = { ScreenKit.label("¿Qué hacemos?", size: 27, color: ScreenKit.accent, weight: .bold) }()
    private let feedButton: UIButton = { ScreenKit.button("🍖  Alimentar") }()
    private let playButton: UIButton = { ScreenKit.button("🎯  Jugar") }()
    private let sleepButton: UIButton = { ScreenKit.button("🛌  Dormir") }()
    private let statusButton: UIButton = { ScreenKit.button("📊  Estado") }()
    private let closeButton: UIButton = { ScreenKit.button("Volver") }()
    private lazy var contentStack: UIStackView = {
        ScreenKit.stack([titleLabel, feedButton, playButton, sleepButton, statusButton, closeButton])
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
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        let isSleeping = gameManager.pet?.isSleeping == true
        sleepButton.setTitle(isSleeping ? "☀️  Despertar" : "🛌  Dormir", for: .normal)
        sleepButton.isEnabled = isSleeping || (gameManager.pet?.energy ?? 100) < 100
        sleepButton.alpha = sleepButton.isEnabled ? 1 : 0.45
        ScreenKit.install(contentStack, in: self)
    }

    @objc private func feed() { onFeed?() }
    @objc private func play() { onPlay?() }
    @objc private func sleep() { onSleep?() }
    @objc private func status() { onShowStatus?() }
    @objc private func close() { onClose?() }
}
