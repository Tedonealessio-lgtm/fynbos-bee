import SwiftUI
import SpriteKit

// MARK: - SpriteKit Scene
class HiveScene: SKScene {

    var hive: Hive
    var zone: Zone
    var beeCount: Int

    private var bees: [SKNode] = []
    private var honeycombNodes: [SKNode] = []
    private var time: Double = 0
    private var ambientLight: SKLightNode?

    init(hive: Hive, zone: Zone, size: CGSize) {
        self.hive = hive
        self.zone = zone
        self.beeCount = min(hive.bees / 10, 20)
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not supported")
    }

    override func didMove(to view: SKView) {
        setupScene()
        spawnBees()
    }

    // MARK: - Setup
    func setupScene() {
        backgroundColor = SKColor(red: 0.15, green: 0.10, blue: 0.05, alpha: 1.0)

        // Luce ambientale dorata
        let light = SKLightNode()
        light.categoryBitMask = 1
        light.falloff = 1
        light.ambientColor = SKColor(red: 0.8, green: 0.6, blue: 0.2, alpha: 0.8)
        light.lightColor = SKColor(red: 1.0, green: 0.8, blue: 0.3, alpha: 1.0)
        light.position = CGPoint(x: size.width / 2, y: size.height * 0.7)
        addChild(light)
        ambientLight = light

        // Favo di sfondo
        drawHoneycomb()

        // Miele che cola
        addDrippingHoney()

        // Particelle polline
        addPollenParticles()
    }

    // MARK: - Favo
    func drawHoneycomb() {
        let cols = 8
        let rows = 6
        let hexSize: CGFloat = 28
        let hexWidth = hexSize * 2
        let hexHeight = hexSize * sqrt(3)

        for row in 0..<rows {
            for col in 0..<cols {
                let xOffset = col % 2 == 0 ? 0 : hexHeight / 2
                let x = CGFloat(col) * hexHeight * 0.87 + 20
                let y = CGFloat(row) * hexWidth * 0.75 + xOffset + 20

                let hex = makeHexagon(size: hexSize)
                hex.position = CGPoint(x: x, y: y)

                // Colore casuale tra miele e vuoto
                let isFilled = Double.random(in: 0...1) > 0.3
                if isFilled {
                    let honeyColors: [SKColor] = [
                        SKColor(red: 0.9, green: 0.6, blue: 0.1, alpha: 0.9),
                        SKColor(red: 0.8, green: 0.5, blue: 0.05, alpha: 0.9),
                        SKColor(red: 0.95, green: 0.7, blue: 0.15, alpha: 0.9)
                    ]
                    hex.fillColor = honeyColors.randomElement()!
                } else {
                    hex.fillColor = SKColor(red: 0.25, green: 0.18, blue: 0.08, alpha: 0.9)
                }

                hex.strokeColor = SKColor(red: 0.6, green: 0.4, blue: 0.1, alpha: 1.0)
                hex.lineWidth = 1.5
                addChild(hex)
                honeycombNodes.append(hex)
            }
        }
    }

    func makeHexagon(size: CGFloat) -> SKShapeNode {
        var points = [CGPoint]()
        for i in 0..<6 {
            let angle = CGFloat(i) * .pi / 3
            points.append(CGPoint(
                x: size * cos(angle),
                y: size * sin(angle)
            ))
        }
        points.append(points[0])
        let path = CGMutablePath()
        path.addLines(between: points)
        path.closeSubpath()
        return SKShapeNode(path: path)
    }

    // MARK: - Api
    func spawnBees() {
        for i in 0..<beeCount {
            let bee = makeBee()
            let x = CGFloat.random(in: 30...size.width - 30)
            let y = CGFloat.random(in: 50...size.height - 50)
            bee.position = CGPoint(x: x, y: y)
            addChild(bee)
            bees.append(bee)

            // Volo casuale
            animateBee(bee, index: i)
        }
    }

    func makeBee() -> SKNode {
        let beeNode = SKNode()

        // Corpo
        let body = SKShapeNode(ellipseOf: CGSize(width: 14, height: 9))
        body.fillColor = SKColor(red: 0.95, green: 0.85, blue: 0.1, alpha: 1.0)
        body.strokeColor = .black
        body.lineWidth = 0.8
        beeNode.addChild(body)

        // Strisce nere
        for j in 0..<2 {
            let stripe = SKShapeNode(rect: CGRect(x: -2 + CGFloat(j) * 4, y: -4, width: 2, height: 8))
            stripe.fillColor = SKColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.8)
            stripe.strokeColor = .clear
            beeNode.addChild(stripe)
        }

        // Ali
        let wing1 = SKShapeNode(ellipseOf: CGSize(width: 10, height: 6))
        wing1.fillColor = SKColor(white: 1.0, alpha: 0.6)
        wing1.strokeColor = SKColor(white: 0.8, alpha: 0.5)
        wing1.position = CGPoint(x: -2, y: 7)
        wing1.zRotation = 0.3
        beeNode.addChild(wing1)

        let wing2 = SKShapeNode(ellipseOf: CGSize(width: 10, height: 6))
        wing2.fillColor = SKColor(white: 1.0, alpha: 0.6)
        wing2.strokeColor = SKColor(white: 0.8, alpha: 0.5)
        wing2.position = CGPoint(x: 2, y: 7)
        wing2.zRotation = -0.3
        beeNode.addChild(wing2)

        return beeNode
    }

    func animateBee(_ bee: SKNode, index: Int) {
        let duration = Double.random(in: 2.0...5.0)
        let targetX = CGFloat.random(in: 30...size.width - 30)
        let targetY = CGFloat.random(in: 50...size.height - 50)

        let move = SKAction.move(to: CGPoint(x: targetX, y: targetY), duration: duration)
        move.timingMode = .easeInEaseOut

        // Oscillazione ali
        let wingFlap = SKAction.sequence([
            SKAction.scaleY(to: 1.2, duration: 0.1),
            SKAction.scaleY(to: 0.8, duration: 0.1)
        ])
        let flapForever = SKAction.repeatForever(wingFlap)

        let moveAndRepeat = SKAction.sequence([
            move,
            SKAction.run { [weak self] in
                self?.animateBee(bee, index: index)
            }
        ])

        bee.run(SKAction.group([moveAndRepeat, flapForever]))
    }

    // MARK: - Miele che cola
    func addDrippingHoney() {
        for _ in 0..<5 {
            let x = CGFloat.random(in: 50...size.width - 50)
            let drip = SKShapeNode(rectOf: CGSize(width: 4, height: 20), cornerRadius: 2)
            drip.fillColor = SKColor(red: 0.9, green: 0.6, blue: 0.05, alpha: 0.8)
            drip.strokeColor = .clear
            drip.position = CGPoint(x: x, y: size.height - 10)

            addChild(drip)

            let fall = SKAction.moveBy(x: 0, y: -size.height, duration: Double.random(in: 3...6))
            let fade = SKAction.fadeOut(withDuration: 0.5)
            let reset = SKAction.run {
                drip.position = CGPoint(x: CGFloat.random(in: 50...self.size.width - 50),
                                        y: self.size.height - 10)
                drip.alpha = 0.8
            }
            let seq = SKAction.sequence([fall, fade, reset])
            drip.run(SKAction.repeatForever(seq))
        }
    }

    // MARK: - Particelle polline
    func addPollenParticles() {
        for _ in 0..<15 {
            let pollen = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...4))
            pollen.fillColor = SKColor(red: 0.95, green: 0.85, blue: 0.2, alpha: 0.7)
            pollen.strokeColor = .clear
            pollen.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height)
            )
            addChild(pollen)

            let float = SKAction.sequence([
                SKAction.moveBy(x: CGFloat.random(in: -20...20),
                               y: CGFloat.random(in: -20...20),
                               duration: Double.random(in: 2...4)),
                SKAction.moveBy(x: CGFloat.random(in: -20...20),
                               y: CGFloat.random(in: -20...20),
                               duration: Double.random(in: 2...4))
            ])
            pollen.run(SKAction.repeatForever(float))
        }
    }

    // MARK: - Regina
    func addQueenBee() {
        let queen = makeBee()
        queen.setScale(1.8)
        queen.position = CGPoint(x: size.width / 2, y: size.height / 2)

        // Corona
        let crown = SKLabelNode(text: "👑")
        crown.fontSize = 16
        crown.position = CGPoint(x: 0, y: 14)
        queen.addChild(crown)

        addChild(queen)

        // Movimento circolare regine
        let radius: CGFloat = 40
        let circle = SKAction.customAction(withDuration: 4.0) { node, elapsed in
            let angle = elapsed / 4.0 * .pi * 2
            node.position = CGPoint(
                x: self.size.width / 2 + radius * cos(angle),
                y: self.size.height / 2 + radius * sin(angle)
            )
        }
        queen.run(SKAction.repeatForever(circle))
    }

    override func update(_ currentTime: TimeInterval) {
        time += 0.016
        // Luce pulsante
        ambientLight?.ambientColor = SKColor(
            red: 0.7 + 0.1 * sin(time * 0.5),
            green: 0.5 + 0.05 * sin(time * 0.5),
            blue: 0.15,
            alpha: 0.8
        )
    }
}

// MARK: - SwiftUI View
struct HiveInteriorView: View {
    let hive: Hive
    let zone: Zone
    var onClose: () -> Void

    var scene: HiveScene {
        let s = HiveScene(hive: hive, zone: zone,
                         size: CGSize(width: 390, height: 500))
        s.scaleMode = .aspectFill
        return s
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color(red: 0.10, green: 0.07, blue: 0.03)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("🏠 \(hive.name)")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        Text("Interno alveare — \(zone.name)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .padding()

                // SpriteKit Scene
                SpriteView(scene: scene, options: [.allowsTransparency])
                    .frame(height: 380)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .padding(.horizontal)

                // Info alveare
                VStack(spacing: 12) {
                    HStack(spacing: 20) {
                        infoItem(icon: "🐝", value: "\(hive.bees)", label: "Api")
                        infoItem(icon: hive.queen.statusEmoji, value: "\(hive.queen.age)g", label: "Regina")
                        infoItem(icon: "🍯", value: String(format: "%.1f", zone.yieldPerTick * Double(hive.bees) / 100), label: "kg/tick")
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding()

                Spacer()
            }
        }
        .onAppear {
            scene.addQueenBee()
        }
    }

    func infoItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(icon).font(.title2)
            Text(value).font(.headline.bold()).foregroundStyle(.white)
            Text(label).font(.caption2).foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
}
