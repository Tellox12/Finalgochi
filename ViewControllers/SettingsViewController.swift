import UIKit

final class SettingsViewController: UIViewController {
    var onClose: (() -> Void)?
    var onExportSave: (() -> Void)?
    var onImportSave: (() -> Void)?
    private let titleLabel: UILabel = { ScreenKit.label("Ajustes", size: 28, color: ScreenKit.accent, weight: .bold) }()
    private let soundSwitch: UISwitch = { let control = UISwitch(); control.translatesAutoresizingMaskIntoConstraints = false; control.onTintColor = ScreenKit.mint; control.isOn = UserDefaults.standard.object(forKey: "finalgochi.soundEnabled") as? Bool ?? true; return control }()
    private let hapticsSwitch: UISwitch = { let control = UISwitch(); control.translatesAutoresizingMaskIntoConstraints = false; control.onTintColor = ScreenKit.mint; control.isOn = UserDefaults.standard.object(forKey: "finalgochi.hapticsEnabled") as? Bool ?? true; return control }()
    private let notificationsSwitch: UISwitch = { let control = UISwitch(); control.translatesAutoresizingMaskIntoConstraints = false; control.onTintColor = ScreenKit.mint; control.isOn = UserDefaults.standard.bool(forKey: "finalgochi.notificationsEnabled"); return control }()
    private let soundLabel: UILabel = { let label = ScreenKit.label("Sonidos de interfaz", size: 18); label.textAlignment = .left; return label }()
    private let hapticsLabel: UILabel = { let label = ScreenKit.label("Hápticos", size: 18); label.textAlignment = .left; return label }()
    private let notificationsLabel: UILabel = { let label = ScreenKit.label("Notificaciones", size: 18); label.textAlignment = .left; return label }()
    private let soundHint: UILabel = { let label = ScreenKit.label("Respuesta sonora al pulsar", size: 11, color: ScreenKit.mutedText); label.textAlignment = .left; return label }()
    private let hapticsHint: UILabel = { let label = ScreenKit.label("Vibración en dispositivos compatibles", size: 11, color: ScreenKit.mutedText); label.textAlignment = .left; return label }()
    private let notificationsHint: UILabel = { let label = ScreenKit.label("Avisos de cuidado y expediciones completadas", size: 11, color: ScreenKit.mutedText); label.textAlignment = .left; return label }()
    private let closeButton: UIButton = { ScreenKit.button("Volver al juego") }()
    private let exportButton: UIButton = { ScreenKit.button("📤  Exportar respaldo") }()
    private let importButton: UIButton = { ScreenKit.button("📥  Importar respaldo") }()
    private lazy var soundTextStack: UIStackView = { ScreenKit.stack([soundLabel, soundHint], spacing: 4) }()
    private lazy var hapticsTextStack: UIStackView = { ScreenKit.stack([hapticsLabel, hapticsHint], spacing: 4) }()
    private lazy var notificationsTextStack: UIStackView = { ScreenKit.stack([notificationsLabel, notificationsHint], spacing: 4) }()
    private lazy var soundRow: UIStackView = { makeRow(text: soundTextStack, control: soundSwitch) }()
    private lazy var hapticsRow: UIStackView = { makeRow(text: hapticsTextStack, control: hapticsSwitch) }()
    private lazy var notificationsRow: UIStackView = { makeRow(text: notificationsTextStack, control: notificationsSwitch) }()
    private lazy var contentStack: UIStackView = {
        ScreenKit.stack([titleLabel, soundRow, hapticsRow, notificationsRow, exportButton, importButton, closeButton], spacing: 18)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        ScreenKit.configure(self, title: "Ajustes")
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        exportButton.addTarget(self, action: #selector(exportSave), for: .touchUpInside)
        importButton.addTarget(self, action: #selector(importSave), for: .touchUpInside)
        soundSwitch.addTarget(self, action: #selector(soundChanged), for: .valueChanged)
        hapticsSwitch.addTarget(self, action: #selector(hapticsChanged), for: .valueChanged)
        notificationsSwitch.addTarget(self, action: #selector(notificationsChanged), for: .valueChanged)
        ScreenKit.installScrollable(contentStack, in: self)
    }

    @objc private func close() { onClose?() }
    @objc private func exportSave() { onExportSave?() }
    @objc private func importSave() { onImportSave?() }
    @objc private func soundChanged() { UserDefaults.standard.set(soundSwitch.isOn, forKey: "finalgochi.soundEnabled") }
    @objc private func hapticsChanged() { UserDefaults.standard.set(hapticsSwitch.isOn, forKey: "finalgochi.hapticsEnabled") }
    @objc private func notificationsChanged() {
        UserDefaults.standard.set(notificationsSwitch.isOn, forKey: "finalgochi.notificationsEnabled")
        LocalNotificationManager.setRemindersEnabled(notificationsSwitch.isOn)
    }

    private func makeRow(text: UIStackView, control: UISwitch) -> UIStackView {
        let row = ScreenKit.horizontalStack([text, control])
        row.distribution = .fill
        row.alignment = .center
        row.spacing = 16
        return row
    }
}
