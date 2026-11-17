import UIKit

final class SettingsViewController: UIViewController {
    var onClose: (() -> Void)?
    private let titleLabel: UILabel = { ScreenKit.label("Ajustes", size: 28, color: ScreenKit.accent, weight: .bold) }()
    private let soundSwitch: UISwitch = { let control = UISwitch(); control.translatesAutoresizingMaskIntoConstraints = false; control.isOn = UserDefaults.standard.object(forKey: "finalgochi.soundEnabled") as? Bool ?? true; return control }()
    private let hapticsSwitch: UISwitch = { let control = UISwitch(); control.translatesAutoresizingMaskIntoConstraints = false; control.isOn = UserDefaults.standard.object(forKey: "finalgochi.hapticsEnabled") as? Bool ?? true; return control }()
    private let notificationsSwitch: UISwitch = { let control = UISwitch(); control.translatesAutoresizingMaskIntoConstraints = false; control.isOn = UserDefaults.standard.bool(forKey: "finalgochi.notificationsEnabled"); return control }()
    private let soundLabel: UILabel = { let label = ScreenKit.label("Música", size: 18); label.textAlignment = .left; return label }()
    private let hapticsLabel: UILabel = { let label = ScreenKit.label("Hápticos", size: 18); label.textAlignment = .left; return label }()
    private let notificationsLabel: UILabel = { let label = ScreenKit.label("Notificaciones", size: 18); label.textAlignment = .left; return label }()
    private let closeButton: UIButton = { ScreenKit.button("Guardar y volver") }()
    private lazy var soundRow: UIStackView = { ScreenKit.horizontalStack([soundLabel, soundSwitch]) }()
    private lazy var hapticsRow: UIStackView = { ScreenKit.horizontalStack([hapticsLabel, hapticsSwitch]) }()
    private lazy var notificationsRow: UIStackView = { ScreenKit.horizontalStack([notificationsLabel, notificationsSwitch]) }()
    private lazy var contentStack: UIStackView = {
        ScreenKit.stack([titleLabel, soundRow, hapticsRow, notificationsRow, closeButton], spacing: 22)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        ScreenKit.configure(self, title: "Ajustes")
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        soundSwitch.addTarget(self, action: #selector(soundChanged), for: .valueChanged)
        hapticsSwitch.addTarget(self, action: #selector(hapticsChanged), for: .valueChanged)
        notificationsSwitch.addTarget(self, action: #selector(notificationsChanged), for: .valueChanged)
        ScreenKit.install(contentStack, in: self)
    }

    @objc private func close() { onClose?() }
    @objc private func soundChanged() { UserDefaults.standard.set(soundSwitch.isOn, forKey: "finalgochi.soundEnabled") }
    @objc private func hapticsChanged() { UserDefaults.standard.set(hapticsSwitch.isOn, forKey: "finalgochi.hapticsEnabled") }
    @objc private func notificationsChanged() {
        UserDefaults.standard.set(notificationsSwitch.isOn, forKey: "finalgochi.notificationsEnabled")
        LocalNotificationManager.setRemindersEnabled(notificationsSwitch.isOn)
    }
}
