import UIKit

final class SettingsViewController: UIViewController {
    var onClose: (() -> Void)?
    var onExportSave: (() -> Void)?
    var onImportSave: (() -> Void)?
    var petName: String = "Tu compañero"

    private let titleLabel = ScreenKit.label("Ajustes", size: 27, color: .white, weight: .bold, textStyle: .largeTitle)
    private let subtitleLabel: UILabel = {
        let label = ScreenKit.label("Sonido, vibración, avisos y respaldos.", size: 14, color: ScreenKit.mutedText)
        label.textAlignment = .left
        return label
    }()

    private let soundSwitch: UISwitch
    private let hapticsSwitch: UISwitch
    private let notificationsSwitch: UISwitch

    private let soundRow: UIView
    private let hapticsRow: UIView
    private let notificationsRow: UIView
    private let exportButton = MenuCardControl()
    private let importButton = MenuCardControl()
    private let closeButton = ScreenKit.button("Volver al juego", symbol: "chevron.left", style: .ghost)
    private let versionLabel: UILabel = {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let label = ScreenKit.label("Finalgochi · versión \(version)", size: 11, color: ScreenKit.faintText, textStyle: .caption2)
        return label
    }()

    private lazy var contentStack: UIStackView = {
        ScreenKit.stack([titleLabel, subtitleLabel, soundRow, hapticsRow, notificationsRow, exportButton, importButton, closeButton, versionLabel], spacing: 13)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        ScreenKit.configure(self, title: "Ajustes")
        titleLabel.textAlignment = .left
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        exportButton.addTarget(self, action: #selector(exportSave), for: .touchUpInside)
        importButton.addTarget(self, action: #selector(importSave), for: .touchUpInside)
        soundSwitch.addTarget(self, action: #selector(soundChanged), for: .valueChanged)
        hapticsSwitch.addTarget(self, action: #selector(hapticsChanged), for: .valueChanged)
        notificationsSwitch.addTarget(self, action: #selector(notificationsChanged), for: .valueChanged)

        exportButton.update(
            symbolName: "square.and.arrow.up",
            title: "Exportar respaldo",
            subtitle: "Guarda tu partida en un archivo JSON.",
            tint: ScreenKit.sky
        )
        importButton.update(
            symbolName: "square.and.arrow.down",
            title: "Importar respaldo",
            subtitle: "Restaura una partida guardada previamente.",
            tint: ScreenKit.gold
        )
        ScreenKit.installScrollable(contentStack, in: self)
    }

    init() {
        let sound = SettingsViewController.makeSwitch(AppSettings.soundEnabled)
        let haptics = SettingsViewController.makeSwitch(AppSettings.hapticsEnabled)
        let notifications = SettingsViewController.makeSwitch(AppSettings.notificationsEnabled)
        soundSwitch = sound
        hapticsSwitch = haptics
        notificationsSwitch = notifications

        soundRow = SettingsViewController.makeRow(
            symbol: "speaker.wave.2.fill",
            title: "Sonidos de interfaz",
            detail: "Respuesta sonora al pulsar",
            control: sound
        )
        hapticsRow = SettingsViewController.makeRow(
            symbol: "hand.tap.fill",
            title: "Vibración",
            detail: "Respuesta háptica en dispositivos compatibles",
            control: haptics
        )
        notificationsRow = SettingsViewController.makeRow(
            symbol: "bell.badge.fill",
            title: "Notificaciones",
            detail: "Avisos de cuidado y expediciones completadas",
            control: notifications
        )
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no está disponible") }

    private static func makeSwitch(_ isOn: Bool) -> UISwitch {
        let control = UISwitch()
        control.translatesAutoresizingMaskIntoConstraints = false
        control.onTintColor = ScreenKit.accentSoft
        control.isOn = isOn
        return control
    }

    private static func makeRow(symbol: String, title: String, detail: String, control: UISwitch) -> UIView {
        let card = ScreenKit.card()
        let icon = ScreenKit.iconBadge(symbol, diameter: 42)
        let titleLabel = ScreenKit.label(title, size: 15, color: .white, weight: .semibold, textStyle: .headline)
        titleLabel.textAlignment = .left
        let detailLabel = ScreenKit.label(detail, size: 11.5, color: ScreenKit.mutedText, textStyle: .caption1)
        detailLabel.textAlignment = .left
        let textStack = ScreenKit.stack([titleLabel, detailLabel], spacing: 3)
        let row = ScreenKit.horizontalStack([icon, textStack, control], spacing: 12)
        row.distribution = .fill
        card.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12)
        ])
        return card
    }

    @objc private func close() { onClose?() }
    @objc private func exportSave() { onExportSave?() }
    @objc private func importSave() { onImportSave?() }

    @objc private func soundChanged() {
        AppSettings.soundEnabled = soundSwitch.isOn
    }

    @objc private func hapticsChanged() {
        AppSettings.hapticsEnabled = hapticsSwitch.isOn
    }

    @objc private func notificationsChanged() {
        AppSettings.notificationsEnabled = notificationsSwitch.isOn
        LocalNotificationManager.setRemindersEnabled(notificationsSwitch.isOn)
        if notificationsSwitch.isOn {
            LocalNotificationManager.scheduleCareReminder(petName: petName)
        }
    }
}
