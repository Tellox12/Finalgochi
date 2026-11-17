import UIKit

final class ShopViewController: UIViewController {
    let gameManager: GameManager
    var onClose: (() -> Void)?
    var onPurchase: ((StoreItem) -> Void)?
    private let titleLabel: UILabel = { ScreenKit.label("Mercado de accesorios", size: 26, color: ScreenKit.accent, weight: .bold) }()
    private let gilLabel: UILabel = { ScreenKit.label("", size: 17, color: .systemYellow) }()
    private let ribbonButton: UIButton = { ScreenKit.button("Lazo de kupó  ·  30 Gil") }()
    private let featherButton: UIButton = { ScreenKit.button("Pluma dorada  ·  45 Gil") }()
    private let hatButton: UIButton = { ScreenKit.button("Sombrero espinoso  ·  60 Gil") }()
    private let messageLabel: UILabel = { ScreenKit.label("Los accesorios se guardan en tu colección.", size: 14, color: .lightGray) }()
    private let closeButton: UIButton = { ScreenKit.button("Volver") }()

    init(gameManager: GameManager) { self.gameManager = gameManager; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("init(coder:) no está disponible") }

    override func viewDidLoad() {
        super.viewDidLoad()
        ScreenKit.configure(self, title: "Tienda")
        ribbonButton.addTarget(self, action: #selector(buyRibbon), for: .touchUpInside)
        featherButton.addTarget(self, action: #selector(buyFeather), for: .touchUpInside)
        hatButton.addTarget(self, action: #selector(buyHat), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        ScreenKit.install(ScreenKit.stack([titleLabel, gilLabel, ribbonButton, featherButton, hatButton, messageLabel, closeButton], spacing: 13), in: self)
        updateView()
    }

    private func purchase(_ item: StoreItem) {
        if gameManager.buy(item) {
            messageLabel.text = "¡Compraste \(item.name)!"
        } else {
            messageLabel.text = gameManager.ownedItems.contains(item) ? "Ya tienes este accesorio." : "Te faltan Gil para comprarlo."
        }
        onPurchase?(item)
        updateView()
    }

    private func updateView() {
        gilLabel.text = "Tienes \(gameManager.gil) Gil"
        ribbonButton.isEnabled = !gameManager.ownedItems.contains(.ribbon)
        featherButton.isEnabled = !gameManager.ownedItems.contains(.feather)
        hatButton.isEnabled = !gameManager.ownedItems.contains(.cactusHat)
        [ribbonButton, featherButton, hatButton].forEach { $0.alpha = $0.isEnabled ? 1 : 0.45 }
    }

    @objc private func buyRibbon() { purchase(.ribbon) }
    @objc private func buyFeather() { purchase(.feather) }
    @objc private func buyHat() { purchase(.cactusHat) }
    @objc private func close() { onClose?() }
}
