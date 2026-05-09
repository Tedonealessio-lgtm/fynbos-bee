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
    @State private var showShop = false

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
        .sheet(isPresented: $showZoneDetail) { zoneDetailView }
        .sheet(isPresented: $showShop) { ShopView(vm: vm) }
    }

    // MARK: - Header
    var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("🍯 Fynbos Bee")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                    Text("Grootbos Nature Reserve 🇿🇦")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                // Badge stagione
                VStack(spacing: 2) {
                    Text(vm.season.emoji)
                        .font(.title2)
                    Text(vm.season.rawValue)
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                }
                .padding(10)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            HStack {
                Label(
                    vm.fireActive ? "Fire bloom attivo" : vm.season.description,
                    systemImage: vm.fireActive ? "flame.fill" : "leaf.fill"
                )
                .font(.caption)
                .foregroundStyle(vm.fireActive ? .orange : .green)

                Spacer()
                
                // Badge livello
                Text(vm.playerTitle)
                    .font(.caption.bold())
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Color.yellow.opacity(0.3))
                    .clipShape(Capsule())

                Text("Giorno \(vm.day)")
                    .font(.caption.bold())
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(.thinMaterial).clipShape(Capsule())
            }

            // Barra ispezione
            if vm.inspectionNeeded {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Ispezione necessaria!")
                        .font(.caption.bold())
                        .foregroundStyle(.orange)
                    Spacer()
                    Button("Ispeziona ora") { vm.performInspection() }
                        .font(.caption.bold())
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                }
                .padding(10)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
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
            statCard(title: "Miele (kg)", value: "\(Int(vm.honey))", icon: "drop.fill", color: .yellow)
            statCard(title: "Monete", value: "\(vm.coins)", icon: "eurosign.circle.fill", color: .orange)
            statCard(title: "Alveari", value: "\(vm.hives.count)", icon: "house.fill", color: .brown)
        }
    }

    func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.title3)
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
            HStack {
                Text("🗺️ Mappa della riserva")
                    .font(.title3.bold())
                Spacer()
                Text(vm.selectedZoneName)
                    .font(.caption.bold())
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(.thinMaterial)
                    .clipShape(Capsule())
            }

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
                Text("🌿 Habitat").font(.title3.bold())
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

                    Button("Entra nella zona →") { showZoneDetail = true }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.green.opacity(0.5), lineWidth: 1.5))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Zone
    var zonesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🌺 Zone botaniche").font(.title3.bold())

            ForEach(vm.zones) { zone in
                if zone.isUnlocked {
                    Button { vm.assignHive(to: zone) } label: {
                        HStack(spacing: 12) {
                            Circle().fill(.green.opacity(0.7))
                                .frame(width: 14, height: 14)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(zone.name).font(.headline)
                                Text("Resa: \(String(format: "%.1f", zone.yieldPerTick)) kg/turno")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(vm.selectedZoneName == zone.name ? Color.green : .clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Circle().fill(.gray.opacity(0.4)).frame(width: 14, height: 14)
                            Text(zone.name).font(.headline).foregroundStyle(.secondary)
                            Spacer()
                            Text("🔒 \(zone.unlockCost) monete")
                                .font(.caption.bold()).foregroundStyle(.orange)
                        }
                        Button("Sblocca zona") { vm.unlockZone(zone) }
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
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
            Text("🏡 I tuoi alveari").font(.title3.bold())

            ForEach(vm.hives.indices, id: \.self) { index in
                let hive = vm.hives[index]
                VStack(alignment: .leading, spacing: 10) {

                    HStack {
                        Text(hive.name).font(.headline)
                        Spacer()
                        Text(vm.zoneName(for: hive))
                            .font(.caption.bold())
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(.thinMaterial).clipShape(Capsule())
                    }

                    // Regina
                    HStack(spacing: 8) {
                        Text(hive.queen.statusEmoji).font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(hive.queen.statusDescription)
                                .font(.caption.bold())
                                .foregroundStyle(queenColor(hive.queen.status))
                            Text("Età: \(hive.queen.age) giorni")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.3)).frame(height: 6)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(queenColor(hive.queen.status))
                                    .frame(width: geo.size.width * hive.queen.health, height: 6)
                            }
                        }
                        .frame(width: 60, height: 6)
                    }
                    .padding(10)
                    .background(queenColor(hive.queen.status).opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    HStack {
                        Label("\(hive.bees) api", systemImage: "ant.fill")
                            .font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        if let zoneID = hive.zoneID,
                           let zone = vm.zones.first(where: { $0.id == zoneID }) {
                            let prod = zone.yieldPerTick * Double(hive.bees) / 100 * hive.productionMultiplier * vm.season.productionMultiplier
                            Text(String(format: "%.2f kg/tick", prod))
                                .font(.caption.bold()).foregroundStyle(.green)
                        }
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            Button("🍯 Raccogli") { vm.collectHoney() }
                                .buttonStyle(.borderedProminent).tint(.orange)
                            Button("🔓 Libera") { vm.freeHive(index: index) }
                                .buttonStyle(.bordered)
                            Button("🐝 +Api") { vm.upgradeHive(index: index) }
                                .buttonStyle(.bordered)
                            if hive.queen.status != .healthy {
                                Button("👑 Nuova Regina") { vm.replaceQueen(hiveIndex: index) }
                                    .buttonStyle(.borderedProminent)
                                    .tint(queenColor(hive.queen.status))
                            }
                        }
                        .font(.caption.bold())
                    }
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(vm.selectedHiveID == hive.id ? Color.blue : .clear, lineWidth: 2)
                )
                .onTapGesture {
                    vm.selectedHiveID = hive.id
                    vm.log.insert("\(hive.name) selezionato.", at: 0)
                }
            }
        }
    }

    func queenColor(_ status: QueenStatus) -> Color {
        switch status {
        case .healthy: return .green
        case .aging:   return .yellow
        case .weak:    return .orange
        case .dead:    return .red
        }
    }

    // MARK: - Shop Section
    var shopSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("⚙️ Gestione").font(.title3.bold())

            HStack(spacing: 12) {
                Button { showShop = true } label: {
                    Label("Shop", systemImage: "cart.fill")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.orange)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button { vm.buyHive() } label: {
                    Label("Nuovo alveare", systemImage: "plus.circle.fill")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.brown.opacity(0.8))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }

            HStack(spacing: 12) {
                Button { vm.sellHoney() } label: {
                    Label("Vendi miele", systemImage: "dollarsign.circle.fill")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.green.opacity(0.8))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button { vm.activateFire() } label: {
                    Label(vm.fireActive ? "Attivo" : "Incendio", systemImage: "flame.fill")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(vm.fireActive ? Color.gray : Color.red.opacity(0.7))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(vm.fireActive)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Log
    var logSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("📋 Registro").font(.title3.bold())
            ForEach(Array(vm.log.prefix(8).enumerated()), id: \.offset) { _, item in
                HStack(alignment: .top, spacing: 8) {
                    Circle().fill(Color.green.opacity(0.5))
                        .frame(width: 6, height: 6)
                        .padding(.top, 6)
                    Text(item).font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
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
                ZoneDetailView(zone: zone, hives: vm.hives, onClose: { showZoneDetail = false })
            }
        }
    }

    // MARK: - Event Overlay
    func eventOverlay(event: GameEvent) -> some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            VStack(spacing: 20) {
                Text(event.title).font(.title.bold()).foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text(event.description).font(.body).foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center).padding(.horizontal)

                HStack(spacing: 16) {
                    Button("✅ Gestisci") { vm.resolveEvent(accept: true) }
                        .buttonStyle(.borderedProminent).tint(.green)
                    Button("❌ Ignora") { vm.resolveEvent(accept: false) }
                        .buttonStyle(.bordered).tint(.white)
                }
            }
            .padding(30)
            .background(Color(red: 0.94, green: 0.93, blue: 0.86))
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(radius: 20)
            .padding(24)
        }
    }
}

#Preview {
    ContentView()
}
