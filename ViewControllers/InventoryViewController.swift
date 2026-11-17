import UIKit

final class InventoryViewController: UIViewController {
    let gameManager: GameManager
    var onClose: (() -> Void)?
    private let titleLabel: UILabel = { ScreenKit.label("Inventario", size: 27, color: ScreenKit.accent, weight: .bold) }()
    private let rationButton: UIButton = { ScreenKit.button("") }()
    private let greensButton: UIButton = { ScreenKit.button("") }()
    private let potionButton: UIButton = { ScreenKit.button("") }()
    private let etherButton: UIButton = { ScreenKit.button("") }()
    private let closeButton: UIButton = { ScreenKit.button("Volver al hábitat") }()
    private let hintLabel: UILabel = { ScreenKit.label("Elige un objeto para cuidar a tu compañero. La cantidad se guarda entre partidas.", size: 14, color: ScreenKit.mutedText) }()
    private lazy var contentStack: UIStackView = {
        ScreenKit.stack([titleLabel, hintLabel, rationButton, greensButton, potionButton, etherButton, closeButton])
    }()

    init(gameManager: GameManager) { self.gameManager = gameManager; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("init(coder:) no está disponible") }

    override func viewDidLoad() {
        super.viewDidLoad()
        ScreenKit.configure(self, title: "Inventario")
        rationButton.addTarget(self, action: #selector(useRation), for: .touchUpInside)
        greensButton.addTarget(self, action: #selector(useGreens), for: .touchUpInside)
        potionButton.addTarget(self, action: #selector(usePotion), for: .touchUpInside)
        etherButton.addTarget(self, action: #selector(useEther), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        ScreenKit.installScrollable(contentStack, in: self)
        gameManager.onChange = { [weak self] in self?.refreshInventory() }
        refreshInventory()
    }

    private func refreshInventory() {
        update(rationButton, item: .ration)
        update(greensButton, item: .gysahlGreens)
        update(potionButton, item: .potion)
        update(etherButton, item: .ether)
    }

    private func update(_ button: UIButton, item: ConsumableItem) {
        let quantity = gameManager.inventory[item, default: 0]
        let effect: String
        switch item {
        case .ration: effect = "+25 saciedad"
        case .gysahlGreens: effect = "+45 saciedad · +5 ánimo"
        case .potion: effect = "+30 energía"
        case .ether: effect = "+30 ánimo"
        }
        ScreenKit.setTitle("\(item.emoji)  \(item.name)  ×\(quantity)\n\(effect)", on: button)
        button.isEnabled = quantity > 0
        button.alpha = quantity > 0 ? 1 : 0.45
    }

    @objc private func useRation() { _ = gameManager.use(.ration) }
    @objc private func useGreens() { _ = gameManager.use(.gysahlGreens) }
    @objc private func usePotion() { _ = gameManager.use(.potion) }
    @objc private func useEther() { _ = gameManager.use(.ether) }
    @objc private func close() { onClose?() }
}
