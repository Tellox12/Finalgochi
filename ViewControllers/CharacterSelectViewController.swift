import UIKit

final class CharacterSelectViewController: UIViewController {
    var onCharacterSelected: ((PetKind) -> Void)?
    private let titleLabel: UILabel = { ScreenKit.label("Elige a tu compañero", size: 27, color: ScreenKit.accent, weight: .bold) }()
    private let moogleButton: UIButton = { ScreenKit.button("☁️  Moogle") }()
    private let chocoboButton: UIButton = { ScreenKit.button("🐤  Chocobo") }()
    private let cactilioButton: UIButton = { ScreenKit.button("🌵  Cactilio") }()

    override func viewDidLoad() {
        super.viewDidLoad()
        ScreenKit.configure(self, title: "Elige mascota")
        moogleButton.addTarget(self, action: #selector(selectMoogle), for: .touchUpInside)
        chocoboButton.addTarget(self, action: #selector(selectChocobo), for: .touchUpInside)
        cactilioButton.addTarget(self, action: #selector(selectCactilio), for: .touchUpInside)
        ScreenKit.install(ScreenKit.stack([titleLabel, moogleButton, chocoboButton, cactilioButton], spacing: 16), in: self)
    }

    @objc private func selectMoogle() { onCharacterSelected?(.moogle) }
    @objc private func selectChocobo() { onCharacterSelected?(.chocobo) }
    @objc private func selectCactilio() { onCharacterSelected?(.cactilio) }
}
