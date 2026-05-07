import SwiftUI
import Combine
import AVFoundation

@MainActor
class GameViewModel: ObservableObject {

    // MARK: - Stato principale
    @Published var honey: Double = 0
    @Published var coins: Int = 100
    @Published var day: Int = 1
    @Published var fireActive: Bool = false
    @Published var log: [String] = ["Benvenuto a Grootbos. 🌿"]

    // MARK: - Alveari e Zone
    @Published var hives: [Hive] = [
        Hive(name: "Alveare 1", zoneID: nil, bees: 100)
    ]

    @Published var zones: [Zone] = [
        Zone(id: UUID(), name: "Fynbos comune", imageName: "fynbos_common",
             habitatDescription: "Vegetazione fynbos aperta, ricca di piccoli arbusti nettariferi.",
             yieldPerTick: 1.0, isUnlocked: true, unlockCost: 0,
             plantName: "Restio, Leucadendron", faunaNotes: "Sunbird, Cape sugarbird",
             honeyType: "Wild Fynbos Honey"),
        Zone(id: UUID(), name: "Erica irregularis", imageName: "erica_field",
             habitatDescription: "Area dominata da eriche in fiore.",
             yieldPerTick: 1.5, isUnlocked: true, unlockCost: 20,
             plantName: "Erica irregularis", faunaNotes: "Orange-breasted sunbird",
             honeyType: "Erica Honey"),
        Zone(id: UUID(), name: "Protea", imageName: "fire_bloom",
             habitatDescription: "Zona dominata da protee del fynbos.",
             yieldPerTick: 2.0, isUnlocked: false, unlockCost: 60,
             plantName: "Protea cynaroides", faunaNotes: "Cape sugarbird, beetles",
             honeyType: "Protea Honey")
    ]

    // MARK: - Eventi di gioco
    @Published var activeEvent: GameEvent? = nil

    // MARK: - UI State
    @Published var selectedZoneName: String = "Nessuna"
    @Published var selectedHiveID: UUID? = nil
    @Published var unlockMessage: String? = nil
    @Published var lastUnlockedZoneID: UUID? = nil

    var selectedZone: Zone? {
        zones.first(where: { $0.name == selectedZoneName })
    }

    // MARK: - Timer
    private var cancellables = Set<AnyCancellable>()

    init() {
        loadGame()

        Timer.publish(every: 1.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
            .store(in: &cancellables)
        AudioManager.shared.playBeesAmbience()

        // Salva quando l'app va in background
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in self?.saveGame() }
            .store(in: &cancellables)

        // Salva quando l'app sta per chiudersi
        NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)
            .sink { [weak self] _ in self?.saveGame() }
            .store(in: &cancellables)
    }

    // MARK: - Tick principale
    func tick() {
        day += 1
        for hive in hives {
            guard let zoneID = hive.zoneID,
                  let zone = zones.first(where: { $0.id == zoneID }),
                  zone.isUnlocked else { continue }
            let production = zone.yieldPerTick * Double(hive.bees) / 100
            honey += production
        }
        if day % 150 == 0 { triggerRandomEvent() }
        if fireActive && day % 10 == 0 {
            fireActive = false
            addLog("La fioritura post-incendio è terminata. 🔥")
            if day % 10 == 0 { saveGame() }
        }
    }

    // MARK: - Azioni
    func assignHive(to zone: Zone) {
        guard zone.isUnlocked else { addLog("Questa zona è bloccata."); return }
        guard let selectedHiveID else {
            selectedZoneName = zone.name
            addLog("Seleziona prima un alveare.")
            return
        }
        guard let index = hives.firstIndex(where: { $0.id == selectedHiveID }) else { return }
        hives[index].zoneID = zone.id
        selectedZoneName = zone.name
        addLog("\(hives[index].name) assegnato a \(zone.name).")
        self.selectedHiveID = nil
    }

    func unlockZone(_ zone: Zone) {
        guard coins >= zone.unlockCost else {
            addLog("Monete insufficienti per sbloccare \(zone.name).")
            return
        }
        coins -= zone.unlockCost
        if let index = zones.firstIndex(where: { $0.id == zone.id }) {
            zones[index].isUnlocked = true
        }
        lastUnlockedZoneID = zone.id
        unlockMessage = "🌸 \(zone.name) sbloccata!"
        addLog("Zona \(zone.name) sbloccata!")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            self.unlockMessage = nil
        }
    }

    func buyHive() {
        guard coins >= 20 else { addLog("Monete insufficienti."); return }
        coins -= 20
        hives.append(Hive(name: "Alveare \(hives.count + 1)", zoneID: nil, bees: 80))
        addLog("Hai comprato un nuovo alveare. 🏡")
    }

    func collectHoney() {
        AudioManager.shared.playHoneyCollect()
        guard honey >= 10 else { addLog("Miele insufficiente."); return }
        honey -= 10
        coins += 5
        addLog("Hai raccolto 10 kg di miele. 🍯")
    }

    func sellHoney() {
        let amount = Int(honey)
        guard amount > 0 else { addLog("Nessun miele da vendere."); return }
        let earnings = amount * 2
        coins += earnings
        honey = 0
        addLog("Venduti \(amount) kg → +\(earnings) monete. 💰")
    }

    func upgradeHive(index: Int) {
        guard coins >= 10 else { addLog("Monete insufficienti."); return }
        coins -= 10
        hives[index].bees += 20
        addLog("\(hives[index].name): +20 api. 🐝")
    }

    func freeHive(index: Int) {
        let name = hives[index].name
        hives[index].zoneID = nil
        addLog("\(name) liberato dalla zona.")
    }

    func activateFire() {
        guard !fireActive else { return }
        fireActive = true
        addLog("Incendio controllato attivato. 🔥")
    }

    func zoneName(for hive: Hive) -> String {
        guard let zoneID = hive.zoneID,
              let zone = zones.first(where: { $0.id == zoneID }) else {
            return "Non assegnato"
        }
        return zone.name
    }

    // MARK: - Eventi casuali
    func triggerRandomEvent() {
        let events: [GameEvent] = [
            GameEvent(type: .hornet, title: "🐝 Attacco calabrone!",
                      description: "Un calabrone orientale attacca un alveare. Perdi il 20% delle api.",
                      impact: -0.2),
            GameEvent(type: .disease, title: "🦠 Varroa detectata",
                      description: "L'acaro Varroa si è diffuso. Produzione ridotta del 30%.",
                      impact: -0.3),
            GameEvent(type: .swarm, title: "🌿 Sciamatura!",
                      description: "Un alveare sta sciamando. Potresti perdere metà delle api.",
                      impact: -0.5),
            GameEvent(type: .goodSeason, title: "☀️ Stagione eccellente!",
                      description: "Le protee fioriscono abbondantemente. +50% produzione.",
                      impact: 0.5)
        ]
        activeEvent = events.randomElement()
        AudioManager.shared.playEventAlert()
        if let event = activeEvent { addLog(event.title) }
    }

    func resolveEvent(accept: Bool) {
        guard let event = activeEvent else { return }
        if accept {
            applyEventImpact(event)
            switch event.type {
            case .hornet:
                addLog("🐝 Hai difeso gli alveari dal calabrone!")
            case .disease:
                addLog("🦠 Hai trattato la Varroa con acido ossalico.")
            case .swarm:
                addLog("🌿 Hai recuperato lo sciame con una nuova arnia.")
            case .drought:
                addLog("💧 Hai integrato con sciroppo di zucchero.")
            case .goodSeason:
                addLog("☀️ Stagione eccellente! Produzione aumentata.")
            }
        } else {
            addLog("⚠️ Evento ignorato — conseguenze possibili.")
        }
        activeEvent = nil
    }

    private func applyEventImpact(_ event: GameEvent) {
        for i in hives.indices {
            let currentBees = Double(hives[i].bees)
            let newBees = max(10, Int(currentBees + currentBees * event.impact))
            hives[i].bees = newBees
        }
        addLog("Impatto: \(event.impact > 0 ? "+" : "")\(Int(event.impact * 100))%")
    }

    private func addLog(_ message: String) {
        log.insert(message, at: 0)
        if log.count > 20 { log.removeLast() }
    }
    
    // MARK: - Salvataggio
    func saveGame() {
        UserDefaults.standard.set(honey, forKey: "honey")
        UserDefaults.standard.set(coins, forKey: "coins")
        UserDefaults.standard.set(day, forKey: "day")
        UserDefaults.standard.set(fireActive, forKey: "fireActive")

        if let hivesData = try? JSONEncoder().encode(hives) {
            UserDefaults.standard.set(hivesData, forKey: "hives")
        }
        if let zonesData = try? JSONEncoder().encode(zones) {
            UserDefaults.standard.set(zonesData, forKey: "zones")
        }
        if let logData = try? JSONEncoder().encode(log) {
            UserDefaults.standard.set(logData, forKey: "log")
        }
    }

    func loadGame() {
        let savedHoney = UserDefaults.standard.double(forKey: "honey")
        if savedHoney > 0 { honey = savedHoney }

        let savedCoins = UserDefaults.standard.integer(forKey: "coins")
        if savedCoins > 0 { coins = savedCoins }

        let savedDay = UserDefaults.standard.integer(forKey: "day")
        if savedDay > 0 { day = savedDay }

        fireActive = UserDefaults.standard.bool(forKey: "fireActive")

        if let hivesData = UserDefaults.standard.data(forKey: "hives"),
           let savedHives = try? JSONDecoder().decode([Hive].self, from: hivesData) {
            hives = savedHives
        }
        if let zonesData = UserDefaults.standard.data(forKey: "zones"),
           let savedZones = try? JSONDecoder().decode([Zone].self, from: zonesData) {
            zones = savedZones
        }
        if let logData = UserDefaults.standard.data(forKey: "log"),
           let savedLog = try? JSONDecoder().decode([String].self, from: logData) {
            log = savedLog
        }
    }
}
