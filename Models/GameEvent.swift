import Foundation

enum GameEventType: String, Codable {
    case hornet        // Calabrone
    case disease       // Malattia
    case swarm         // Sciamatura
    case drought       // Siccità
    case goodSeason    // Stagione ottima
}

struct GameEvent: Identifiable {
    let id = UUID()
    let type: GameEventType
    let title: String
    let description: String
    let impact: Double   // positivo o negativo
}
