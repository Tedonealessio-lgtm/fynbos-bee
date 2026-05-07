import SwiftUI
import Combine

struct ZoneSceneView: View {
    let zone: Zone
    let hives: [Hive]

    // Api volanti
    @State private var bees: [BeeParticle] = []
    @State private var windPhase: Double = 0
    @State private var time: Double = 0

    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Sfondo paesaggio
                Image(zone.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .overlay(Color.black.opacity(0.25))

                // Erba / piante con vento
                windyPlants(geo: geo)

                // Fiori
                flowers(geo: geo)

                // Alveari
                hivesScene(geo: geo)

                // Api volanti
                ForEach(bees) { bee in
                    beeView(bee: bee, geo: geo)
                }

                // Overlay info in basso
                VStack {
                    Spacer()
                    bottomInfo
                }
            }
        }
        .onReceive(timer) { _ in
            time += 0.05
            windPhase = sin(time * 0.8) * 5
            updateBees()
        }
        .onAppear {
            spawnBees()
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(radius: 12)
    }

    // MARK: - Piante con vento
    func windyPlants(geo: GeometryProxy) -> some View {
        ZStack {
            ForEach(0..<12, id: \.self) { i in
                let x = geo.size.width * CGFloat(i) / 12 + 15
                let h = CGFloat.random(in: 30...60)
                Capsule()
                    .fill(Color.green.opacity(0.6))
                    .frame(width: 3, height: h)
                    .offset(x: x, y: geo.size.height * 0.72)
                    .rotationEffect(
                        .degrees(Double(windPhase) * (i % 2 == 0 ? 1 : -1)),
                        anchor: .bottom
                    )
            }
        }
    }

    // MARK: - Fiori
    func flowers(geo: GeometryProxy) -> some View {
        ZStack {
            ForEach(0..<8, id: \.self) { i in
                let x = geo.size.width * CGFloat(i + 1) / 9
                let y = geo.size.height * 0.68 + CGFloat(i % 3) * 8

                ZStack {
                    ForEach(0..<6, id: \.self) { petal in
                        Circle()
                            .fill(flowerColor(for: zone).opacity(0.9))
                            .frame(width: 8, height: 8)
                            .offset(
                                x: cos(Double(petal) * .pi / 3) * 7,
                                y: sin(Double(petal) * .pi / 3) * 7
                            )
                    }
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 6, height: 6)
                }
                .position(x: x, y: y)
            }
        }
    }

    func flowerColor(for zone: Zone) -> Color {
        switch zone.name {
        case "Protea": return .orange
        case "Erica irregularis": return .pink
        default: return .purple
        }
    }

    // MARK: - Alveari nella scena
    func hivesScene(geo: GeometryProxy) -> some View {
        let hivesInZone = hives.filter { $0.zoneID == zone.id }
        return ZStack {
            ForEach(Array(hivesInZone.enumerated()), id: \.element.id) { index, hive in
                let x = geo.size.width * (index % 2 == 0 ? 0.25 : 0.70)
                let y = geo.size.height * 0.62

                ZStack {
                    // Corpo alveare
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.72, green: 0.50, blue: 0.25),
                                    Color(red: 0.45, green: 0.28, blue: 0.12)
                                ],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .frame(width: 52, height: 38)

                    // Strisce alveare
                    VStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { _ in
                            Rectangle()
                                .fill(Color.black.opacity(0.2))
                                .frame(width: 52, height: 2)
                        }
                    }

                    // Entrata alveare
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.black.opacity(0.7))
                        .frame(width: 16, height: 6)
                        .offset(y: 14)

                    // Nome
                    Text(hive.name)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                        .offset(y: -28)
                        .shadow(radius: 2)
                }
                .position(x: x, y: y)
            }
        }
    }

    // MARK: - Api
    func beeView(bee: BeeParticle, geo: GeometryProxy) -> some View {
        ZStack {
            // Corpo
            Capsule()
                .fill(Color.yellow)
                .frame(width: 10, height: 6)
            // Strisce
            Capsule()
                .fill(Color.black.opacity(0.7))
                .frame(width: 2, height: 6)
                .offset(x: -2)
            Capsule()
                .fill(Color.black.opacity(0.7))
                .frame(width: 2, height: 6)
                .offset(x: 2)
            // Ali
            Ellipse()
                .fill(Color.white.opacity(0.75))
                .frame(width: 7, height: 4)
                .offset(x: -3, y: -4)
                .rotationEffect(.degrees(bee.wingAngle))
            Ellipse()
                .fill(Color.white.opacity(0.75))
                .frame(width: 7, height: 4)
                .offset(x: 3, y: -4)
                .rotationEffect(.degrees(-bee.wingAngle))
        }
        .scaleEffect(bee.scale)
        .position(x: bee.x * geo.size.width, y: bee.y * geo.size.height)
        .opacity(bee.opacity)
    }

    // MARK: - Info in basso
    var bottomInfo: some View {
        HStack(spacing: 16) {
            let hivesInZone = hives.filter { $0.zoneID == zone.id }
            let totalBees = hivesInZone.reduce(0) { $0 + $1.bees }
            let totalProduction = hivesInZone.reduce(0.0) { $0 + zone.yieldPerTick * Double($1.bees) / 100 }

            Label("\(hivesInZone.count) alveari", systemImage: "shippingbox.fill")
            Label("\(totalBees) api", systemImage: "ant.fill")
            Label(String(format: "%.1f kg/tick", totalProduction), systemImage: "drop.fill")
        }
        .font(.caption.bold())
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .padding(.bottom, 16)
    }

    // MARK: - Logica Api
    func spawnBees() {
        let count = min(hives.filter { $0.zoneID == zone.id }.count * 6 + 3, 15)
        bees = (0..<count).map { _ in BeeParticle.random() }
    }

    func updateBees() {
        for i in bees.indices {
            bees[i].x += bees[i].vx
            bees[i].y += bees[i].vy

            // Rimbalza sui bordi
            if bees[i].x < 0.05 || bees[i].x > 0.95 { bees[i].vx *= -1 }
            if bees[i].y < 0.05 || bees[i].y > 0.85 { bees[i].vy *= -1 }

            // Vira leggermente in modo random
            bees[i].vx += Double.random(in: -0.002...0.002)
            bees[i].vy += Double.random(in: -0.002...0.002)

            // Limita velocità
            bees[i].vx = max(-0.008, min(0.008, bees[i].vx))
            bees[i].vy = max(-0.008, min(0.008, bees[i].vy))

            // Ali che battono
            bees[i].wingAngle = sin(time * 20 + Double(i)) * 30
        }
    }
}

// MARK: - Modello Ape
struct BeeParticle: Identifiable {
    let id = UUID()
    var x: Double
    var y: Double
    var vx: Double
    var vy: Double
    var scale: Double
    var opacity: Double
    var wingAngle: Double = 0

    static func random() -> BeeParticle {
        BeeParticle(
            x: Double.random(in: 0.1...0.9),
            y: Double.random(in: 0.1...0.8),
            vx: Double.random(in: -0.006...0.006),
            vy: Double.random(in: -0.004...0.004),
            scale: Double.random(in: 0.7...1.2),
            opacity: Double.random(in: 0.7...1.0)
        )
    }
}
