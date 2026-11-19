import UIKit

final class GameOverViewController: UIViewController {
    var onRestart: (() -> Void)?
    var petName: String?

    private let iconHalo: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ScreenKit.rose.withAlphaComponent(0.10)
        view.layer.cornerRadius = 58
        view.layer.cornerCurve = .continuous
        view.layer.borderWidth = 1
        view.layer.borderColor = ScreenKit.rose.withAlphaComponent(0.28).cgColor
        return view
    }()
    private let iconView = ScreenKit.symbolLabel("moon.stars.fill", size: 46, color: ScreenKit.rose, weight: .regular)
    private let titleLabel = ScreenKit.label("El ciclo termina", size: 28, color: .white, weight: .bold, textStyle: .largeTitle)
    private let messageLabel: UILabel = {
        let label = ScreenKit.label(
            "Tu compañero se ha ido a descansar a otro mundo.\nGracias por los días compartidos.",
            size: 15,
            color: ScreenKit.mutedText
        )
        return label
    }()
    private let restartButton = ScreenKit.button("Empezar una nueva aventura", symbol: "sparkles", style: .primary)
    private lazy var contentStack: UIStackView = {
        let stack = ScreenKit.stack([iconHalo, titleLabel, messageLabel, restartButton], spacing: 18)
        stack.setCustomSpacing(28, after: iconHalo)
        return stack
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        ScreenKit.configure(self, title: "Fin de partida")
        iconHalo.addSubview(iconView)
        NSLayoutConstraint.activate([
            iconHalo.widthAnchor.constraint(equalToConstant: 116),
            iconHalo.heightAnchor.constraint(equalToConstant: 116),
            iconView.centerXAnchor.constraint(equalTo: iconHalo.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconHalo.centerYAnchor)
        ])
        if let petName, !petName.isEmpty {
            messageLabel.text = "\(petName) se ha ido a descansar a otro mundo.\nGracias por los días compartidos."
        }
        restartButton.addTarget(self, action: #selector(restart), for: .touchUpInside)
        ScreenKit.installScrollable(contentStack, in: self)
    }

    @objc private func restart() { onRestart?() }
}
