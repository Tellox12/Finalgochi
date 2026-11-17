import UIKit

final class SplashViewController: UIViewController {
    var onFinishSplash: (() -> Void)?
    private let crystalLabel: UILabel = {
        let label = ScreenKit.label("🔮", size: 88)
        label.layer.shadowColor = ScreenKit.accent.cgColor
        label.layer.shadowRadius = 24
        label.layer.shadowOpacity = 0.85
        label.layer.shadowOffset = .zero
        return label
    }()
    private let titleLabel: UILabel = { ScreenKit.label("FINALGOCHI", size: 32, color: ScreenKit.accent, weight: .heavy) }()
    private let subtitleLabel: UILabel = { ScreenKit.label("Tu aventura comienza aquí", size: 16, color: .lightGray) }()
    private lazy var contentStack: UIStackView = {
        ScreenKit.stack([crystalLabel, titleLabel, subtitleLabel], spacing: 18)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        ScreenKit.configure(self, title: "Finalgochi")
        ScreenKit.install(contentStack, in: self)
        UIView.animate(withDuration: 1.1, delay: 0, options: [.autoreverse, .repeat, .allowUserInteraction], animations: {
            self.crystalLabel.transform = CGAffineTransform(scaleX: 1.08, y: 1.08)
            self.crystalLabel.layer.shadowOpacity = 0.45
        }, completion: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { [weak self] in self?.onFinishSplash?() }
    }
}
