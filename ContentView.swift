import SwiftUI
import Combine

struct ContentView: View {

    @StateObject private var vm = GameViewModel()

    @State private var beeOffset: CGFloat = -6
    @State private var beeFlight: CGFloat = 0
    @State private var mapScale: CGFloat = 1.0
    @State private var mapOffset: CGSize = .zero
    @State private var isZooming = false
    @State private var showZoneDetail = false

    let timer = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color(red: 0.94, green: 0.93, blue: 0.86).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    headerCard
                    statsRow
                    mapSection
                    if vm.selectedZone != nil { habitatCard }
                    zonesSection
                    hivesSection
                    shopSection
                    logSection
                }
                .padding()
            }

            if let msg = vm.unlockMessage {
                VStack {
                    Spacer()
                    Text(msg)
                        .font(.headline.bold())
                        .foregroundStyle(.black)
                        .padding(.horizontal, 18).padding(.vertical, 12)
                        .background(Color.yellow.opacity(0.9))
                        .clipShape(Capsule())
                        .shadow(radius: 10)
                        .padding(.bottom, 40)
                        .transition(.scale.combined(with: .opacity))
                }
            }

            // Evento di gioco
            if let event = vm.activeEvent {
                eventOverlay(event: event)
            }
        }
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 1.2)) {
                beeOffset = beeOffset == -6 ? 6 : -6
                beeFlight = beeFlight == 0 ? 1 : 0
            }
        }
        .sheet(isPresented: $showZoneDetail) {
            zoneDetailView
        }
    }

    // MARK: - Header
    var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("🍯 Fynbos Bee")
                .font(.system(size: 30, weight: .bold, design: .serif))
            Text("Beekeeping simulator nel paesaggio fynbos sudafricano.")
                .font(.subheadline).foregroundStyle(.secondary)
            HStack {
                Label(
                    vm.fireActive ? "Fire bloom attivo" : "Stagione normale",
                    systemImage: vm.fireActive ? "flame.fill" : "leaf.fill"
                )
                .foregroundStyle(vm.fireActive ? .orange : .green)
                Spacer()
                Text("Giorno \(vm.day)")
                    .font(.caption.bold())
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(.thinMaterial).clipShape(Capsule())
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    // MARK: - Stats
    var statsRow: some View {
        HStack(spacing: 12) {
            statCard(title: "Miele (kg)", value: "\(Int(vm.honey))", icon: "drop.fill")
            statCard(title: "Monete", value: "\(vm.coins)", icon: "eurosign.circle.fill")
            statCard(title: "Alveari", value: "\(vm.hives.count)", icon: "shippingbox.fill")
        }
    }

    func statCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
            Text(value).font(.title3.bold())
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - Mappa
    var mapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mappa della riserva").font(.title3.bold())
            Text("Zona selezionata: \(vm.selectedZoneName)")
                .font(.subheadline).foregroundStyle(.secondary)

            ZStack {
                Image("fynbos_map")
                    .resizable()
                    .scaledToFill()
                    .scaleEffect(mapScale)
                    .offset(mapOffset)
                    .frame(maxWidth: .infinity)
                    .frame(height: 430)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in isZooming = true; mapScale = value }
                            .onEnded { _ in isZooming = false }
                    )

                mapMarker(x: 0.30, y: 0.28, color: .green, title: "Fynbos comune")
                mapMarker(x: 0.53, y: 0.33, color: .pink, title: "Erica irregularis")
                mapMarker(x: 0.50, y: 0.72, color: .orange, title: "Protea")
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                    if !isZooming { mapScale = 1.04; mapOffset = CGSize(width: 12, height: -10) }
                }
            }
            .frame(height: 430)
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }

    @ViewBuilder
    func mapMarker(x: CGFloat, y: CGFloat, color: Color, title: String) -> some View {
        GeometryReader { geo in
            Button {
                withAnimation { vm.selectedZoneName = title }
                if let zone = vm.zones.first(where: { $0.name == title }) {
                    vm.assignHive(to: zone)
                }
            } label: {
                Circle()
                    .fill(color)
                    .frame(width: 26, height: 26)
                    .overlay(Circle().stroke(.white, lineWidth: 3))
                    .shadow(
                        color: vm.selectedZoneName == title ? color.opacity(0.6) : .black.opacity(0.2),
                        radius: vm.selectedZoneName == title ? 12 : 6
                    )
                    .scaleEffect(vm.selectedZoneName == title ? 1.45 : 1.1)
                    .animation(.easeInOut(duration: 0.2), value: vm.selectedZoneName)
            }
            .position(x: geo.size.width * x, y: geo.size.height * y)
        }
    }

    // MARK: - Habitat Card
    var habitatCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let zone = vm.selectedZone {
                Text("Habitat").font(.title3.bold())
                VStack(alignment: .leading, spacing: 12) {
                    Image(zone.imageName)
                        .resizable().scaledToFit()
                        .frame(maxWidth: .infinity).frame(height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(radius: 6)

                    Text(zone.name).font(.headline)
                    Text(zone.plantName).font(.subheadline).foregroundStyle(.secondary)

                    HStack {
                        Text(zone.honeyType)
                        Spacer()
                        Text("\(String(format: "%.1f", zone.yieldPerTick))/tick")
                    }
                    .font(.subheadline).foregroundStyle(.secondary)

                    Text(zone.habitatDescription).font(.subheadline)
                    Text("Fauna: \(zone.faunaNotes)").font(.caption).foregroundStyle(.secondary)

                    Button("Entra nella zona") { showZoneDetail = true }
                        .buttonStyle(.borderedProminent)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.green, lineWidth: 1.5))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Zone
    var zonesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Zone botaniche").font(.title3.bold())

            ForEach(vm.zones) { zone in
                if zone.isUnlocked {
                    Button { vm.assignHive(to: zone) } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Circle().fill(.green.opacity(0.7))
                                .frame(width: 18, height: 18).padding(.top, 4)
                            VStack(alignment: .leading, spacing: 6) {
                                Text(zone.name).font(.headline)
                                Text("Resa: \(String(format: "%.1f", zone.yieldPerTick)) kg/turno")
                                    .font(.caption).foregroundStyle(.secondary)
                                Text("Disponibile").font(.caption.bold()).foregroundStyle(.green)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(vm.selectedZoneName == zone.name ? .green : .clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Circle().fill(.gray.opacity(0.5)).frame(width: 18, height: 18)
                            VStack(alignment: .leading, spacing: 6) {
                                Text(zone.name).font(.headline).foregroundStyle(.secondary)
                                Text("Bloccata").font(.caption.bold()).foregroundStyle(.orange)
                                Text("Costo: \(zone.unlockCost) monete").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        Button("Sblocca (\(zone.unlockCost) monete)") { vm.unlockZone(zone) }
                            .buttonStyle(.borderedProminent)
                            .disabled(vm.coins < zone.unlockCost)
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }
            }
        }
    }

    // MARK: - Alveari
    var hivesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("I tuoi alveari").font(.title3.bold())

            ForEach(vm.hives.indices, id: \.self) { index in
                let hive = vm.hives[index]
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(hive.name).font(.headline)
                        Spacer()
                        Text(vm.zoneName(for: hive))
                            .font(.caption.bold())
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(.thinMaterial).clipShape(Capsule())
                    }
                    Text("Api: \(hive.bees)").font(.caption).foregroundStyle(.secondary)

                    if let zoneID = hive.zoneID,
                       let zone = vm.zones.first(where: { $0.id == zoneID }) {
                        Text("Produzione: \(String(format: "%.2f", zone.yieldPerTick * Double(hive.bees) / 100))/tick")
                            .font(.caption.bold()).foregroundStyle(.green)
                    } else {
                        Text("Produzione: 0.00/tick").font(.caption.bold()).foregroundStyle(.secondary)
                    }

                    HStack(spacing: 10) {
                        Button("Raccogli 10") { vm.collectHoney() }.buttonStyle(.borderedProminent)
                        Button("Libera") { vm.freeHive(index: index) }.buttonStyle(.bordered)
                        Button("+ Api (10)") { vm.upgradeHive(index: index) }.buttonStyle(.bordered)
                    }
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(vm.selectedHiveID == hive.id ? .blue : .clear, lineWidth: 3)
                )
                .onTapGesture {
                    vm.selectedHiveID = hive.id
                    vm.log.insert("\(hive.name) selezionato. Ora scegli una zona.", at: 0)
                }
            }
        }
    }

    // MARK: - Shop
    var shopSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Gestione").font(.title3.bold())
            HStack(spacing: 12) {
                Button("Compra alveare (20)") { vm.buyHive() }.buttonStyle(.borderedProminent)
                Button("Vendi tutto il miele") { vm.sellHoney() }.buttonStyle(.borderedProminent)
            }
            Button(vm.fireActive ? "Fire bloom già attivo" : "Attiva incendio controllato") {
                vm.activateFire()
            }
            .buttonStyle(.bordered)
            .disabled(vm.fireActive)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Log
    var logSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Registro").font(.title3.bold())
            ForEach(Array(vm.log.prefix(6).enumerated()), id: \.offset) { _, item in
                Text("• \(item)").font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
    
    // MARK: - Zone Detail
        var zoneDetailView: some View {
            Group {
                if let zone = vm.selectedZone {
                    ZoneDetailView(
                        zone: zone,
                        hives: vm.hives,
                        onClose: { showZoneDetail = false }
                    )
                }
            }
        }

    // MARK: - Event Overlay
    func eventOverlay(event: GameEvent) -> some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            VStack(spacing: 20) {
                Text(event.title).font(.title.bold()).foregroundStyle(.white)
                Text(event.description).font(.body).foregroundStyle(.white)
                    .multilineTextAlignment(.center).padding(.horizontal)

                HStack(spacing: 20) {
                    Button("Gestisci") { vm.resolveEvent(accept: true) }
                        .buttonStyle(.borderedProminent)
                    Button("Ignora") { vm.resolveEvent(accept: false) }
                        .buttonStyle(.bordered).tint(.white)
                }
            }
            .padding(30)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
