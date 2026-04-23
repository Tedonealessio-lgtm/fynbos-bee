import SwiftUI
import Combine

struct Zone: Identifiable {
    let id = UUID()
    let name: String
    let honeyType: String
    let yieldPerTick: Double
    let color: Color
    let unlocksAfterFire: Bool

    let plantName: String
    let habitatDescription: String
    let faunaNotes: String
    let imageName: String
}

struct Hive: Identifiable {
    let id = UUID()
    let name: String
    var zoneID: UUID?
}

struct ContentView: View {

    @State private var selectedZoneName: String = "Nessuna"
    @State private var honey: Double = 0
    @State private var coins: Int = 20
    @State private var hives: [Hive] = [
        Hive(name: "Alveare 1", zoneID: nil)
    ]

    @State private var day: Int = 1
    @State private var fireActive: Bool = false
    @State private var log: [String] = ["Benvenuto a Grootbos."]

    @State private var beeOffset: CGFloat = -6
    @State private var beeX: CGFloat = 0
    @State private var beeY: CGFloat = 0

    @State private var mapScale: CGFloat = 1.0
    @State private var mapOffset: CGSize = .zero
    @State private var isZooming = false

    @State private var zones: [Zone] = [
        Zone(
            name: "Fynbos comune",
            honeyType: "Wild Honey",
            yieldPerTick: 0.5,
            color: Color.green.opacity(0.7),
            unlocksAfterFire: false,
            plantName: "Fynbos misto",
            habitatDescription: "Vegetazione fynbos aperta, ricca di piccoli arbusti nettariferi e fioriture diffuse lungo i pendii.",
            faunaNotes: "Piccoli uccelli del capo, insetti impollinatori e microfauna del sottobosco.",
            imageName: "fynbos_common"
        ),
        Zone(
            name: "Erica irregularis",
            honeyType: "Floral Honey",
            yieldPerTick: 1.0,
            color: Color.pink.opacity(0.8),
            unlocksAfterFire: false,
            plantName: "Erica irregularis",
            habitatDescription: "Area dominata da eriche in fiore, con maggiore concentrazione di nettare e fioritura più evidente.",
            faunaNotes: "Api bottinatrici molto attive, coleotteri floreali e piccoli passeriformi.",
            imageName: "erica_field"
        ),
        Zone(
            name: "Wachendorfia paniculata",
            honeyType: "Fire Bloom Honey",
            yieldPerTick: 2.0,
            color: Color.orange.opacity(0.85),
            unlocksAfterFire: true,
            plantName: "Wachendorfia paniculata",
            habitatDescription: "Habitat post-incendio con fioritura specializzata, raro e molto produttivo per un periodo limitato.",
            faunaNotes: "Insetti opportunisti del post-fire, attività intensa di impollinazione e dinamica ecologica temporanea.",
            imageName: "fire_bloom"
        )
    ]
    
    var selectedZone: Zone? {
        zones.first(where: { $0.name == selectedZoneName })
    }

    let timer = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color(red: 0.94, green: 0.93, blue: 0.86)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    headerCard
                    statsRow
                    mapSection

                    if selectedZone != nil {
                        habitatCard
                    }

                    zonesSection
                    hivesSection
                    shopSection
                    logSection
                }
                .padding()
            }
        }
        .onReceive(timer) { _ in
            tick()

            withAnimation(.easeInOut(duration: 1.2)) {
                if beeOffset == -6 {
                    beeOffset = 6
                } else {
                    beeOffset = -6
                }

                beeX = CGFloat.random(in: -5...5)
                beeY = CGFloat.random(in: -5...5)
            }
        }
    }

    var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("🍯 Fynbos Bee")
                .font(.system(size: 30, weight: .bold, design: .serif))

            Text("Beekeeping simulator nel paesaggio fynbos sudafricano.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack {
                Label(
                    fireActive ? "Fire bloom attivo" : "Stagione normale",
                    systemImage: fireActive ? "flame.fill" : "leaf.fill"
                )
                .foregroundStyle(fireActive ? .orange : .green)

                Spacer()

                Text("Giorno \(day)")
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.thinMaterial)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    var mapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mappa della riserva")
                .font(.title3.bold())

            Text("Zona selezionata: \(selectedZoneName)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ZStack {
                Image("fynbos_map")
                    .resizable()
                    .scaleEffect(mapScale)
                    .offset(mapOffset)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                isZooming = true
                                mapScale = value
                            }
                            .onEnded { _ in
                                isZooming = false
                            }
                    )
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 430)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                mapMarker(x: 0.30, y: 0.28, color: .green, title: "Fynbos comune")
                mapMarker(x: 0.53, y: 0.33, color: .pink, title: "Erica irregularis")
                mapMarker(x: 0.50, y: 0.72, color: .orange, title: "Wachendorfia paniculata")
            }
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 6)
                    .repeatForever(autoreverses: true)
                ) {
                    if !isZooming {
                        mapScale = 1.04
                        mapOffset = CGSize(width: 12, height: -10)
                    }
                }
            }
            .frame(height: 430)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }
    
    var habitatCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let zone = selectedZone {
                Text("Habitat")
                    .font(.title3.bold())

                VStack(alignment: .leading, spacing: 12) {
                    Image(zone.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(height: 140)
                        .background(.white.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(radius: 6)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(zone.name)
                            .font(.headline)

                        Text(zone.plantName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text(zone.honeyType)
                        Spacer()
                        Text("\(String(format: "%.1f", zone.yieldPerTick))/tick")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    Text(zone.habitatDescription)
                        .font(.subheadline)

                    Text("Fauna: \(zone.faunaNotes)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(isZoneAvailable(zone) ? "Disponibile" : "Bloccata (fire bloom)")
                        .font(.caption.bold())
                        .foregroundStyle(isZoneAvailable(zone) ? .green : .orange)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial)
                .shadow(color: zone.color.opacity(0.25), radius: 10, x: 0, y: 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(zone.color, lineWidth: 1.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    func mapMarker(x: CGFloat, y: CGFloat, color: Color, title: String) -> some View {
        GeometryReader { geo in
            Button {
                withAnimation {
                    selectedZoneName = title
                }

                if let zone = zones.first(where: { $0.name == title }) {
                    assignHive(to: zone)
                }
            } label: {
                Circle()
                    .fill(color)
                    .frame(width: 26, height: 26)
                    .overlay(
                        ZStack {
                            Circle().stroke(.white, lineWidth: 3)

                            if let zone = zones.first(where: { $0.name == title }),
                               hives.contains(where: { $0.zoneID == zone.id }) {
                                Image(systemName: "shippingbox.fill")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(6)
                                    .background(.black.opacity(0.55))
                                    .clipShape(Circle())
                                    .offset(y: -24)
                            }

                            miniBee(offsetX: -10, offsetY: beeOffset, scale: 1.0)
                            miniBee(offsetX: 12, offsetY: -beeOffset, scale: 0.9)
                        }
                    )
                    .shadow(
                        color: selectedZoneName == title ? color.opacity(0.6) : .black.opacity(0.2),
                        radius: selectedZoneName == title ? 12 : 6
                    )
                    .scaleEffect(selectedZoneName == title ? 1.45 : 1.1)
                    .animation(.easeInOut(duration: 0.2), value: selectedZoneName)
            }
            .position(
                x: geo.size.width * x,
                y: geo.size.height * y
            )
        }
    }

    @ViewBuilder
    func miniBee(offsetX: CGFloat, offsetY: CGFloat, scale: CGFloat) -> some View {
        ZStack {
            Capsule()
                .fill(Color.yellow)
                .frame(width: 10, height: 6)

            Capsule()
                .fill(Color.black.opacity(0.75))
                .frame(width: 2, height: 6)
                .offset(x: -2)

            Capsule()
                .fill(Color.black.opacity(0.75))
                .frame(width: 2, height: 6)
                .offset(x: 2)

            Circle()
                .fill(Color.white.opacity(0.85))
                .frame(width: 5, height: 5)
                .offset(x: -2, y: -4)

            Circle()
                .fill(Color.white.opacity(0.85))
                .frame(width: 5, height: 5)
                .offset(x: 2, y: -4)
        }
        .scaleEffect(scale)
        .offset(
            x: offsetX + beeX + sin(beeOffset) * 2,
            y: offsetY + beeY
        )
    }

    var statsRow: some View {
        HStack(spacing: 12) {
            statCard(title: "Miele", value: "\(Int(honey))", icon: "drop.fill")
            statCard(title: "Monete", value: "\(coins)", icon: "eurosign.circle.fill")
            statCard(title: "Alveari", value: "\(hives.count)", icon: "shippingbox.fill")
        }
    }

    func statCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
            Text(value)
                .font(.title3.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    var zonesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Zone botaniche")
                .font(.title3.bold())

            ForEach(zones) { zone in
                Button {
                    assignHive(to: zone)
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Circle()
                            .fill(isZoneAvailable(zone) ? zone.color : .gray.opacity(0.4))
                            .frame(width: 18, height: 18)
                            .padding(.top, 4)

                        VStack(alignment: .leading, spacing: 6) {
                            Text(zone.name)
                                .font(.headline)

                            Text("Miele: \(zone.honeyType)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text("Resa: \(String(format: "%.1f", zone.yieldPerTick))/tick")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(isZoneAvailable(zone) ? "Disponibile" : "Si sblocca dopo incendio")
                                .font(.caption.bold())
                                .foregroundStyle(isZoneAvailable(zone) ? .green : .orange)
                        }

                        Spacer()
                    }
                    .padding()
                    .background(
                        selectedZoneName == zone.name
                        ? AnyShapeStyle(zone.color.opacity(0.15))
                        : AnyShapeStyle(.regularMaterial)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                selectedZoneName == zone.name ? zone.color : .clear,
                                lineWidth: 2
                            )
                    )
                    .scaleEffect(selectedZoneName == zone.name ? 1.02 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: selectedZoneName)
                }
                .buttonStyle(.plain)
            }
        }
    }

    var hivesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("I tuoi alveari")
                .font(.title3.bold())

            ForEach(hives.indices, id: \.self) { index in
                let hive = hives[index]

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(hive.name)
                            .font(.headline)

                        Spacer()

                        Text(zoneName(for: hive))
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.thinMaterial)
                            .clipShape(Capsule())
                    }

                    HStack(spacing: 10) {
                        Button("Raccogli 10") {
                            collectHoney()
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Libera") {
                            hives[index].zoneID = nil
                            log.insert("\(hive.name) liberato dalla zona.", at: 0)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }
        }
    }

    var shopSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Gestione")
                .font(.title3.bold())

            HStack(spacing: 12) {
                Button("Compra alveare (20)") {
                    buyHive()
                }
                .buttonStyle(.borderedProminent)

                Button("Vendi 10 miele") {
                    if honey >= 10 {
                        honey -= 10
                        coins += 6
                        log.insert("Hai venduto 10 miele.", at: 0)
                    } else {
                        log.insert("Miele insufficiente per vendere.", at: 0)
                    }
                }
                .buttonStyle(.bordered)
            }

            Button(fireActive ? "Fire bloom già attivo" : "Attiva incendio controllato") {
                if !fireActive {
                    fireActive = true
                    log.insert("Un incendio controllato ha attivato la fioritura rara.", at: 0)
                }
            }
            .buttonStyle(.bordered)
            .disabled(fireActive)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var logSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Registro")
                .font(.title3.bold())

            ForEach(Array(log.prefix(6).enumerated()), id: \.offset) { _, item in
                Text("• \(item)")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    func tick() {
        day += 1

        for hive in hives {
            guard let zoneID = hive.zoneID,
                  let zone = zones.first(where: { $0.id == zoneID }),
                  isZoneAvailable(zone)
            else { continue }

            honey += zone.yieldPerTick
        }

        if fireActive && day % 10 == 0 {
            fireActive = false
            log.insert("La fioritura post-incendio è terminata.", at: 0)

            for i in hives.indices {
                if let zoneID = hives[i].zoneID,
                   let zone = zones.first(where: { $0.id == zoneID }),
                   zone.unlocksAfterFire {
                    hives[i].zoneID = nil
                }
            }
        }
    }

    func buyHive() {
        if coins >= 20 {
            coins -= 20
            hives.append(Hive(name: "Alveare \(hives.count + 1)", zoneID: nil))
            log.insert("Hai comprato un nuovo alveare.", at: 0)
        } else {
            log.insert("Monete insufficienti.", at: 0)
        }
    }

    func collectHoney() {
        if honey >= 10 {
            honey -= 10
            coins += 5
            log.insert("Hai raccolto 10 miele.", at: 0)
        } else {
            log.insert("Miele insufficiente da raccogliere.", at: 0)
        }
    }

    func assignHive(to zone: Zone) {
        guard isZoneAvailable(zone) else {
            log.insert("Questa zona è bloccata.", at: 0)
            return
        }

        guard let index = hives.firstIndex(where: { $0.zoneID == nil }) else {
            log.insert("Nessun alveare libero da assegnare.", at: 0)
            return
        }

        hives[index].zoneID = zone.id
        selectedZoneName = zone.name
        log.insert("\(hives[index].name) assegnato a \(zone.name).", at: 0)
    }

    func zoneName(for hive: Hive) -> String {
        guard let zoneID = hive.zoneID,
              let zone = zones.first(where: { $0.id == zoneID }) else {
            return "Non assegnato"
        }
        return zone.name
    }

    func isZoneAvailable(_ zone: Zone) -> Bool {
        if zone.unlocksAfterFire {
            return fireActive
        }
        return true
    }
}

#Preview {
    ContentView()
}
