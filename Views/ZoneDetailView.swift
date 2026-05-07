import SwiftUI

struct ZoneDetailView: View {
    let zone: Zone
    let hives: [Hive]
    var onClose: () -> Void

    @State private var appeared = false
    @State private var beeOffset: CGFloat = 0

    var body: some View {
        ZStack(alignment: .top) {

            // Sfondo
            Color(red: 0.10, green: 0.12, blue: 0.10).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // HERO IMAGE

                    // CONTENUTO
                    VStack(alignment: .leading, spacing: 24) {
                        habitatSection
                        if !hivesInZone.isEmpty { hivesSection }
                        floraFaunaSection
                        honeySection
                    }
                    .padding(20)
                    .background(Color(red: 0.10, green: 0.12, blue: 0.10))
                }
            }

            // Bottone chiudi
            HStack {
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.white.opacity(0.8))
                        .shadow(radius: 8)
                }
                .padding(20)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { appeared = true }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                beeOffset = 8
            }
            AudioManager.shared.playBeesAmbience()
        }
        .onDisappear {
            AudioManager.shared.fadeOut()
        }
    }

    var hivesInZone: [Hive] {
        hives.filter { $0.zoneID == zone.id }
    }

    // MARK: - Hero
    var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            Image(zone.imageName)
                .resizable()
                .scaledToFit() 
                .frame(maxWidth: .infinity)
                .frame(height: 320)
                .clipped()
                .overlay(
                    LinearGradient(
                        colors: [.clear, Color(red: 0.10, green: 0.12, blue: 0.10)],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(zone.name)
                    .font(.system(size: 34, weight: .bold, design: .serif))
                    .foregroundStyle(.white)

                Text(zone.plantName)
                    .font(.subheadline.italic())
                    .foregroundStyle(.white.opacity(0.7))

                HStack(spacing: 6) {
                    Image(systemName: "drop.fill")
                        .foregroundStyle(.yellow)
                    Text(zone.honeyType)
                        .font(.caption.bold())
                        .foregroundStyle(.yellow)
                }
            }
            .padding(20)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
        }
    }

    // MARK: - Habitat
    var habitatSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZoneSceneView(zone: zone, hives: hives)
                        .frame(height: 220)
            Label("Habitat", systemImage: "leaf.fill")
                .font(.title3.bold())
                .foregroundStyle(.green)

            Text(zone.habitatDescription)
                .font(.body)
                .foregroundStyle(.white.opacity(0.85))
                .lineSpacing(6)

            // Stats resa
            HStack(spacing: 16) {
                statBadge(icon: "drop.fill", value: "\(String(format: "%.1f", zone.yieldPerTick))", label: "kg/tick", color: .yellow)
                statBadge(icon: "lock.open.fill", value: zone.isUnlocked ? "Aperta" : "Bloccata", label: "", color: .green)
            }
        }
    }

    // MARK: - Alveari
    var hivesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Alveari attivi", systemImage: "shippingbox.fill")
                .font(.title3.bold())
                .foregroundStyle(.yellow)

            ForEach(hivesInZone) { hive in
                HStack(spacing: 14) {
                    // Icona alveare
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.72, green: 0.50, blue: 0.25))
                            .frame(width: 48, height: 48)
                        Text("🏡").font(.title2)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(hive.name).font(.headline).foregroundStyle(.white)
                        Text("🐝 \(hive.bees) api").font(.subheadline).foregroundStyle(.white.opacity(0.7))
                        Text("Produzione: \(String(format: "%.2f", zone.yieldPerTick * Double(hive.bees) / 100)) kg/tick")
                            .font(.caption.bold()).foregroundStyle(.yellow)
                    }

                    Spacer()

                    // Api animate
                    Text("🐝")
                        .font(.title)
                        .offset(y: beeOffset)
                }
                .padding(14)
                .background(Color.white.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    // MARK: - Flora e Fauna
    var floraFaunaSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Flora & Fauna", systemImage: "bird.fill")
                .font(.title3.bold())
                .foregroundStyle(.mint)

            HStack(spacing: 12) {
                infoCard(icon: "🌿", title: "Piante", value: zone.plantName)
                infoCard(icon: "🦅", title: "Fauna", value: zone.faunaNotes)
            }
        }
    }

    // MARK: - Miele
    var honeySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Miele prodotto", systemImage: "drop.fill")
                .font(.title3.bold())
                .foregroundStyle(.yellow)

            HStack(spacing: 14) {
                Text("🍯").font(.system(size: 44))
                VStack(alignment: .leading, spacing: 4) {
                    Text(zone.honeyType)
                        .font(.headline).foregroundStyle(.white)
                    Text("Miele artigianale di Grootbos — sudafricano, selvatico, autentico.")
                        .font(.caption).foregroundStyle(.white.opacity(0.6))
                        .lineSpacing(4)
                }
            }
            .padding(16)
            .background(Color.yellow.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.yellow.opacity(0.3), lineWidth: 1))
        }
    }

    // MARK: - Helpers
    func statBadge(icon: String, value: String, label: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).foregroundStyle(color)
            Text(value).font(.subheadline.bold()).foregroundStyle(.white)
            if !label.isEmpty {
                Text(label).font(.caption).foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }

    func infoCard(icon: String, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(icon) \(title)").font(.caption.bold()).foregroundStyle(.white.opacity(0.5))
            Text(value).font(.subheadline).foregroundStyle(.white).lineLimit(3)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
    
}
