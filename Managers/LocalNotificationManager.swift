import Foundation
import UserNotifications

enum LocalNotificationManager {
    private static let identifier = "finalgochi.petReminder"

    static func setRemindersEnabled(_ enabled: Bool) {
        let center = UNUserNotificationCenter.current()
        guard enabled else {
            center.removePendingNotificationRequests(withIdentifiers: [identifier])
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
}
