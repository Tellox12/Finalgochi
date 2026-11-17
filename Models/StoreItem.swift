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
}
