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
        ScreenKit.label("Tres criaturas. Tres formas de vivir la aventura.", size: 15, color: ScreenKit.mutedText)
    }()
    private let moogleButton: CharacterSelectionCard = {
        CharacterSelectionCard(kind: .moogle, detail: "Cariñoso y curioso", tint: UIColor(red: 0.25, green: 0.40, blue: 0.59, alpha: 1))
    }()
    private let chocoboButton: CharacterSelectionCard = {
        CharacterSelectionCard(kind: .chocobo, detail: "Rápido y valiente", tint: UIColor(red: 0.53, green: 0.38, blue: 0.16, alpha: 1))
    }()
    private let cactilioButton: CharacterSelectionCard = {
        CharacterSelectionCard(kind: .cactilio, detail: "Tranquilo y resistente", tint: UIColor(red: 0.19, green: 0.43, blue: 0.34, alpha: 1))
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

    @objc private func selectMoogle() { onCharacterSelected?(.moogle) }
    @objc private func selectChocobo() { onCharacterSelected?(.chocobo) }
    @objc private func selectCactilio() { onCharacterSelected?(.cactilio) }
}

private final class CharacterSelectionCard: UIButton {
    private let spriteView: PixelPetSpriteView = {
        let view = PixelPetSpriteView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private let nameLabel: UILabel = {
        let label = ScreenKit.label("", size: 18, color: .white, weight: .bold)
        label.textAlignment = .left
        return label
    }()
    private let detailLabel: UILabel = {
        let label = ScreenKit.label("", size: 13, color: ScreenKit.mutedText)
        label.textAlignment = .left
        return label
    }()
    private let callToActionLabel: UILabel = {
        let label = ScreenKit.label("ELEGIR COMPAÑERO  ›", size: 10, color: ScreenKit.gold, weight: .bold)
        label.textAlignment = .left
        return label
    }()
    private lazy var textStack: UIStackView = {
        ScreenKit.stack([nameLabel, detailLabel, callToActionLabel], spacing: 7)
    }()
    private lazy var contentStack: UIStackView = {
        let stack = ScreenKit.horizontalStack([spriteView, textStack])
        stack.distribution = .fill
        stack.alignment = .center
        return stack
    }()

    init(kind: PetKind, detail: String, tint: UIColor) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        var configuration = UIButton.Configuration.plain()
        configuration.contentInsets = .zero
        self.configuration = configuration
        backgroundColor = tint.withAlphaComponent(0.25)
        layer.cornerRadius = 20
        layer.borderWidth = 1
        layer.borderColor = tint.withAlphaComponent(0.8).cgColor
        layer.masksToBounds = true

        spriteView.kind = kind
        spriteView.showsMoodBadge = false
        nameLabel.text = kind.displayName.uppercased()
        detailLabel.text = detail
        addSubview(contentStack)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 126),
            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            spriteView.widthAnchor.constraint(equalToConstant: 100),
            spriteView.heightAnchor.constraint(equalToConstant: 100),
            textStack.trailingAnchor.constraint(equalTo: contentStack.trailingAnchor)
        ])
        accessibilityLabel = "\(kind.displayName), \(detail)"
        accessibilityHint = "Toca dos veces para elegir este compañero"
        addTarget(FeedbackManager.shared, action: #selector(FeedbackManager.buttonWasTapped(_:)), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no está disponible") }

    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.72 : 1 }
    }
}
