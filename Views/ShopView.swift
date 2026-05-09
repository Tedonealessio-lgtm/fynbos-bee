import SwiftUI

struct ShopView: View {
    @ObservedObject var vm: GameViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color(red: 0.94, green: 0.93, blue: 0.86).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {

                    // Header
                    HStack {
                        VStack(alignment: .leading) {
                            Text("🛒 Shop Apicoltore")
                                .font(.title2.bold())
                            Text("Attrezzatura professionale")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        // Monete
                        HStack(spacing: 6) {
                            Image(systemName: "eurosign.circle.fill")
                                .foregroundStyle(.orange)
                            Text("\(vm.coins)")
                                .font(.title3.bold())
                        }
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                    // Stagione attuale
                    seasonCard

                    // Attrezzatura
                    Text("Attrezzatura")
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(vm.equipment) { item in
                        equipmentCard(item: item)
                    }

                    // Regina
                    Text("Api & Regine")
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)

                    queenCard

                    Button("Chiudi") { dismiss() }
                        .buttonStyle(.bordered)
                        .padding(.bottom)
                }
                .padding()
            }
        }
    }

    // MARK: - Stagione
    var seasonCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(vm.season.emoji) Stagione attuale")
                    .font(.headline)
                Spacer()
                Text(vm.season.rawValue)
                    .font(.subheadline.bold())
                    .foregroundStyle(.orange)
            }

            Text(vm.season.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack {
                Label("Produzione", systemImage: "drop.fill")
                    .font(.caption)
                Spacer()
                Text("\(Int(vm.season.productionMultiplier * 100))%")
                    .font(.caption.bold())
                    .foregroundStyle(vm.season.productionMultiplier >= 1 ? .green : .orange)
            }

            // Barra stagione
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(seasonColor)
                        .frame(width: geo.size.width * seasonProgress, height: 8)
                }
            }
            .frame(height: 8)

            Text("Giorno \(vm.day) — prossima stagione tra \(daysToNextSeason) giorni")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(seasonColor.opacity(0.5), lineWidth: 1.5)
        )
    }

    var seasonColor: Color {
        switch vm.season {
        case .spring: return .green
        case .summer: return .yellow
        case .autumn: return .orange
        case .winter: return .blue
        }
    }

    var seasonProgress: CGFloat {
        let cycle = vm.day % 600
        let seasonDay = cycle % 150
        return CGFloat(seasonDay) / 150.0
    }

    var daysToNextSeason: Int {
        let cycle = vm.day % 600
        let seasonDay = cycle % 150
        return 150 - seasonDay
    }

    // MARK: - Equipment Card
    func equipmentCard(item: Equipment) -> some View {
        HStack(spacing: 14) {
            Text(item.emoji)
                .font(.system(size: 36))
                .frame(width: 50, height: 50)
                .background(Color.orange.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.name).font(.headline)
                    Spacer()
                    if item.quantity > 0 {
                        Text("x\(item.quantity)")
                            .font(.caption.bold())
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color.green.opacity(0.2))
                            .foregroundStyle(.green)
                            .clipShape(Capsule())
                    }
                }
                Text(item.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                HStack {
                    Text("💰 \(item.cost) monete")
                        .font(.caption.bold())
                        .foregroundStyle(.orange)
                    Spacer()
                    Button("Acquista") {
                        vm.buyEquipment(item.type)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .disabled(vm.coins < item.cost)
                    .font(.caption.bold())
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Regina Card
    var queenCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("👑 Ape Regina")
                    .font(.headline)
                Spacer()
                Text("100 monete")
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
            }

            Text("Sostituisce la regina in un alveare malato o vecchio. Una nuova regina garantisce massima produzione.")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Lista alveari che necessitano regina
            ForEach(vm.hives.indices, id: \.self) { index in
                let hive = vm.hives[index]
                if hive.queen.status != .healthy {
                    HStack {
                        Text("\(hive.queen.statusEmoji) \(hive.name)")
                            .font(.subheadline)
                        Spacer()
                        Button("Sostituisci") {
                            vm.replaceQueen(hiveIndex: index)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .disabled(vm.coins < 100)
                        .font(.caption.bold())
                    }
                }
            }

            if vm.hives.allSatisfy({ $0.queen.status == .healthy }) {
                Text("✅ Tutte le regine sono in ottima salute!")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
