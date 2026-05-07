import SwiftUI

struct Zone: Identifiable, Codable {
    let id: UUID
    let name: String
    let imageName: String
    let habitatDescription: String
    let yieldPerTick: Double
    var isUnlocked: Bool
    let unlockCost: Int
    let plantName: String
    let faunaNotes: String
    let honeyType: String
}
