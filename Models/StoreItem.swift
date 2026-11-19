import Foundation

enum EquipmentSlot: String, CaseIterable, Codable, Hashable {
    case head
    case body
    case charm

    var displayName: String {
        switch self {
        case .head: return "Cabeza"
        case .body: return "Vestimenta"
        case .charm: return "Amuleto"
        }
    }
}

enum StoreItem: String, CaseIterable, Codable, Hashable {
    case ribbon, feather, cactusHat
    case kupoRobe, chocoboHarness, mageCloak

    var name: String {
        switch self {
        case .ribbon: return "Lazo de kupó"
        case .feather: return "Pluma dorada"
        case .cactusHat: return "Sombrero espinoso"
        case .kupoRobe: return "Túnica kupó"
        case .chocoboHarness: return "Arnés de chocobo"
        case .mageCloak: return "Capa de mago"
        }
    }

    var slot: EquipmentSlot {
        switch self {
        case .ribbon: return .charm
        case .feather, .cactusHat: return .head
        case .kupoRobe, .chocoboHarness, .mageCloak: return .body
        }
    }

    var price: Int {
        switch self {
        case .ribbon: return 30
        case .feather: return 45
        case .cactusHat: return 60
        case .kupoRobe: return 75
        case .chocoboHarness: return 90
        case .mageCloak: return 120
        }
    }

    var symbolName: String {
        switch self {
        case .ribbon: return "gift.fill"
        case .feather: return "feather"
        case .cactusHat: return "crown.fill"
        case .kupoRobe: return "tshirt.fill"
        case .chocoboHarness: return "figure.walk"
        case .mageCloak: return "wand.and.stars"
        }
    }

    var bonusDescription: String {
        switch self {
        case .ribbon: return "El ánimo baja más despacio"
        case .feather: return "La energía se desgasta 12% más lento"
        case .cactusHat: return "La saciedad se desgasta 12% más lento"
        case .kupoRobe: return "El ánimo se desgasta 10% más lento"
        case .chocoboHarness: return "La saciedad se desgasta 10% más lento"
        case .mageCloak: return "Recupera energía al dormir 22% más rápido; +8% de experiencia"
        }
    }

    var careModifiers: PetCareModifiers {
        switch self {
        case .ribbon: return PetCareModifiers(happinessDecayMultiplier: 0.88)
        case .feather: return PetCareModifiers(energyDecayMultiplier: 0.88)
        case .cactusHat: return PetCareModifiers(hungerDecayMultiplier: 0.88)
        case .kupoRobe: return PetCareModifiers(happinessDecayMultiplier: 0.90)
        case .chocoboHarness: return PetCareModifiers(hungerDecayMultiplier: 0.90)
        case .mageCloak: return PetCareModifiers(sleepRecoveryMultiplier: 1.22, experienceGainMultiplier: 1.08)
        }
    }
}

enum Materia: String, CaseIterable, Codable, Hashable {
    case cure, fire, haste, regen

    var name: String {
        switch self {
        case .cure: return "Cura"
        case .fire: return "Piro"
        case .haste: return "Prisa"
        case .regen: return "Regenerar"
        }
    }

    var symbolName: String {
        switch self {
        case .cure: return "cross.case.fill"
        case .fire: return "flame.fill"
        case .haste: return "bolt.fill"
        case .regen: return "leaf.fill"
        }
    }

    var description: String {
        switch self {
        case .cure: return "Recupera 25 de energía y 8 de ánimo."
        case .fire: return "Anima a la mascota y otorga experiencia."
        case .haste: return "Recupera 38 de energía al instante."
        case .regen: return "Restaura 22 de saciedad y 8 de ánimo."
        }
    }

    var price: Int {
        switch self {
        case .cure: return 0
        case .fire: return 55
        case .haste: return 65
        case .regen: return 80
        }
    }

    var magicCost: Int {
        switch self {
        case .cure: return 18
        case .fire: return 28
        case .haste: return 24
        case .regen: return 32
        }
    }

    var passiveModifiers: PetCareModifiers {
        switch self {
        case .cure: return PetCareModifiers(happinessDecayMultiplier: 0.95)
        case .fire: return PetCareModifiers(experienceGainMultiplier: 1.15)
        case .haste: return PetCareModifiers(energyDecayMultiplier: 0.95)
        case .regen: return PetCareModifiers(hungerDecayMultiplier: 0.95)
        }
    }

    var passiveDescription: String {
        switch self {
        case .cure: return "El ánimo se desgasta 5% más lento"
        case .fire: return "Ganas 15% más experiencia en minijuegos"
        case .haste: return "La energía se desgasta 5% más lento"
        case .regen: return "La saciedad se desgasta 5% más lento"
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

    var symbolName: String {
        switch self {
        case .ration: return "takeoutbag.and.cup.and.straw.fill"
        case .gysahlGreens: return "leaf.fill"
        case .potion: return "bolt.heart.fill"
        case .ether: return "sparkles"
        }
    }

    var effectDescription: String {
        switch self {
        case .ration: return "Recupera 25 de saciedad."
        case .gysahlGreens: return "Recupera 45 de saciedad y 5 de ánimo."
        case .potion: return "Recupera 30 de energía."
        case .ether: return "Recupera 30 de ánimo."
        }
    }
}
