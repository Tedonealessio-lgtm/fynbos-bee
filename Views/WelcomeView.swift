import SwiftUI

struct WelcomeView: View {
    @State private var beeScale: CGFloat = 0.3
    @State private var beeOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var beeOffset: CGFloat = 30
    @State private var glowRadius: CGFloat = 10
    @State private var pollenOpacity: Double = 0

    var onStart: () -> Void

    var body: some View {
        ZStack {
            // Sfondo beige
            Color(red: 0.94, green: 0.93, blue: 0.86)
                .ignoresSafeArea()

            // Particelle polline sfondo
            pollenParticles

            VStack(spacing: 0) {
                Spacer()

                // APE MASCOT
                Image("bee_mascot")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 280, height: 280)
                    .scaleEffect(beeScale)
                    .opacity(beeOpacity)
                    .offset(y: beeOffset)
                    .shadow(color: .yellow.opacity(0.6), radius: glowRadius)

                Spacer().frame(height: 20)

                // TITOLO
                VStack(spacing: 8) {
                    Text("Fynbos Bee")
                        .font(.system(size: 42, weight: .bold, design: .serif))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, Color(red: 0.8, green: 0.5, blue: 0.0), .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .orange.opacity(0.3), radius: 4)

                    Text("Grootbos Nature Reserve")
                        .font(.system(size: 16, weight: .medium, design: .serif))
                        .foregroundStyle(.black.opacity(0.6))
                        .italic()

                    Text("🇿🇦 South Africa")
                        .font(.caption)
                        .foregroundStyle(.black.opacity(0.4))
                }
                .opacity(titleOpacity)

                Spacer().frame(height: 40)

                // DESCRIZIONE
                VStack(spacing: 12) {
                    descriptionRow(icon: "🐝", text: "Gestisci i tuoi alveari nel Fynbos")
                    descriptionRow(icon: "🌸", text: "Scopri la flora sudafricana")
                    descriptionRow(icon: "🍯", text: "Produci miele autentico di Grootbos")
                    descriptionRow(icon: "📚", text: "Impara il vero mestiere dell'apicoltore")
                }
                .opacity(titleOpacity)
                .padding(.horizontal, 40)

                Spacer().frame(height: 50)

                // BOTTONE START
                Button(action: onStart) {
                    HStack(spacing: 12) {
                        Text("🐝")
                            .font(.title2)
                        Text("Inizia l'avventura")
                            .font(.title3.bold())
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.8, green: 0.5, blue: 0.0), .orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: .orange.opacity(0.4), radius: 12, x: 0, y: 6)
                }
                .opacity(buttonOpacity)
                .scaleEffect(buttonOpacity == 1 ? 1 : 0.8)

                Spacer().frame(height: 20)

                Text("Un progetto nato a Grootbos 🌿")
                    .font(.caption2)
                    .foregroundStyle(.black.opacity(0.3))
                    .opacity(buttonOpacity)

                Spacer()
            }
        }
        .onAppear { startAnimations() }
    }

    // MARK: - Polline particelle
    var pollenParticles: some View {
        ZStack {
            ForEach(0..<20, id: \.self) { i in
                Circle()
                    .fill(Color.orange.opacity(Double.random(in: 0.1...0.25)))
                    .frame(
                        width: CGFloat.random(in: 3...10),
                        height: CGFloat.random(in: 3...10)
                    )
                    .position(
                        x: CGFloat.random(in: 0...400),
                        y: CGFloat.random(in: 0...900)
                    )
                    .opacity(pollenOpacity)
            }
        }
    }

    func descriptionRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Text(icon).font(.title3)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.black.opacity(0.7))
            Spacer()
        }
    }

    // MARK: - Animazioni
    func startAnimations() {
        withAnimation(.easeIn(duration: 1.0)) {
            pollenOpacity = 1
        }
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.3)) {
            beeScale = 1.0
            beeOpacity = 1
            beeOffset = 0
        }
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true).delay(1.0)) {
            glowRadius = 25
        }
        withAnimation(.easeOut(duration: 0.8).delay(0.8)) {
            titleOpacity = 1
        }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(1.3)) {
            buttonOpacity = 1
        }
    }
}
