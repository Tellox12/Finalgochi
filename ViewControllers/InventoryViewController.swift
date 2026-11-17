import UIKit

final class InventoryViewController: UIViewController {
    let gameManager: GameManager
    var onClose: (() -> Void)?
    private let titleLabel: UILabel = { ScreenKit.label("Inventario", size: 27, color: ScreenKit.accent, weight: .bold) }()
    private let foodButton: UIButton = { ScreenKit.button("🍖 Ración de viaje  ·  recuperar hambre") }()
    private let closeButton: UIButton = { ScreenKit.button("Volver al hábitat") }()
    private let hintLabel: UILabel = { ScreenKit.label("La ración es gratis y está recién hecha.", size: 14, color: .lightGray) }()

    init(gameManager: GameManager) { self.gameManager = gameManager; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("init(coder:) no está disponible") }

    override func viewDidLoad() {
        super.viewDidLoad()
        ScreenKit.configure(self, title: "Inventario")
        foodButton.addTarget(self, action: #selector(useFood), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        ScreenKit.install(ScreenKit.stack([titleLabel, foodButton, hintLabel, closeButton]), in: self)
    }

    @objc private func useFood() { gameManager.feed() }
    @objc private func close() { onClose?() }
}
