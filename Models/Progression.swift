import Foundation

enum EvolutionStage: Int, Codable, CaseIterable, Equatable {
    case hatchling = 1
    case apprentice = 5
    case veteran = 10
    case legendary = 20

    init(level: Int) {
        self = EvolutionStage.allCases.last(where: { level >= $0.rawValue }) ?? .hatchling
    }

    var title: String {
        switch self {
        case .hatchling: return "Compañero recién llegado"
        case .apprentice: return "Aventurero aprendiz"
        case .veteran: return "Héroe veterano"
        case .legendary: return "Leyenda del cristal"
        }
    }
}

enum HabitatDecoration: String, CaseIterable, Codable, Hashable {
    case crystalGarden, chocoboStable, moogleWorkshop, starLantern

    var name: String {
        switch self {
        case .crystalGarden: return "Jardín de cristal"
        case .chocoboStable: return "Establo dorado"
        case .moogleWorkshop: return "Taller kupó"
        case .starLantern: return "Farol estelar"
        }
    }
    var symbolName: String {
        switch self {
        case .crystalGarden: return "sparkles"
        case .chocoboStable: return "house.fill"
        case .moogleWorkshop: return "wrench.and.screwdriver.fill"
        case .starLantern: return "lightbulb.fill"
        }
    }
    var price: Int {
        switch self {
        case .crystalGarden: return 80
        case .chocoboStable: return 100
        case .moogleWorkshop: return 120
        case .starLantern: return 150
        }
    }
}

enum MiniGameMode: Int, CaseIterable {
    case crystalReflex
    case chocoboSprint
    case materiaRush

    var title: String {
        switch self {
        case .crystalReflex: return "Cristal"
        case .chocoboSprint: return "Chocobo"
        case .materiaRush: return "Materia"
        }
    }
}

enum GameAchievement: String, CaseIterable, Codable, Hashable {
    case firstFriend, levelFive, fashionista, materiaCollector, expeditionVeteran, reflexMaster, bestiary

    var title: String {
        switch self {
        case .firstFriend: return "Primer vínculo"
        case .levelFive: return "Aventura en marcha"
        case .fashionista: return "A la moda"
        case .materiaCollector: return "Aprendiz de mago"
        case .expeditionVeteran: return "Explorador"
        case .reflexMaster: return "Reflejos de héroe"
        case .bestiary: return "Bestiario del cristal"
        }
    }
    var detail: String {
        switch self {
        case .firstFriend: return "Adopta a tu primer compañero"
        case .levelFive: return "Alcanza el nivel 5"
        case .fashionista: return "Consigue una pieza de equipo"
        case .materiaCollector: return "Aprende 3 materias"
        case .expeditionVeteran: return "Completa 5 expediciones"
        case .reflexMaster: return "Gana 10 minijuegos"
        case .bestiary: return "Descubre las tres especies"
        }
    }
    var reward: Int {
        switch self {
        case .bestiary: return 50
        default: return 25
        }
    }

    var symbolName: String {
        switch self {
        case .firstFriend: return "heart.fill"
        case .levelFive: return "star.fill"
        case .fashionista: return "sparkles"
        case .materiaCollector: return "circle.hexagongrid.fill"
        case .expeditionVeteran: return "map.fill"
        case .reflexMaster: return "bolt.fill"
        case .bestiary: return "book.closed.fill"
        }
    }
}

struct ProgressionState: Codable, Equatable {
    var discoveredPets: Set<PetKind> = []
    var ownedDecorations: Set<HabitatDecoration> = []
    var equippedDecoration: HabitatDecoration?
    var unlockedAchievements: Set<GameAchievement> = []
    var completedExpeditions = 0
    var wonMiniGames = 0
}

struct GameSaveArchive: Codable {
    let formatVersion: Int
    let exportedAt: Date
    let values: [String: Data]

    init(values: [String: Data], exportedAt: Date = Date()) {
        formatVersion = 2
        self.exportedAt = exportedAt
        self.values = values
    }
}
