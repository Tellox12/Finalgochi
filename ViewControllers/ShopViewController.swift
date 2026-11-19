import UIKit

final class ShopViewController: UIViewController {
    let gameManager: GameManager
    var onClose: (() -> Void)?
    var onOpenMateria: (() -> Void)?

    private var observerToken: UUID?

    private let titleLabel = ScreenKit.label("Bazar del Cristal", size: 27, color: .white, weight: .bold, textStyle: .largeTitle)
    private let subtitleLabel: UILabel = {
        let label = ScreenKit.label("Equipo, materias y detalles para tu refugio.", size: 14, color: ScreenKit.mutedText)
        label.textAlignment = .left
        return label
    }()
    private let gilLabel = ScreenKit.pill("0 GIL", color: ScreenKit.gold)
    private let categoryControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["Equipo", "Materia", "Objetos", "Hábitat"])
        control.translatesAutoresizingMaskIntoConstraints = false
        control.selectedSegmentIndex = 0
        control.selectedSegmentTintColor = ScreenKit.accentSoft
        control.setTitleTextAttributes([
            .foregroundColor: ScreenKit.mutedText,
            .font: ScreenKit.roundedFont(size: 12.5, weight: .semibold, textStyle: .caption1)
        ], for: .normal)
        control.setTitleTextAttributes([
            .foregroundColor: UIColor.white,
            .font: ScreenKit.roundedFont(size: 12.5, weight: .bold, textStyle: .caption1)
        ], for: .selected)
        return control
    }()
    private let equipmentTitleLabel = ScreenKit.sectionTitle("EQUIPO Y VESTIMENTA", color: ScreenKit.gold)
    private let materiaTitleLabel = ScreenKit.sectionTitle("MATERIAS", color: ScreenKit.gold)
    private let suppliesTitleLabel = ScreenKit.sectionTitle("SUMINISTROS", color: ScreenKit.gold)
    private let habitatTitleLabel = ScreenKit.sectionTitle("DECORA TU HÁBITAT", color: ScreenKit.gold)
    private let messageLabel: UILabel = {
        let label = ScreenKit.label("Cada pieza ocupa una ranura y aporta una ventaja pasiva.", size: 12.5, color: ScreenKit.mutedText)
        label.textAlignment = .left
        return label
    }()
    private let materiaButton = MenuCardControl()
    private let closeButton = ScreenKit.button("Volver al hábitat", symbol: "chevron.left", style: .ghost)

    private let equipmentRows: [StoreItem: MenuCardControl] = {
        Dictionary(uniqueKeysWithValues: StoreItem.allCases.map { ($0, MenuCardControl()) })
    }()
    private let materiaRows: [Materia: MenuCardControl] = {
        Dictionary(uniqueKeysWithValues: Materia.allCases.map { ($0, MenuCardControl()) })
    }()
    private let consumableRows: [ConsumableItem: MenuCardControl] = {
        Dictionary(uniqueKeysWithValues: ConsumableItem.allCases.map { ($0, MenuCardControl()) })
    }()
    private let decorationRows: [HabitatDecoration: MenuCardControl] = {
        Dictionary(uniqueKeysWithValues: HabitatDecoration.allCases.map { ($0, MenuCardControl()) })
    }()

    private lazy var equipmentSection: UIStackView = {
        var views: [UIView] = [equipmentTitleLabel]
        views.append(contentsOf: StoreItem.allCases.compactMap { equipmentRows[$0] })
        return ScreenKit.stack(views, spacing: 10)
    }()
    private lazy var materiaSection: UIStackView = {
        var views: [UIView] = [materiaTitleLabel]
        views.append(contentsOf: Materia.allCases.compactMap { materiaRows[$0] })
        views.append(materiaButton)
        return ScreenKit.stack(views, spacing: 10)
    }()
    private lazy var suppliesSection: UIStackView = {
        var views: [UIView] = [suppliesTitleLabel]
        views.append(contentsOf: ConsumableItem.allCases.compactMap { consumableRows[$0] })
        return ScreenKit.stack(views, spacing: 10)
    }()
    private lazy var habitatSection: UIStackView = {
        var views: [UIView] = [habitatTitleLabel]
        views.append(contentsOf: HabitatDecoration.allCases.compactMap { decorationRows[$0] })
        return ScreenKit.stack(views, spacing: 10)
    }()
    private lazy var headerStack: UIStackView = {
        let stack = ScreenKit.headerRow(title: subtitleLabel, trailing: [gilLabel])
        stack.distribution = .fill
        return stack
    }()
    private lazy var contentStack: UIStackView = {
        ScreenKit.stack([titleLabel, headerStack, categoryControl, equipmentSection, materiaSection, suppliesSection, habitatSection, messageLabel, closeButton], spacing: 14)
    }()

    init(gameManager: GameManager) {
        self.gameManager = gameManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no está disponible") }

    override func viewDidLoad() {
        super.viewDidLoad()
        ScreenKit.configure(self, title: "Bazar")
        titleLabel.textAlignment = .left
        for (item, control) in equipmentRows {
            control.accessibilityIdentifier = item.rawValue
            control.addTarget(self, action: #selector(equipmentPressed(_:)), for: .touchUpInside)
        }
        for (materia, control) in materiaRows {
            control.accessibilityIdentifier = materia.rawValue
            control.addTarget(self, action: #selector(materiaPressed(_:)), for: .touchUpInside)
        }
        for (item, control) in consumableRows {
            control.accessibilityIdentifier = item.rawValue
            control.addTarget(self, action: #selector(consumablePressed(_:)), for: .touchUpInside)
        }
        for (decoration, control) in decorationRows {
            control.accessibilityIdentifier = decoration.rawValue
            control.addTarget(self, action: #selector(decorationPressed(_:)), for: .touchUpInside)
        }
        materiaButton.update(
            symbolName: "circle.hexagongrid.fill",
            title: "Gestionar materias",
            subtitle: "Equipa hasta dos pasivas y lanza habilidades.",
            tint: ScreenKit.accent
        )
        materiaButton.addTarget(self, action: #selector(openMateria), for: .touchUpInside)
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        categoryControl.addTarget(self, action: #selector(categoryChanged), for: .valueChanged)

        materiaSection.isHidden = true
        suppliesSection.isHidden = true
        habitatSection.isHidden = true
        ScreenKit.installScrollable(contentStack, in: self)
        observerToken = gameManager.addObserver { [weak self] in self?.refresh() }
        refresh()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        gameManager.updateElapsedTime()
        refresh()
    }

    deinit { gameManager.removeObserver(observerToken) }

    private func refresh() {
        gilLabel.attributedText = ScreenKit.symbolText("diamond.fill", text: " \(gameManager.gil) GIL ", size: 12, weight: .bold, color: ScreenKit.gold, textStyle: .caption1)

        for item in StoreItem.allCases {
            guard let control = equipmentRows[item] else { continue }
            let isOwned = gameManager.ownedItems.contains(item)
            let isEquipped = gameManager.equippedItems[item.slot] == item
            control.update(
                symbolName: item.symbolName,
                title: item.name,
                subtitle: item.bonusDescription,
                footnote: isEquipped
                    ? "EQUIPADO · TOCA PARA RETIRAR"
                    : (isOwned ? "EN TU COLECCIÓN · TOCA PARA EQUIPAR" : "\(item.price) GIL · \(item.slot.displayName.uppercased())"),
                tint: isEquipped ? ScreenKit.mint : ScreenKit.accent,
                selected: isEquipped
            )
            control.isEnabled = isOwned || gameManager.gil >= item.price
        }

        for materia in Materia.allCases {
            guard let control = materiaRows[materia] else { continue }
            let isOwned = gameManager.ownedMateria.contains(materia)
            let isEquipped = gameManager.equippedMateria.contains(materia)
            control.update(
                symbolName: materia.symbolName,
                title: materia.name,
                subtitle: materia.description,
                footnote: isEquipped
                    ? "EQUIPADA · TOCA PARA LIBERAR RANURA"
                    : (isOwned ? "EN COLECCIÓN · \(materia.magicCost) PM" : "\(materia.price) GIL · \(materia.magicCost) PM"),
                tint: isEquipped ? ScreenKit.mint : ScreenKit.rose,
                selected: isEquipped
            )
            control.isEnabled = isOwned || gameManager.gil >= materia.price
        }

        for item in ConsumableItem.allCases {
            guard let control = consumableRows[item] else { continue }
            let stock = gameManager.inventory[item, default: 0]
            control.update(
                symbolName: item.symbolName,
                title: item.name,
                subtitle: item.effectDescription,
                footnote: "\(item.price) GIL · EN MOCHILA ×\(stock)",
                tint: ScreenKit.hunger
            )
            control.isEnabled = gameManager.gil >= item.price && stock < 999
        }

        for decoration in HabitatDecoration.allCases {
            guard let control = decorationRows[decoration] else { continue }
            let isOwned = gameManager.progression.ownedDecorations.contains(decoration)
            let isEquipped = gameManager.progression.equippedDecoration == decoration
            control.update(
                symbolName: decoration.symbolName,
                title: decoration.name,
                subtitle: "Un detalle más para tu refugio.",
                footnote: isEquipped
                    ? "APLICADO · TOCA PARA RETIRAR"
                    : (isOwned ? "EN COLECCIÓN · TOCA PARA APLICAR" : "\(decoration.price) GIL"),
                tint: isEquipped ? ScreenKit.mint : ScreenKit.gold,
                selected: isEquipped
            )
            control.isEnabled = isOwned || gameManager.gil >= decoration.price
        }
    }

    @objc private func equipmentPressed(_ sender: MenuCardControl) {
        guard let rawValue = sender.accessibilityIdentifier, let item = StoreItem(rawValue: rawValue) else { return }
        if gameManager.ownedItems.contains(item) {
            if gameManager.equippedItems[item.slot] == item {
                gameManager.unequip(item.slot)
                show("Retiraste \(item.name).")
            } else {
                _ = gameManager.equip(item)
                show("\(item.name) equipado. \(item.bonusDescription).")
            }
        } else if gameManager.buy(item) {
            show("\(item.name) añadido a tu colección. Tócalo de nuevo para equiparlo.")
        } else {
            show("Te faltan Gil para esta pieza.", isError: true)
        }
        refresh()
    }

    @objc private func materiaPressed(_ sender: MenuCardControl) {
        guard let rawValue = sender.accessibilityIdentifier, let materia = Materia(rawValue: rawValue) else { return }
        if gameManager.ownedMateria.contains(materia) {
            if gameManager.toggleMateria(materia) {
                show(gameManager.equippedMateria.contains(materia)
                    ? "\(materia.name) equipada. Su ventaja pasiva ya está activa."
                    : "Liberaste la ranura de \(materia.name).")
            } else {
                show("Solo puedes llevar \(GameManager.maximumEquippedMateria) materias equipadas a la vez.", isError: true)
            }
        } else if gameManager.buy(materia) {
            show("Materia \(materia.name) adquirida. Equípala para lanzar su habilidad.")
        } else {
            show("Te faltan Gil para esta materia.", isError: true)
        }
        refresh()
    }

    @objc private func consumablePressed(_ sender: MenuCardControl) {
        guard let rawValue = sender.accessibilityIdentifier, let item = ConsumableItem(rawValue: rawValue) else { return }
        if gameManager.buy(item) {
            show("Compraste \(item.name). En mochila: ×\(gameManager.inventory[item, default: 0]).")
        } else {
            show("No puedes comprar \(item.name) ahora mismo.", isError: true)
        }
        refresh()
    }

    @objc private func decorationPressed(_ sender: MenuCardControl) {
        guard let rawValue = sender.accessibilityIdentifier,
              let decoration = HabitatDecoration(rawValue: rawValue) else { return }
        if gameManager.progression.ownedDecorations.contains(decoration) {
            _ = gameManager.equip(gameManager.progression.equippedDecoration == decoration ? nil : decoration)
            show(gameManager.progression.equippedDecoration == decoration
                ? "\(decoration.name) transforma tu refugio."
                : "Decoración retirada.")
        } else if gameManager.buy(decoration) {
            show("\(decoration.name) añadido a tu colección. Tócalo para aplicarlo.")
        } else {
            show("Te faltan Gil para decorar el hábitat.", isError: true)
        }
        refresh()
    }

    private func show(_ text: String, isError: Bool = false) {
        messageLabel.text = text
        messageLabel.textColor = isError ? ScreenKit.hunger : ScreenKit.mint
    }

    @objc private func openMateria() { onOpenMateria?() }
    @objc private func close() { onClose?() }

    @objc private func categoryChanged() {
        UIView.animate(withDuration: 0.18) {
            self.equipmentSection.isHidden = self.categoryControl.selectedSegmentIndex != 0
            self.materiaSection.isHidden = self.categoryControl.selectedSegmentIndex != 1
            self.suppliesSection.isHidden = self.categoryControl.selectedSegmentIndex != 2
            self.habitatSection.isHidden = self.categoryControl.selectedSegmentIndex != 3
            self.contentStack.layoutIfNeeded()
        }
    }
}
