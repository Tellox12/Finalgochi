import UIKit

final class InventoryViewController: UIViewController {
    let gameManager: GameManager
    var onClose: (() -> Void)?

    private var observerToken: UUID?

    private let titleLabel = ScreenKit.label("Mochila", size: 27, color: .white, weight: .bold, textStyle: .largeTitle)
    private let hintLabel: UILabel = {
        let label = ScreenKit.label("Elige un objeto para cuidar a tu compañero. Solo se consume si tiene efecto.", size: 14, color: ScreenKit.mutedText)
        label.textAlignment = .left
        return label
    }()
    private let messageLabel: UILabel = {
        let label = ScreenKit.label("", size: 12.5, color: ScreenKit.mint)
        label.textAlignment = .left
        return label
    }()
    private let rationRow = MenuCardControl()
    private let greensRow = MenuCardControl()
    private let potionRow = MenuCardControl()
    private let etherRow = MenuCardControl()
    private let closeButton = ScreenKit.button("Volver al hábitat", symbol: "chevron.left", style: .ghost)

    private lazy var contentStack: UIStackView = {
        ScreenKit.stack([titleLabel, hintLabel, rationRow, greensRow, potionRow, etherRow, messageLabel, closeButton], spacing: 12)
    }()

    init(gameManager: GameManager) {
        self.gameManager = gameManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no está disponible") }

    override func viewDidLoad() {
        super.viewDidLoad()
        ScreenKit.configure(self, title: "Mochila")
        titleLabel.textAlignment = .left
        rationRow.addTarget(self, action: #selector(useRation), for: .touchUpInside)
        greensRow.addTarget(self, action: #selector(useGreens), for: .touchUpInside)
        potionRow.addTarget(self, action: #selector(usePotion), for: .touchUpInside)
        etherRow.addTarget(self, action: #selector(useEther), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        ScreenKit.installScrollable(contentStack, in: self)
        observerToken = gameManager.addObserver { [weak self] in self?.refreshInventory() }
        refreshInventory()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        gameManager.updateElapsedTime()
        refreshInventory()
    }

    deinit { gameManager.removeObserver(observerToken) }

    private func refreshInventory() {
        update(rationRow, item: .ration, symbol: "takeoutbag.and.cup.and.straw.fill", effect: "Recupera 25 de saciedad.", tint: ScreenKit.hunger)
        update(greensRow, item: .gysahlGreens, symbol: "leaf.fill", effect: "Recupera 45 de saciedad y 5 de ánimo.", tint: ScreenKit.mint)
        update(potionRow, item: .potion, symbol: "bolt.heart.fill", effect: "Recupera 30 de energía.", tint: ScreenKit.sky)
        update(etherRow, item: .ether, symbol: "sparkles", effect: "Recupera 30 de ánimo.", tint: ScreenKit.rose)
    }

    private func update(_ control: MenuCardControl, item: ConsumableItem, symbol: String, effect: String, tint: UIColor) {
        let quantity = gameManager.inventory[item, default: 0]
        let canUse = gameManager.canUse(item)
        control.update(
            symbolName: symbol,
            title: item.name,
            subtitle: effect,
            footnote: quantity > 0 ? (canUse ? "×\(quantity) · TOCA PARA USAR" : "×\(quantity) · SIN EFECTO AHORA") : "AGOTADO",
            tint: tint
        )
        control.isEnabled = quantity > 0 && canUse
    }

    private func use(_ item: ConsumableItem) {
        if gameManager.use(item) {
            messageLabel.textColor = ScreenKit.mint
            messageLabel.text = "\(item.name) usada. Quedan ×\(gameManager.inventory[item, default: 0])."
        } else {
            messageLabel.textColor = ScreenKit.hunger
            messageLabel.text = gameManager.pet?.isSleeping == true
                ? "Tu compañero está durmiendo. Despiértalo para darle objetos."
                : "Ese objeto no haría efecto ahora mismo."
        }
        refreshInventory()
    }

    @objc private func useRation() { use(.ration) }
    @objc private func useGreens() { use(.gysahlGreens) }
    @objc private func usePotion() { use(.potion) }
    @objc private func useEther() { use(.ether) }
    @objc private func close() { onClose?() }
}
