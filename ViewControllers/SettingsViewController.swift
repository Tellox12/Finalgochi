import UIKit

final class SettingsViewController: UIViewController {
    var onClose: (() -> Void)?
    private let titleLabel: UILabel = { ScreenKit.label("Ajustes", size: 28, color: ScreenKit.accent, weight: .bold) }()
    private let soundSwitch: UISwitch = { let control = UISwitch(); control.translatesAutoresizingMaskIntoConstraints = false; control.isOn = UserDefaults.standard.object(forKey: "finalgochi.soundEnabled") as? Bool ?? true; return control }()
    private let hapticsSwitch: UISwitch = { let control = UISwitch(); control.translatesAutoresizingMaskIntoConstraints = false; control.isOn = UserDefaults.standard.object(forKey: "finalgochi.hapticsEnabled") as? Bool ?? true; return control }()
    private let notificationsSwitch: UISwitch = { let control = UISwitch(); control.translatesAutoresizingMaskIntoConstraints = false; control.isOn = UserDefaults.standard.bool(forKey: "finalgochi.notificationsEnabled"); return control }()
    private let closeButton: UIButton = { ScreenKit.button("Guardar y volver") }()

    override func viewDidLoad() {
        super.viewDidLoad()
        ScreenKit.configure(self, title: "Ajustes")
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        soundSwitch.addTarget(self, action: #selector(soundChanged), for: .valueChanged)
        hapticsSwitch.addTarget(self, action: #selector(hapticsChanged), for: .valueChanged)
        notificationsSwitch.addTarget(self, action: #selector(notificationsChanged), for: .valueChanged)
        let stack = ScreenKit.stack([titleLabel, row("Música", control: soundSwitch), row("Hápticos", control: hapticsSwitch), row("Notificaciones", control: notificationsSwitch), closeButton], spacing: 22)
        ScreenKit.install(stack, in: self)
    }

    private func row(_ title: String, control: UISwitch) -> UIStackView {
        let label = ScreenKit.label(title, size: 18)
        label.textAlignment = .left
        let row = UIStackView(arrangedSubviews: [label, control])
        row.translatesAutoresizingMaskIntoConstraints = false
        row.axis = .horizontal
        row.spacing = 12
        row.distribution = .equalSpacing
        row.alignment = .center
        return row
    }

    @objc private func close() { onClose?() }
    @objc private func soundChanged() { UserDefaults.standard.set(soundSwitch.isOn, forKey: "finalgochi.soundEnabled") }
    @objc private func hapticsChanged() { UserDefaults.standard.set(hapticsSwitch.isOn, forKey: "finalgochi.hapticsEnabled") }
    @objc private func notificationsChanged() {
        UserDefaults.standard.set(notificationsSwitch.isOn, forKey: "finalgochi.notificationsEnabled")
        LocalNotificationManager.setRemindersEnabled(notificationsSwitch.isOn)
    }
}
