import Foundation
import UserNotifications

enum LocalNotificationManager {
    private static let careIdentifier = "finalgochi.careReminder"
    private static let expeditionIdentifier = "finalgochi.expeditionReturn"
    private static let legacyReminderIdentifier = "finalgochi.petReminder"

    static func setRemindersEnabled(_ enabled: Bool) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [legacyReminderIdentifier])

        guard enabled else {
            center.removePendingNotificationRequests(withIdentifiers: [careIdentifier, expeditionIdentifier])
            return
        }

        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
        }
    }

    static func scheduleCareReminder(after interval: TimeInterval = 3 * 60 * 60, petName: String) {
        guard AppSettings.notificationsEnabled else { return }
        let content = UNMutableNotificationContent()
        content.title = "\(petName) te espera"
        content.body = "Lleva un rato sin verte. Entra para darle de comer y jugar un rato."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(60, interval), repeats: false)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: careIdentifier, content: content, trigger: trigger))
    }

    static func scheduleExpeditionReturn(after interval: TimeInterval, petName: String, routeName: String) {
        guard AppSettings.notificationsEnabled else { return }
        let content = UNMutableNotificationContent()
        content.title = "Expedición completada"
        content.body = "\(petName) ha vuelto de \(routeName). Ya puedes reclamar el botín."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, interval), repeats: false)
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [careIdentifier])
        center.add(UNNotificationRequest(identifier: expeditionIdentifier, content: content, trigger: trigger))
    }

    static func clearCareReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [careIdentifier, legacyReminderIdentifier])
    }

    static func clearExpeditionReturn() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [expeditionIdentifier])
    }

    static func clearAll() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [careIdentifier, expeditionIdentifier, legacyReminderIdentifier]
        )
    }
}
