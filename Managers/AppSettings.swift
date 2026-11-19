import Foundation

enum AppSettings {
    private enum Key {
        static let sound = "finalgochi.soundEnabled"
        static let haptics = "finalgochi.hapticsEnabled"
        static let notifications = "finalgochi.notificationsEnabled"
    }

    private static var defaults: UserDefaults { .standard }

    static var soundEnabled: Bool {
        get { defaults.object(forKey: Key.sound) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.sound) }
    }

    static var hapticsEnabled: Bool {
        get { defaults.object(forKey: Key.haptics) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.haptics) }
    }

    static var notificationsEnabled: Bool {
        get { defaults.object(forKey: Key.notifications) as? Bool ?? false }
        set { defaults.set(newValue, forKey: Key.notifications) }
    }
}
