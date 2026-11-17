import UIKit

final class CharacterSelectViewController: UIViewController {
    var onCharacterSelected: ((PetKind) -> Void)?

    private let eyebrowLabel: UILabel = {
        ScreenKit.label("CRÓNICAS DEL CRISTAL  /  SELECCIÓN", size: 11, color: ScreenKit.gold, weight: .bold)
    }()
    private let titleLabel: UILabel = {
        ScreenKit.label("Elige a tu compañero", size: 28, color: .white, weight: .bold)
    }()
    private let subtitleLabel: UILabel = {
        ScreenKit.label("Cada criatura tiene su propio encanto.\n¿Quién viajará contigo?", size: 15, color: ScreenKit.mutedText)
    }()
    private let moogleButton: UIButton = {
        CharacterSelectViewController.makeCharacterCard(title: "☁️\nMOOGLE\nCariñoso y curioso", color: UIColor(red: 0.25, green: 0.40, blue: 0.59, alpha: 1))
    }()
    private let chocoboButton: UIButton = {
        CharacterSelectViewController.makeCharacterCard(title: "🐤\nCHOCOBO\nRápido y valiente", color: UIColor(red: 0.53, green: 0.38, blue: 0.16, alpha: 1))
    }()
    private let cactilioButton: UIButton = {
        CharacterSelectViewController.makeCharacterCard(title: "🌵\nCACTILIO\nTranquilo y resistente", color: UIColor(red: 0.19, green: 0.43, blue: 0.34, alpha: 1))
    }()
    private lazy var contentStack: UIStackView = {
        ScreenKit.stack([eyebrowLabel, titleLabel, subtitleLabel, moogleButton, chocoboButton, cactilioButton], spacing: 14)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        ScreenKit.configure(self, title: "Elige mascota")
        moogleButton.addTarget(self, action: #selector(selectMoogle), for: .touchUpInside)
        chocoboButton.addTarget(self, action: #selector(selectChocobo), for: .touchUpInside)
        cactilioButton.addTarget(self, action: #selector(selectCactilio), for: .touchUpInside)
        ScreenKit.installScrollable(contentStack, in: self)
    }

    private static func makeCharacterCard(title: String, color: UIColor) -> UIButton {
        let button = ScreenKit.button(title)
        ScreenKit.setBackground(color.withAlphaComponent(0.48), on: button)
        button.layer.cornerRadius = 20
        button.layer.borderWidth = 1
        button.layer.borderColor = color.withAlphaComponent(0.9).cgColor
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        button.titleLabel?.numberOfLines = 3
        button.titleLabel?.lineBreakMode = .byWordWrapping
        button.titleLabel?.textAlignment = .center
        button.accessibilityHint = "Toca dos veces para elegir este compañero"
        button.heightAnchor.constraint(equalToConstant: 132).isActive = true
        return button
    }

    @objc private func selectMoogle() { onCharacterSelected?(.moogle) }
    @objc private func selectChocobo() { onCharacterSelected?(.chocobo) }
    @objc private func selectCactilio() { onCharacterSelected?(.cactilio) }
}
