import Foundation

enum WorldPhase: String, CaseIterable, Codable {
    case dawn
    case day
    case dusk
    case night

    static func current(at date: Date = Date(), calendar: Calendar = .current) -> WorldPhase {
        let hour = calendar.component(.hour, from: date)
        switch hour {
        case 5..<8: return .dawn
        case 8..<17: return .day
        case 17..<20: return .dusk
        default: return .night
        }
    }

    var title: String {
        switch self {
        case .dawn: return "AMANECER"
        case .day: return "DÍA"
        case .dusk: return "ATARDECER"
        case .night: return "NOCHE"
        }
    }
}

enum PetMood: String, Codable {
    case joyful
    case calm
    case hungry
    case tired
    case sad
    case sleeping

    var title: String {
        switch self {
        case .joyful: return "FELIZ"
        case .calm: return "TRANQUILO"
        case .hungry: return "TIENE HAMBRE"
        case .tired: return "CANSADO"
        case .sad: return "NECESITA JUGAR"
        case .sleeping: return "DURMIENDO"
        }
    }

    var symbol: String {
        switch self {
        case .joyful: return "✦"
        case .calm: return "•"
        case .hungry: return "!"
        case .tired: return "zZ"
        case .sad: return "…"
        case .sleeping: return "☾"
        }
    }
}

enum PetActionKind {
    case fed
    case played
    case wentToSleep
    case wokeUp
    case usedPotion
    case cheeredUp
}
