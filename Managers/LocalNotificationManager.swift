import Foundation
import UserNotifications

enum LocalNotificationManager {
    private static let identifier = "finalgochi.petReminder"
    private static let expeditionIdentifier = "finalgochi.expeditionReturn"

    static func setRemindersEnabled(_ enabled: Bool) {
        let center = UNUserNotificationCenter.current()
        guard enabled else {
            center.removePendingNotificationRequests(withIdentifiers: [identifier, expeditionIdentifier])
            return
        }

        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "Tu compañero te extraña"
            content.body = "Entra a Finalgochi para revisar cómo está tu mascota."
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 8 * 60 * 60, repeats: true)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            center.add(request)
        }
    }

    static func scheduleExpeditionReturn(after interval: TimeInterval, petName: String, routeName: String) {
        guard UserDefaults.standard.bool(forKey: "finalgochi.notificationsEnabled") else { return }
        let content = UNMutableNotificationContent()
        content.title = "¡\(petName) volvió de su expedición!"
        content.body = "Tu compañero terminó \(routeName). Entra para reclamar su recompensa."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, interval), repeats: false)
        let request = UNNotificationRequest(identifier: expeditionIdentifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    static func clearExpeditionReturn() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [expeditionIdentifier])
    }
}
