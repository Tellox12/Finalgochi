import UIKit

/// Central design system for Finalgochi.
///
/// The interface is iconographic: every glyph in the game comes from SF Symbols, never from emoji.
/// Colors follow a soft, natural night-garden palette so the screens feel calm and cohesive.
enum ScreenKit {
    // MARK: Palette

    static let background = UIColor(red: 0.055, green: 0.078, blue: 0.094, alpha: 1)
    static let backgroundDeep = UIColor(red: 0.035, green: 0.051, blue: 0.063, alpha: 1)
    static let panel = UIColor(red: 0.098, green: 0.125, blue: 0.149, alpha: 1)
    static let panelElevated = UIColor(red: 0.129, green: 0.161, blue: 0.188, alpha: 1)
    static let accent = UIColor(red: 0.549, green: 0.792, blue: 0.706, alpha: 1)
    static let accentSoft = UIColor(red: 0.361, green: 0.545, blue: 0.494, alpha: 1)
    static let gold = UIColor(red: 0.906, green: 0.769, blue: 0.510, alpha: 1)
    static let mint = UIColor(red: 0.529, green: 0.827, blue: 0.647, alpha: 1)
    static let rose = UIColor(red: 0.898, green: 0.616, blue: 0.643, alpha: 1)
    static let sky = UIColor(red: 0.573, green: 0.722, blue: 0.878, alpha: 1)
    static let mutedText = UIColor(red: 0.596, green: 0.651, blue: 0.694, alpha: 1)
    static let faintText = UIColor(red: 0.443, green: 0.494, blue: 0.537, alpha: 1)
    static let positive = UIColor(red: 0.525, green: 0.788, blue: 0.639, alpha: 1)
    static let danger = UIColor(red: 0.878, green: 0.541, blue: 0.541, alpha: 1)
    static let hunger = UIColor(red: 0.910, green: 0.678, blue: 0.451, alpha: 1)

    static let cornerRadius: CGFloat = 20
    static let maximumContentWidth: CGFloat = 560

    // MARK: Typography

    static func roundedFont(size: CGFloat, weight: UIFont.Weight = .regular, textStyle: UIFont.TextStyle = .body) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        guard let descriptor = base.fontDescriptor.withDesign(.rounded) else { return base }
        return UIFontMetrics(forTextStyle: textStyle).scaledFont(for: UIFont(descriptor: descriptor, size: size))
    }

    // MARK: Symbols

    static func symbolImage(_ name: String, size: CGFloat = 17, weight: UIImage.SymbolWeight = .semibold, color: UIColor = .white) -> UIImage? {
        let configuration = UIImage.SymbolConfiguration(pointSize: size, weight: weight)
        return UIImage(systemName: name, withConfiguration: configuration)?
            .withTintColor(color, renderingMode: .alwaysOriginal)
    }

    static func symbolLabel(_ name: String, size: CGFloat = 20, color: UIColor = .white, weight: UIImage.SymbolWeight = .semibold) -> UIImageView {
        let view = UIImageView(image: symbolImage(name, size: size, weight: weight, color: color))
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentMode = .scaleAspectFit
        view.setContentHuggingPriority(.required, for: .horizontal)
        view.setContentCompressionResistancePriority(.required, for: .horizontal)
        view.isAccessibilityElement = false
        return view
    }

    /// Creates a circular icon badge: a tinted rounded square with a symbol inside.
    static func iconBadge(_ name: String, tint: UIColor = accent, diameter: CGFloat = 46) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = tint.withAlphaComponent(0.14)
        container.layer.cornerRadius = diameter * 0.32
        container.layer.cornerCurve = .continuous
        container.layer.borderWidth = 1
        container.layer.borderColor = tint.withAlphaComponent(0.24).cgColor
        let image = symbolLabel(name, size: diameter * 0.44, color: tint)
        container.addSubview(image)
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: diameter),
            container.heightAnchor.constraint(equalToConstant: diameter),
            image.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            image.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        return container
    }

    /// Builds an attributed string with a leading SF Symbol, useful for labels that mix icon and text.
    static func symbolText(
        _ symbolName: String,
        text: String,
        size: CGFloat = 14,
        weight: UIFont.Weight = .semibold,
        color: UIColor = .white,
        symbolColor: UIColor? = nil,
        textStyle: UIFont.TextStyle = .subheadline
    ) -> NSAttributedString {
        let result = NSMutableAttributedString()
        if let image = symbolImage(symbolName, size: size, color: symbolColor ?? color) {
            let attachment = NSTextAttachment()
            attachment.image = image
            attachment.bounds = CGRect(x: 0, y: -2, width: image.size.width, height: image.size.height)
            result.append(NSAttributedString(attachment: attachment))
            result.append(NSAttributedString(string: "  "))
        }
        result.append(NSAttributedString(
            string: text,
            attributes: [
                .font: roundedFont(size: size, weight: weight, textStyle: textStyle),
                .foregroundColor: color
            ]
        ))
        return result
    }

    // MARK: Building blocks

    static func card() -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = panel
        card.layer.cornerRadius = cornerRadius
        card.layer.cornerCurve = .continuous
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.white.withAlphaComponent(0.055).cgColor
        card.layer.masksToBounds = true
        return card
    }

    static func label(
        _ text: String,
        size: CGFloat = 20,
        color: UIColor = .white,
        weight: UIFont.Weight = .regular,
        textStyle: UIFont.TextStyle = .body
    ) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.textColor = color
        label.font = roundedFont(size: size, weight: weight, textStyle: textStyle)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }

    static func sectionTitle(_ text: String, color: UIColor = mutedText) -> UILabel {
        let label = label(text.uppercased(), size: 11, color: color, weight: .bold, textStyle: .caption1)
        label.textAlignment = .left
        label.accessibilityTraits = .header
        return label
    }

    static func pill(_ text: String, color: UIColor = accent) -> UILabel {
        let label = PillLabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.textColor = color
        label.font = roundedFont(size: 12, weight: .semibold, textStyle: .caption1)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        label.backgroundColor = color.withAlphaComponent(0.12)
        label.layer.cornerRadius = 11
        label.layer.cornerCurve = .continuous
        label.layer.masksToBounds = true
        label.layer.borderWidth = 1
        label.layer.borderColor = color.withAlphaComponent(0.18).cgColor
        return label
    }

    enum ButtonStyle {
        case primary
        case secondary
        case ghost
        case destructive
    }

    static func button(_ title: String, symbol: String? = nil, style: ButtonStyle = .secondary) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        var configuration = style == .primary || style == .destructive
            ? UIButton.Configuration.filled()
            : UIButton.Configuration.gray()
        configuration.title = title
        configuration.cornerStyle = .large
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 13, leading: 18, bottom: 13, trailing: 18)

        switch style {
        case .primary:
            configuration.baseBackgroundColor = accentSoft
            configuration.baseForegroundColor = .white
        case .secondary:
            configuration.baseBackgroundColor = panel
            configuration.baseForegroundColor = .white
        case .ghost:
            configuration.baseBackgroundColor = UIColor.white.withAlphaComponent(0.045)
            configuration.baseForegroundColor = mutedText
        case .destructive:
            configuration.baseBackgroundColor = danger.withAlphaComponent(0.22)
            configuration.baseForegroundColor = danger
        }

        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = roundedFont(size: 17, weight: .semibold, textStyle: .headline)
            return outgoing
        }

        if let symbol, let image = symbolImage(symbol, size: 15, color: configuration.baseForegroundColor ?? .white) {
            configuration.image = image
            configuration.imagePadding = 8
            configuration.imagePlacement = .leading
        }

        button.configuration = configuration
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.titleLabel?.lineBreakMode = .byWordWrapping
        button.titleLabel?.textAlignment = .center
        button.layer.cornerRadius = 15
        button.layer.cornerCurve = .continuous
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.055).cgColor
        button.addTarget(FeedbackManager.shared, action: #selector(FeedbackManager.buttonWasTapped(_:)), for: .touchUpInside)
        return button
    }

    static func setTitle(_ title: String, on button: UIButton) {
        guard var configuration = button.configuration else {
            button.setTitle(title, for: .normal)
            return
        }
        configuration.title = title
        button.configuration = configuration
    }

    static func setBackground(_ color: UIColor, on button: UIButton) {
        guard var configuration = button.configuration else {
            button.backgroundColor = color
            return
        }
        configuration.baseBackgroundColor = color
        button.configuration = configuration
    }

    static func stack(_ views: [UIView], spacing: CGFloat = 14) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: views)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = spacing
        stack.distribution = .fill
        stack.alignment = .fill
        return stack
    }

    static func horizontalStack(_ views: [UIView], spacing: CGFloat = 12) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: views)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = spacing
        stack.distribution = .equalSpacing
        stack.alignment = .center
        return stack
    }

    static func headerRow(title: UILabel, trailing: [UIView]) -> UIStackView {
        let stack = horizontalStack([title] + trailing)
        stack.distribution = .fill
        title.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        for view in trailing {
            view.setContentCompressionResistancePriority(.required, for: .horizontal)
        }
        return stack
    }

    // MARK: Installation

    static func install(_ stack: UIStackView, in controller: UIViewController) {
        controller.view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: controller.view.safeAreaLayoutGuide.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: controller.view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: controller.view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            stack.centerXAnchor.constraint(equalTo: controller.view.safeAreaLayoutGuide.centerXAnchor),
            stack.widthAnchor.constraint(lessThanOrEqualToConstant: maximumContentWidth)
        ])
        let width = stack.widthAnchor.constraint(equalTo: controller.view.safeAreaLayoutGuide.widthAnchor, constant: -48)
        width.priority = .defaultHigh
        width.isActive = true

        // On iPad the flexible width can exceed the readable maximum; pin it to the cap instead of
        // letting Auto Layout fall back to the stack's intrinsic width.
        let maximumWidth = stack.widthAnchor.constraint(equalToConstant: maximumContentWidth)
        maximumWidth.priority = UILayoutPriority(749)
        maximumWidth.isActive = true
    }

    static func installScrollable(_ stack: UIStackView, in controller: UIViewController) {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .interactive
        controller.view.addSubview(scrollView)
        scrollView.addSubview(stack)

        let compactWidth = stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40)
        compactWidth.priority = .defaultHigh

        // Keep the readable column centered on iPad while still filling narrower phones.
        let maximumWidth = stack.widthAnchor.constraint(equalToConstant: maximumContentWidth)
        maximumWidth.priority = UILayoutPriority(749)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: controller.view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: controller.view.keyboardLayoutGuide.topAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 18),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -32),
            stack.centerXAnchor.constraint(equalTo: scrollView.frameLayoutGuide.centerXAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            stack.widthAnchor.constraint(lessThanOrEqualToConstant: maximumContentWidth),
            scrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            compactWidth,
            maximumWidth
        ])
    }

    static func configure(_ controller: UIViewController, title: String) {
        controller.view.backgroundColor = background
        let backdrop = GardenBackgroundView()
        controller.view.insertSubview(backdrop, at: 0)
        NSLayoutConstraint.activate([
            backdrop.topAnchor.constraint(equalTo: controller.view.topAnchor),
            backdrop.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor),
            backdrop.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor),
            backdrop.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor)
        ])
        controller.title = title
    }

    static func divider() -> UIView {
        let line = UIView()
        line.translatesAutoresizingMaskIntoConstraints = false
        line.backgroundColor = UIColor.white.withAlphaComponent(0.065)
        line.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return line
    }
}

// MARK: - Padded pill label

/// A single-line label with symmetric padding. `UILabel` has no content insets, so the rounded
/// "pill" background would otherwise hug the text too tightly.
final class PillLabel: UILabel {
    private let textInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: textInsets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + textInsets.left + textInsets.right,
                      height: size.height + textInsets.top + textInsets.bottom)
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let inner = CGSize(width: max(0, size.width - textInsets.left - textInsets.right),
                           height: max(0, size.height - textInsets.top - textInsets.bottom))
        let fitted = super.sizeThatFits(inner)
        return CGSize(width: fitted.width + textInsets.left + textInsets.right,
                      height: fitted.height + textInsets.top + textInsets.bottom)
    }
}

// MARK: - List card control

/// A tappable card with an icon badge, title and supporting text.
/// Used across shop, inventory, expeditions and actions for a consistent, emoji-free look.
final class MenuCardControl: UIControl {
    private let badge: UIView
    private let iconView: UIImageView
    private let titleLabel: UILabel
    private let subtitleLabel: UILabel
    private let footnoteLabel: UILabel
    private let chevronView: UIImageView

    init() {
        let badgeView = ScreenKit.iconBadge("circle", diameter: 46)
        badge = badgeView
        iconView = badgeView.subviews.compactMap { $0 as? UIImageView }.first ?? UIImageView()
        let title = ScreenKit.label("", size: 16, color: .white, weight: .semibold, textStyle: .headline)
        title.textAlignment = .left
        titleLabel = title
        let subtitle = ScreenKit.label("", size: 12.5, color: ScreenKit.mutedText, textStyle: .subheadline)
        subtitle.textAlignment = .left
        subtitleLabel = subtitle
        let footnote = ScreenKit.label("", size: 11.5, color: ScreenKit.gold, weight: .semibold, textStyle: .caption1)
        footnote.textAlignment = .left
        footnoteLabel = footnote
        chevronView = ScreenKit.symbolLabel("chevron.right", size: 13, color: ScreenKit.faintText, weight: .bold)

        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = ScreenKit.panel
        layer.cornerRadius = 18
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.withAlphaComponent(0.055).cgColor

        let textStack = ScreenKit.stack([titleLabel, subtitleLabel, footnoteLabel], spacing: 3)
        textStack.setCustomSpacing(6, after: subtitleLabel)
        let row = ScreenKit.horizontalStack([badge, textStack, chevronView], spacing: 14)
        row.distribution = .fill
        row.alignment = .center
        // The stack would otherwise become the hit-test target and swallow taps meant for the control.
        row.isUserInteractionEnabled = false
        textStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: topAnchor, constant: 13),
            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            row.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -13),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 68)
        ])
        isAccessibilityElement = true
        accessibilityTraits = .button
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no está disponible") }

    func update(
        symbolName: String,
        title: String,
        subtitle: String,
        footnote: String? = nil,
        tint: UIColor = ScreenKit.accent,
        selected: Bool = false
    ) {
        self.iconView.image = ScreenKit.symbolImage(symbolName, size: 20, color: tint)
        badge.backgroundColor = tint.withAlphaComponent(0.14)
        badge.layer.borderColor = tint.withAlphaComponent(0.24).cgColor
        titleLabel.text = title
        subtitleLabel.text = subtitle
        subtitleLabel.isHidden = subtitle.isEmpty
        if let footnote, !footnote.isEmpty {
            footnoteLabel.text = footnote
            footnoteLabel.textColor = selected ? ScreenKit.mint : tint
            footnoteLabel.isHidden = false
        } else {
            footnoteLabel.text = nil
            footnoteLabel.isHidden = true
        }
        backgroundColor = selected ? tint.withAlphaComponent(0.10) : ScreenKit.panel
        layer.borderColor = (selected ? tint.withAlphaComponent(0.45) : UIColor.white.withAlphaComponent(0.055)).cgColor
        chevronView.image = ScreenKit.symbolImage(selected ? "checkmark.circle.fill" : "chevron.right", size: 13, weight: .bold, color: selected ? tint : ScreenKit.faintText)
        accessibilityLabel = [title, subtitle, footnote].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ". ")
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.12) {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.985, y: 0.985) : .identity
                self.alpha = self.isHighlighted ? 0.86 : (self.isEnabled ? 1 : 0.45)
            }
        }
    }

    override var isEnabled: Bool {
        didSet { alpha = isEnabled ? 1 : 0.45 }
    }
}

// MARK: - Background

private final class GardenBackgroundView: UIView {
    private let gradientLayer = CAGradientLayer()
    private let glowLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        isUserInteractionEnabled = false
        accessibilityElementsHidden = true

        gradientLayer.colors = [
            UIColor(red: 0.086, green: 0.125, blue: 0.141, alpha: 1).cgColor,
            ScreenKit.background.cgColor,
            ScreenKit.backgroundDeep.cgColor
        ]
        gradientLayer.locations = [0, 0.55, 1]
        gradientLayer.startPoint = CGPoint(x: 0.15, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.85, y: 1)
        layer.addSublayer(gradientLayer)

        glowLayer.type = .radial
        glowLayer.colors = [
            ScreenKit.accent.withAlphaComponent(0.14).cgColor,
            ScreenKit.accent.withAlphaComponent(0.04).cgColor,
            UIColor.clear.cgColor
        ]
        glowLayer.locations = [0, 0.45, 1]
        glowLayer.startPoint = CGPoint(x: 0.78, y: 0.05)
        glowLayer.endPoint = CGPoint(x: 1.15, y: 0.65)
        layer.addSublayer(glowLayer)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no está disponible") }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientLayer.frame = bounds
        glowLayer.frame = bounds
        CATransaction.commit()
    }
}
