import UIKit
import CoreHaptics
import AudioToolbox

final class FeedbackManager: NSObject {
    static let shared = FeedbackManager()
    private var engine: CHHapticEngine?

    private override init() {
        super.init()
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        engine = try? CHHapticEngine()
        try? engine?.start()
    }

    @objc func buttonWasTapped(_ sender: UIButton) {
        if UserDefaults.standard.object(forKey: "finalgochi.soundEnabled") as? Bool ?? true {
            AudioServicesPlaySystemSound(1104)
        }
        let isEnabled = UserDefaults.standard.object(forKey: "finalgochi.hapticsEnabled") as? Bool ?? true
        guard isEnabled, let engine else { return }
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.55)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.35)
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
        guard let pattern = try? CHHapticPattern(events: [event], parameters: []) else { return }
        guard let player = try? engine.makePlayer(with: pattern) else { return }
        try? player.start(atTime: 0)
    }
}
