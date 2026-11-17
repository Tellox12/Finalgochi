import UIKit

final class SplashViewController: UIViewController {
    var onFinishSplash: (() -> Void)?
    private let crystalLabel: UILabel = { ScreenKit.label("🔮", size: 88) }()
    private let titleLabel: UILabel = { ScreenKit.label("FINALGOCHI", size: 32, color: ScreenKit.accent, weight: .heavy) }()
    private let subtitleLabel: UILabel = { ScreenKit.label("Tu aventura comienza aquí", size: 16, color: .lightGray) }()

    override func viewDidLoad() {
        super.viewDidLoad()
        ScreenKit.configure(self, title: "Finalgochi")
        let stack = ScreenKit.stack([crystalLabel, titleLabel, subtitleLabel], spacing: 18)
        ScreenKit.install(stack, in: self)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { [weak self] in self?.onFinishSplash?() }
    }
}
