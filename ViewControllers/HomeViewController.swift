import UIKit

final class HomeViewController: UIViewController {
    let gameManager: GameManager
    var onOpenActions: (() -> Void)?
    var onOpenInventory: (() -> Void)?
    var onOpenCharacterSheet: (() -> Void)?
    var onOpenShop: (() -> Void)?
    var onOpenSettings: (() -> Void)?
    var onGameOver: (() -> Void)?

    private let petLabel: UILabel = { ScreenKit.label("", size: 76) }()
    private let nameLabel: UILabel = { ScreenKit.label("", size: 27, color: ScreenKit.accent, weight: .bold) }()
    private let statsLabel: UILabel = { ScreenKit.label("", size: 17, color: .white) }()
    private let gilLabel: UILabel = { ScreenKit.label("", size: 16, color: .systemYellow, weight: .semibold) }()
    private let actionsButton: UIButton = { ScreenKit.button("⚔️  Comandos") }()
    private let inventoryButton: UIButton = { ScreenKit.button("🎒  Inventario") }()
    private let sheetButton: UIButton = { ScreenKit.button("📜  Estado") }()
    private let shopButton: UIButton = { ScreenKit.button("🛍️  Tienda") }()
    private let settingsButton: UIButton = { ScreenKit.button("⚙️  Ajustes") }()

    init(gameManager: GameManager) { self.gameManager = gameManager; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("init(coder:) no está disponible") }

    override func viewDidLoad() {
        super.viewDidLoad()
        ScreenKit.configure(self, title: "Hábitat")
        actionsButton.addTarget(self, action: #selector(openActions), for: .touchUpInside)
        inventoryButton.addTarget(self, action: #selector(openInventory), for: .touchUpInside)
        sheetButton.addTarget(self, action: #selector(openSheet), for: .touchUpInside)
        shopButton.addTarget(self, action: #selector(openShop), for: .touchUpInside)
        settingsButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        let stack = ScreenKit.stack([petLabel, nameLabel, statsLabel, gilLabel, actionsButton, inventoryButton, sheetButton, shopButton, settingsButton], spacing: 10)
        stack.setCustomSpacing(22, after: gilLabel)
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])
        gameManager.onChange = { [weak self] in self?.refresh() }
        gameManager.onGameOver = { [weak self] in self?.onGameOver?() }
        refresh()
    }

    private func refresh() {
        guard let pet = gameManager.pet else { return }
        petLabel.text = pet.kind.emoji
        nameLabel.text = pet.kind.displayName + " · Nv. \(pet.level)"
        statsLabel.text = "🍗 Hambre  \(Int(pet.hunger))%\n💖 Felicidad  \(Int(pet.happiness))%\n🌙 Sueño  \(Int(pet.energy))%"
        gilLabel.text = "Gil: \(gameManager.gil)"
    }

    @objc private func openActions() { onOpenActions?() }
    @objc private func openInventory() { onOpenInventory?() }
    @objc private func openSheet() { onOpenCharacterSheet?() }
    @objc private func openShop() { onOpenShop?() }
    @objc private func openSettings() { onOpenSettings?() }
}
