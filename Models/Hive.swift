import Foundation

struct Hive: Identifiable, Codable {
    let id: UUID
    var name: String
    var zoneID: UUID?
    var bees: Int

    init(name: String, zoneID: UUID? = nil, bees: Int) {
        self.id = UUID()
        self.name = name
        self.zoneID = zoneID
        self.bees = bees
    }
}
