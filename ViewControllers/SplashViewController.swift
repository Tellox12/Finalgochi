import UIKit

final class SplashViewController: UIViewController {
    var onFinishSplash: (() -> Void)?

    private let haloView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = ScreenKit.accent.withAlphaComponent(0.10)
        view.layer.cornerRadius = 62
        view.layer.cornerCurve = .continuous
        view.layer.borderWidth = 1
        view.layer.borderColor = ScreenKit.accent.withAlphaComponent(0.32).cgColor
        view.layer.shadowColor = ScreenKit.accent.cgColor
        view.layer.shadowRadius = 30
        view.layer.shadowOpacity = 0.45
        view.layer.shadowOffset = .zero
        return view
    }()
    private let crystalView = ScreenKit.symbolLabel("sparkles", size: 58, color: ScreenKit.accent, weight: .regular)
    private let titleLabel = ScreenKit.label("FINALGOCHI", size: 32, color: .white, weight: .heavy, textStyle: .largeTitle)
    private let subtitleLabel: UILabel = {
        let label = ScreenKit.label("Un pequeño refugio para una gran aventura.", size: 15, color: ScreenKit.mutedText)
        return label
    }()
    private let footerLabel: UILabel = {
        let label = ScreenKit.label("Cuidado · Materia · Expediciones", size: 10.5, color: ScreenKit.faintText, weight: .semibold, textStyle: .caption2)
        return label
    }()
    private lazy var contentStack: UIStackView = {
        let stack = ScreenKit.stack([haloView, titleLabel, subtitleLabel, footerLabel], spacing: 14)
        stack.setCustomSpacing(26, after: haloView)
        return stack
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        ScreenKit.configure(self, title: "Finalgochi")
        haloView.addSubview(crystalView)
        NSLayoutConstraint.activate([
            haloView.widthAnchor.constraint(equalToConstant: 124),
            haloView.heightAnchor.constraint(equalToConstant: 124),
            crystalView.centerXAnchor.constraint(equalTo: haloView.centerXAnchor),
            crystalView.centerYAnchor.constraint(equalTo: haloView.centerYAnchor)
        ])
        ScreenKit.install(contentStack, in: self)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { [weak self] in self?.onFinishSplash?() }

        guard !UIAccessibility.isReduceMotionEnabled else { return }
        UIView.animate(withDuration: 1.1, delay: 0, options: [.autoreverse, .repeat, .allowUserInteraction], animations: {
            self.crystalView.transform = CGAffineTransform(scaleX: 1.06, y: 1.06)
            self.haloView.layer.shadowOpacity = 0.25
        }, completion: nil)
    }
}
