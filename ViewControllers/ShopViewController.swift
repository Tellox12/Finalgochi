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
    private let rationButton: UIButton = { ScreenKit.button("") }()
    private let greensButton: UIButton = { ScreenKit.button("") }()
    private let potionButton: UIButton = { ScreenKit.button("") }()
    private let etherButton: UIButton = { ScreenKit.button("") }()
    private let messageLabel: UILabel = { ScreenKit.label("Los accesorios se guardan en tu colección.", size: 14, color: .lightGray) }()
    private let consumablesTitleLabel: UILabel = { ScreenKit.label("Consumibles", size: 21, color: ScreenKit.accent, weight: .semibold) }()
    private let closeButton: UIButton = { ScreenKit.button("Volver") }()
    private lazy var contentStack: UIStackView = {
        ScreenKit.stack([titleLabel, gilLabel, ribbonButton, featherButton, hatButton, messageLabel, consumablesTitleLabel, rationButton, greensButton, potionButton, etherButton, closeButton], spacing: 13)
    }()

    init(gameManager: GameManager) { self.gameManager = gameManager; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("init(coder:) no está disponible") }

    override func viewDidLoad() {
        super.viewDidLoad()
        ScreenKit.configure(self, title: "Tienda")
        ribbonButton.addTarget(self, action: #selector(buyRibbon), for: .touchUpInside)
        featherButton.addTarget(self, action: #selector(buyFeather), for: .touchUpInside)
        hatButton.addTarget(self, action: #selector(buyHat), for: .touchUpInside)
        rationButton.addTarget(self, action: #selector(buyRation), for: .touchUpInside)
        greensButton.addTarget(self, action: #selector(buyGreens), for: .touchUpInside)
        potionButton.addTarget(self, action: #selector(buyPotion), for: .touchUpInside)
        etherButton.addTarget(self, action: #selector(buyEther), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        ScreenKit.installScrollable(contentStack, in: self)
        gameManager.onChange = { [weak self] in self?.updateView() }
        updateView()
    }

    private func purchase(_ item: StoreItem) {
        if gameManager.ownedItems.contains(item) {
            let newItem = gameManager.equippedAccessory == item ? nil : item
            _ = gameManager.equip(newItem)
            messageLabel.text = newItem == nil ? "Accesorio quitado." : "¡\(item.name) equipado!"
        } else if gameManager.buy(item) {
            messageLabel.text = "¡Compraste \(item.name)! Ahora puedes equiparlo."
            onPurchase?(item)
        } else {
            messageLabel.text = "Te faltan Gil para comprarlo."
        }
        updateView()
    }

    private func purchase(_ item: ConsumableItem) {
        if gameManager.buy(item) {
            messageLabel.text = "Compraste \(item.name). Tienes ×\(gameManager.inventory[item, default: 0])."
        } else {
            messageLabel.text = "Te faltan Gil para comprar \(item.name)."
        }
        updateView()
    }

    private func updateView() {
        gilLabel.text = "Tienes \(gameManager.gil) Gil"
        updateAccessoryButton(ribbonButton, item: .ribbon)
        updateAccessoryButton(featherButton, item: .feather)
        updateAccessoryButton(hatButton, item: .cactusHat)
        updateConsumableButton(rationButton, item: .ration)
        updateConsumableButton(greensButton, item: .gysahlGreens)
        updateConsumableButton(potionButton, item: .potion)
        updateConsumableButton(etherButton, item: .ether)
    }

    private func updateAccessoryButton(_ button: UIButton, item: StoreItem) {
        let title: String
        if gameManager.equippedAccessory == item {
            title = "✅ Quitar \(item.emoji) \(item.name)"
        } else if gameManager.ownedItems.contains(item) {
            title = "Equipar \(item.emoji) \(item.name)"
        } else {
            title = "Comprar \(item.emoji) \(item.name)  ·  \(item.price) Gil"
        }
        ScreenKit.setTitle(title, on: button)
    }

    private func updateConsumableButton(_ button: UIButton, item: ConsumableItem) {
        ScreenKit.setTitle("Comprar \(item.emoji) \(item.name)  ·  \(item.price) Gil", on: button)
    }

    @objc private func buyRibbon() { purchase(.ribbon) }
    @objc private func buyFeather() { purchase(.feather) }
    @objc private func buyHat() { purchase(.cactusHat) }
    @objc private func buyRation() { purchase(.ration) }
    @objc private func buyGreens() { purchase(.gysahlGreens) }
    @objc private func buyPotion() { purchase(.potion) }
    @objc private func buyEther() { purchase(.ether) }
    @objc private func close() { onClose?() }
}
