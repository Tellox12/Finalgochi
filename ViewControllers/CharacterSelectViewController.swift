import UIKit

final class CharacterSelectViewController: UIViewController {
    var onCharacterSelected: ((PetKind) -> Void)?
    private var didAnimateEntrance = false

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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !didAnimateEntrance, !UIAccessibility.isReduceMotionEnabled else { return }
        didAnimateEntrance = true
        let cards = [moogleButton, chocoboButton, cactilioButton]
        for (index, card) in cards.enumerated() {
            card.alpha = 0
            card.transform = CGAffineTransform(translationX: 0, y: 18)
            UIView.animate(withDuration: 0.42, delay: Double(index) * 0.10, options: [.curveEaseOut], animations: {
                card.alpha = 1
                card.transform = .identity
            }, completion: nil)
        }
    }

    @objc private func selectMoogle() { onCharacterSelected?(.moogle) }
    @objc private func selectChocobo() { onCharacterSelected?(.chocobo) }
    @objc private func selectCactilio() { onCharacterSelected?(.cactilio) }
}

private final class CharacterSelectionCard: UIButton {
    private let portraitAura: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 64
        view.layer.borderWidth = 1
        view.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        return view
    }()
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
        let stack = ScreenKit.horizontalStack([portraitAura, textStack])
        stack.distribution = .fill
        stack.alignment = .center
        stack.isUserInteractionEnabled = false
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
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = tint.withAlphaComponent(0.8).cgColor
        layer.masksToBounds = true
        portraitAura.layer.borderColor = tint.withAlphaComponent(0.52).cgColor
        portraitAura.backgroundColor = tint.withAlphaComponent(0.26)

        spriteView.kind = kind
        spriteView.showsMoodBadge = false
        nameLabel.text = kind.displayName.uppercased()
        detailLabel.text = detail
        portraitAura.addSubview(spriteView)
        addSubview(contentStack)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: 150),
            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: 11),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -11),
            portraitAura.widthAnchor.constraint(equalToConstant: 128),
            portraitAura.heightAnchor.constraint(equalToConstant: 128),
            spriteView.centerXAnchor.constraint(equalTo: portraitAura.centerXAnchor),
            spriteView.centerYAnchor.constraint(equalTo: portraitAura.centerYAnchor),
            spriteView.widthAnchor.constraint(equalToConstant: 116),
            spriteView.heightAnchor.constraint(equalToConstant: 116),
            textStack.trailingAnchor.constraint(equalTo: contentStack.trailingAnchor)
        ])
        accessibilityLabel = "\(kind.displayName), \(detail)"
        accessibilityHint = "Toca dos veces para elegir este compañero"
        addTarget(FeedbackManager.shared, action: #selector(FeedbackManager.buttonWasTapped(_:)), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no está disponible") }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.12) {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.985, y: 0.985) : .identity
            }
        }
    }
}
