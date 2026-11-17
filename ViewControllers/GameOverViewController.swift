import UIKit

final class GameOverViewController: UIViewController {
    var onRestart: (() -> Void)?
    private let emojiLabel: UILabel = { ScreenKit.label("💀", size: 76) }()
    private let titleLabel: UILabel = { ScreenKit.label("¡Kupó…!", size: 32, color: .systemPink, weight: .heavy) }()
    private let messageLabel: UILabel = { ScreenKit.label("Tu compañero se fue a tomar unas vacaciones en otro mundo.\n¡Puedes empezar una nueva aventura!", size: 17, color: .lightGray) }()
    private let restartButton: UIButton = { ScreenKit.button("✨  Empezar de nuevo") }()
    private lazy var contentStack: UIStackView = {
        ScreenKit.stack([emojiLabel, titleLabel, messageLabel, restartButton], spacing: 20)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        ScreenKit.configure(self, title: "Fin de partida")
        restartButton.addTarget(self, action: #selector(restart), for: .touchUpInside)
        ScreenKit.install(contentStack, in: self)
    }

    @objc private func restart() { onRestart?() }
}
