import UIKit

final class CharacterSheetViewController: UIViewController {
    let gameManager: GameManager
    var onClose: (() -> Void)?
    private let titleLabel: UILabel = { ScreenKit.label("Ficha de aventurero", size: 27, color: ScreenKit.accent, weight: .bold) }()
    private let detailLabel: UILabel = { ScreenKit.label("", size: 19) }()
    private let closeButton: UIButton = { ScreenKit.button("Cerrar") }()
    private lazy var contentStack: UIStackView = {
        ScreenKit.stack([titleLabel, detailLabel, closeButton], spacing: 20)
    }()

    init(gameManager: GameManager) { self.gameManager = gameManager; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("init(coder:) no está disponible") }

    override func viewDidLoad() {
        super.viewDidLoad()
        ScreenKit.configure(self, title: "Ficha")
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        if let pet = gameManager.pet {
            let accessory = gameManager.equippedAccessory.map { "\($0.emoji) \($0.name)" } ?? "Ninguno"
            let inventory = ConsumableItem.allCases
                .map { "\($0.emoji) \($0.name): \(gameManager.inventory[$0, default: 0])" }
                .joined(separator: "\n")
            detailLabel.text = "\(pet.kind.emoji)  \(pet.kind.displayName)\n\nNivel  \(pet.level)\nExperiencia  \(pet.experience) / \(pet.nextLevelExperience)\n\nHambre  \(Int(pet.hunger))%\nFelicidad  \(Int(pet.happiness))%\nSueño  \(Int(pet.energy))%\n\nAccesorio  \(accessory)\nGil  \(gameManager.gil)\n\nInventario\n\(inventory)"
        }
        ScreenKit.install(contentStack, in: self)
    }

    @objc private func close() { onClose?() }
}
