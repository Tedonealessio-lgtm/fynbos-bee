import Foundation

enum EquipmentType: String, Codable {
    case smoker          // Fumatore
    case gloves          // Guanti
    case suit            // Tuta apistica
    case sugarSyrup      // Sciroppo zucchero
    case oxalicAcid      // Acido ossalico (Varroa)
    case hornetTrap      // Trappola calabrone
    case honeySuper      // Melario
}

struct Equipment: Identifiable, Codable {
    let id: UUID
    let type: EquipmentType
    var quantity: Int

    var name: String {
        switch type {
        case .smoker:     return "Fumatore"
        case .gloves:     return "Guanti"
        case .suit:       return "Tuta apistica"
        case .sugarSyrup: return "Sciroppo zucchero"
        case .oxalicAcid: return "Acido ossalico"
        case .hornetTrap: return "Trappola calabrone"
        case .honeySuper: return "Melario"
        }
    }

    var emoji: String {
        switch type {
        case .smoker:     return "🔥"
        case .gloves:     return "🧤"
        case .suit:       return "🦺"
        case .sugarSyrup: return "🍬"
        case .oxalicAcid: return "💊"
        case .hornetTrap: return "🪤"
        case .honeySuper: return "🏠"
        }
    }

    var description: String {
        switch type {
        case .smoker:     return "Necessario per ispezionare senza perdere api"
        case .gloves:     return "Protezione dalle punture"
        case .suit:       return "Protezione completa — ispezione sicura"
        case .sugarSyrup: return "Nutrimento in siccità o inverno"
        case .oxalicAcid: return "Cura la Varroa — usa subito!"
        case .hornetTrap: return "Difende l'alveare dai calabroni"
        case .honeySuper: return "+50% capacità produzione miele"
        }
    }

    var cost: Int {
        switch type {
        case .smoker:     return 50
        case .gloves:     return 30
        case .suit:       return 80
        case .sugarSyrup: return 20
        case .oxalicAcid: return 40
        case .hornetTrap: return 35
        case .honeySuper: return 60
        }
    }

    init(type: EquipmentType, quantity: Int = 0) {
        self.id = UUID()
        self.type = type
        self.quantity = quantity
    }
}
