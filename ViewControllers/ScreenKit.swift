import UIKit

enum ScreenKit {
    static let background = UIColor(red: 0.055, green: 0.067, blue: 0.12, alpha: 1)
    static let panel = UIColor(red: 0.12, green: 0.14, blue: 0.23, alpha: 1)
    static let accent = UIColor(red: 0.55, green: 0.82, blue: 1, alpha: 1)
    static let gold = UIColor(red: 1, green: 0.79, blue: 0.35, alpha: 1)
    static let mint = UIColor(red: 0.36, green: 0.86, blue: 0.69, alpha: 1)
    static let mutedText = UIColor(red: 0.69, green: 0.73, blue: 0.84, alpha: 1)

    static func card() -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = panel
        card.layer.cornerRadius = 22
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor
        card.layer.masksToBounds = true
        return card
    }

    static func label(_ text: String, size: CGFloat = 20, color: UIColor = .white, weight: UIFont.Weight = .regular) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.textColor = color
        label.font = .systemFont(ofSize: size, weight: weight)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }

    static func button(_ title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = panel
        button.layer.cornerRadius = 14
        button.contentEdgeInsets = UIEdgeInsets(top: 14, left: 18, bottom: 14, right: 18)
        button.addTarget(FeedbackManager.shared, action: #selector(FeedbackManager.buttonWasTapped(_:)), for: .touchUpInside)
        return button
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

    static func horizontalStack(_ views: [UIView]) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: views)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 12
        stack.distribution = .equalSpacing
        stack.alignment = .center
        return stack
    }

    static func install(_ stack: UIStackView, in controller: UIViewController) {
        controller.view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: controller.view.safeAreaLayoutGuide.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: controller.view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: controller.view.safeAreaLayoutGuide.trailingAnchor, constant: -24)
        ])
    }

    static func installScrollable(_ stack: UIStackView, in controller: UIViewController) {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        controller.view.addSubview(scrollView)
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: controller.view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: controller.view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: controller.view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: controller.view.safeAreaLayoutGuide.bottomAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -24),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -48),
            scrollView.contentLayoutGuide.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.frameLayoutGuide.heightAnchor)
        ])
    }

    static func configure(_ controller: UIViewController, title: String) {
        controller.view.backgroundColor = background
        controller.title = title
    }
}
