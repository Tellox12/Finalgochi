import UIKit

final class ShopViewController: UIViewController {
    let gameManager: GameManager
    var onClose: (() -> Void)?
    var onOpenMateria: (() -> Void)?

    private let titleLabel: UILabel = { ScreenKit.label("Bazar del Cristal", size: 27, color: ScreenKit.accent, weight: .bold) }()
    private let gilLabel: UILabel = { ScreenKit.label("", size: 17, color: ScreenKit.gold, weight: .bold) }()
    private let equipmentTitleLabel: UILabel = { ScreenKit.label("🧥  EQUIPO Y VESTIMENTA", size: 12, color: ScreenKit.gold, weight: .bold) }()
    private let materiaTitleLabel: UILabel = { ScreenKit.label("🔮  MATERIAS", size: 12, color: ScreenKit.gold, weight: .bold) }()
    private let suppliesTitleLabel: UILabel = { ScreenKit.label("⚗️  SUMINISTROS", size: 12, color: ScreenKit.gold, weight: .bold) }()
    private let messageLabel: UILabel = { ScreenKit.label("Cada pieza ocupa una ranura y aporta una ventaja pasiva.", size: 13, color: ScreenKit.mutedText) }()
    private let materiaButton: UIButton = { ScreenKit.button("Gestionar materias y habilidades  ›") }()
    private let closeButton: UIButton = { ScreenKit.button("Volver al hábitat") }()

    private let equipmentButtons: [StoreItem: UIButton] = {
        Dictionary(uniqueKeysWithValues: StoreItem.allCases.map { ($0, ScreenKit.button("")) })
    }()
    private let materiaButtons: [Materia: UIButton] = {
        Dictionary(uniqueKeysWithValues: Materia.allCases.map { ($0, ScreenKit.button("")) })
    }()
    private let consumableButtons: [ConsumableItem: UIButton] = {
        Dictionary(uniqueKeysWithValues: ConsumableItem.allCases.map { ($0, ScreenKit.button("")) })
    }()

    private lazy var contentStack: UIStackView = {
        var views: [UIView] = [titleLabel, gilLabel, equipmentTitleLabel]
        views.append(contentsOf: StoreItem.allCases.compactMap { equipmentButtons[$0] })
        views.append(materiaTitleLabel)
        views.append(contentsOf: Materia.allCases.compactMap { materiaButtons[$0] })
        views.append(materiaButton)
        views.append(suppliesTitleLabel)
        views.append(contentsOf: ConsumableItem.allCases.compactMap { consumableButtons[$0] })
        views.append(messageLabel)
        views.append(closeButton)
        return ScreenKit.stack(views, spacing: 12)
    }()

    init(gameManager: GameManager) {
        self.gameManager = gameManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no está disponible") }

    override func viewDidLoad() {
        super.viewDidLoad()
        ScreenKit.configure(self, title: "Bazar")
        for (item, button) in equipmentButtons {
            button.accessibilityIdentifier = item.rawValue
            button.addTarget(self, action: #selector(equipmentButtonPressed(_:)), for: .touchUpInside)
        }
        for (materia, button) in materiaButtons {
            button.accessibilityIdentifier = materia.rawValue
            button.addTarget(self, action: #selector(materiaButtonPressed(_:)), for: .touchUpInside)
        }
        for (item, button) in consumableButtons {
            button.accessibilityIdentifier = item.rawValue
            button.addTarget(self, action: #selector(consumableButtonPressed(_:)), for: .touchUpInside)
        }
        materiaButton.addTarget(self, action: #selector(openMateria), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        ScreenKit.setBackground(UIColor(red: 0.28, green: 0.31, blue: 0.53, alpha: 1), on: materiaButton)
        ScreenKit.installScrollable(contentStack, in: self)
        gameManager.onChange = { [weak self] in self?.refresh() }
        refresh()
    }

    private func refresh() {
        gilLabel.text = "◈  \(gameManager.gil) GIL DISPONIBLES"
        for item in StoreItem.allCases {
            guard let button = equipmentButtons[item] else { continue }
            let isOwned = gameManager.ownedItems.contains(item)
            let isEquipped = gameManager.equippedItems[item.slot] == item
            let title: String
            if isEquipped {
                title = "✅  \(item.emoji)  \(item.name)  ·  \(item.slot.displayName)\nEQUIPADO  ·  Toca para retirar"
            } else if isOwned {
                title = "\(item.emoji)  \(item.name)  ·  \(item.slot.displayName)\nEquipar  ·  \(item.bonusDescription)"
            } else {
                title = "\(item.emoji)  \(item.name)  ·  \(item.price) Gil\n\(item.bonusDescription)"
            }
            ScreenKit.setTitle(title, on: button)
            let canUse = isOwned || gameManager.gil >= item.price
            button.isEnabled = canUse
            button.alpha = canUse ? 1 : 0.45
        }

        for materia in Materia.allCases {
            guard let button = materiaButtons[materia] else { continue }
            let isOwned = gameManager.ownedMateria.contains(materia)
            let isEquipped = gameManager.equippedMateria.contains(materia)
            let title: String
            if isEquipped {
                title = "✅  \(materia.emoji)  \(materia.name)  ·  \(materia.magicCost) PM\nEQUIPADA  ·  Toca para liberar ranura"
            } else if isOwned {
                title = "\(materia.emoji)  \(materia.name)\nEquipar  ·  \(materia.description)"
            } else {
                title = "Comprar \(materia.emoji)  \(materia.name)  ·  \(materia.price) Gil\n\(materia.description)"
            }
            ScreenKit.setTitle(title, on: button)
            let canUse = isOwned || gameManager.gil >= materia.price
            button.isEnabled = canUse
            button.alpha = canUse ? 1 : 0.45
        }

        for item in ConsumableItem.allCases {
            guard let button = consumableButtons[item] else { continue }
            let stock = gameManager.inventory[item, default: 0]
            ScreenKit.setTitle("Comprar \(item.emoji)  \(item.name)  ·  \(item.price) Gil\nEn mochila: ×\(stock)", on: button)
            let canBuy = gameManager.gil >= item.price
            button.isEnabled = canBuy
            button.alpha = canBuy ? 1 : 0.45
        }
    }

    @objc private func equipmentButtonPressed(_ sender: UIButton) {
        guard let rawValue = sender.accessibilityIdentifier, let item = StoreItem(rawValue: rawValue) else { return }
        if gameManager.ownedItems.contains(item) {
            if gameManager.equippedItems[item.slot] == item {
                gameManager.unequip(item.slot)
                messageLabel.text = "Retiraste \(item.name)."
            } else {
                _ = gameManager.equip(item)
                messageLabel.text = "\(item.name) equipado. \(item.bonusDescription)."
            }
        } else if gameManager.buy(item) {
            messageLabel.text = "\(item.name) añadido a tu colección. Tócalo de nuevo para equiparlo."
        } else {
            messageLabel.text = "Te faltan Gil para esta pieza."
        }
        refresh()
    }

    @objc private func materiaButtonPressed(_ sender: UIButton) {
        guard let rawValue = sender.accessibilityIdentifier, let materia = Materia(rawValue: rawValue) else { return }
        if gameManager.ownedMateria.contains(materia) {
            if gameManager.toggleMateria(materia) {
                messageLabel.text = gameManager.equippedMateria.contains(materia)
                    ? "\(materia.name) equipada. Su ventaja pasiva ya está activa."
                    : "Liberaste la ranura de \(materia.name)."
            } else {
                messageLabel.text = "Solo puedes llevar \(GameManager.maximumEquippedMateria) materias equipadas a la vez."
            }
        } else if gameManager.buy(materia) {
            messageLabel.text = "Materia \(materia.name) adquirida. Equípala para lanzar su habilidad."
        } else {
            messageLabel.text = "Te faltan Gil para esta materia."
        }
        refresh()
    }

    @objc private func consumableButtonPressed(_ sender: UIButton) {
        guard let rawValue = sender.accessibilityIdentifier, let item = ConsumableItem(rawValue: rawValue) else { return }
        if gameManager.buy(item) {
            messageLabel.text = "Compraste \(item.name). En mochila: ×\(gameManager.inventory[item, default: 0])."
        } else {
            messageLabel.text = "Te faltan Gil para comprar \(item.name)."
        }
        refresh()
    }

    @objc private func openMateria() { onOpenMateria?() }
    @objc private func close() { onClose?() }
}
