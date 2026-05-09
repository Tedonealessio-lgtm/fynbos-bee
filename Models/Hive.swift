import Foundation

enum QueenStatus: String, Codable {
    case healthy      // 👑 Sana
    case aging        // ⚠️ Sta invecchiando
    case weak         // 🔴 Debole
    case dead         // 💀 Morta
}

struct Queen: Codable {
    var age: Int          // giorni di gioco
    var health: Double    // 0.0 - 1.0
    var status: QueenStatus

    var statusEmoji: String {
        switch status {
        case .healthy: return "👑"
        case .aging:   return "⚠️"
        case .weak:    return "🔴"
        case .dead:    return "💀"
        }
    }

    var statusDescription: String {
        switch status {
        case .healthy: return "Regina in ottima salute"
        case .aging:   return "Regina sta invecchiando"
        case .weak:    return "Regina debole — sostituiscila!"
        case .dead:    return "Regina morta — colonia in pericolo!"
        }
    }

    // Aggiorna stato in base all'età
    mutating func updateStatus() {
        if age < 200 {
            status = .healthy
            health = 1.0
        } else if age < 400 {
            status = .aging
            health = 0.7
        } else if age < 600 {
            status = .weak
            health = 0.4
        } else {
            status = .dead
            health = 0.0
        }
    }
}

struct Hive: Identifiable, Codable {
    let id: UUID
    var name: String
    var zoneID: UUID?
    var bees: Int
    var queen: Queen
    var lastInspection: Int  // giorno dell'ultima ispezione
    var hasDisease: Bool = false
    var hasHornet: Bool = false

    // Produzione modificata da salute regina
    var productionMultiplier: Double {
        switch queen.status {
        case .healthy: return 1.0
        case .aging:   return 0.7
        case .weak:    return 0.4
        case .dead:    return 0.1
        }
    }

    var needsInspection: Bool {
        // Ispezione necessaria ogni 50 giorni
        return false // calcolato nel ViewModel
    }

    init(name: String, zoneID: UUID? = nil, bees: Int) {
        self.id = UUID()
        self.name = name
        self.zoneID = zoneID
        self.bees = bees
        self.queen = Queen(age: 0, health: 1.0, status: .healthy)
        self.lastInspection = 0
    }
}
