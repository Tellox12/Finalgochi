import Foundation

enum StoreItem: String, CaseIterable, Codable, Hashable {
    case ribbon, feather, cactusHat

    var name: String {
        switch self {
        case .ribbon: return "Lazo de kupó"
        case .feather: return "Pluma dorada"
        case .cactusHat: return "Sombrero espinoso"
        }
    }

    var price: Int {
        switch self {
        case .ribbon: return 30
        case .feather: return 45
        case .cactusHat: return 60
        }
    }

    var emoji: String {
        switch self {
        case .ribbon: return "🎀"
        case .feather: return "🪶"
        case .cactusHat: return "🤠"
        }
    }
}

enum ConsumableItem: String, CaseIterable, Codable, Hashable {
    case ration
    case gysahlGreens
    case potion
    case ether

    var name: String {
        switch self {
        case .ration: return "Ración de viaje"
        case .gysahlGreens: return "Verduras Gysahl"
        case .potion: return "Poción energética"
        case .ether: return "Éter de ánimo"
        }
    }

    var price: Int {
        switch self {
        case .ration: return 10
        case .gysahlGreens: return 20
        case .potion: return 25
        case .ether: return 30
        }
    }

    var emoji: String {
        switch self {
        case .ration: return "🍖"
        case .gysahlGreens: return "🥬"
        case .potion: return "🧪"
        case .ether: return "✨"
        }
    }
}
