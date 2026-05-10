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

    func setupScene() {
        backgroundColor = SKColor(red: 0.15, green: 0.10, blue: 0.05, alpha: 1.0)
        let light = SKLightNode()
        light.categoryBitMask = 1
        light.falloff = 1
        light.ambientColor = SKColor(red: 0.8, green: 0.6, blue: 0.2, alpha: 0.8)
        light.lightColor = SKColor(red: 1.0, green: 0.8, blue: 0.3, alpha: 1.0)
        light.position = CGPoint(x: size.width / 2, y: size.height * 0.7)
        addChild(light)
        ambientLight = light
        drawHoneycomb()
        addDrippingHoney()
        addPollenParticles()
    }

    func drawHoneycomb() {
        let cols = 8
        let rows = 6
        let hexSize: CGFloat = 28
        let hexHeight = hexSize * sqrt(3)
        for row in 0..<rows {
            for col in 0..<cols {
                let xOffset = col % 2 == 0 ? 0 : hexHeight / 2
                let x = CGFloat(col) * hexHeight * 0.87 + 20
                let y = CGFloat(row) * hexSize * 1.5 + xOffset + 20
                let hex = makeHexagon(size: hexSize)
                hex.position = CGPoint(x: x, y: y)
                hex.name = "honeycell_\(row)_\(col)"
                let isFilled = Double.random(in: 0...1) > 0.3
                if isFilled {
                    let honeyColors: [SKColor] = [
                        SKColor(red: 0.9, green: 0.6, blue: 0.1, alpha: 0.9),
                        SKColor(red: 0.8, green: 0.5, blue: 0.05, alpha: 0.9),
                        SKColor(red: 0.95, green: 0.7, blue: 0.15, alpha: 0.9)
                    ]
                    hex.fillColor = honeyColors.randomElement()!
                    hex.userData = NSMutableDictionary()
                    hex.userData?.setValue(true, forKey: "hasMoney")
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
            points.append(CGPoint(x: size * cos(angle), y: size * sin(angle)))
        }
        points.append(points[0])
        let path = CGMutablePath()
        path.addLines(between: points)
        path.closeSubpath()
        return SKShapeNode(path: path)
    }

    func spawnBees() {
        for i in 0..<beeCount {
            let bee = makeBee()
            let x = CGFloat.random(in: 30...size.width - 30)
            let y = CGFloat.random(in: 50...size.height - 50)
            bee.position = CGPoint(x: x, y: y)
            addChild(bee)
            bees.append(bee)
            animateBee(bee, index: i)
        }
    }

    func makeBee() -> SKNode {
        let beeNode = SKNode()
        let texture = SKTexture(imageNamed: "bee_sprite")
        let beeSprite = SKSpriteNode(texture: texture)
        beeSprite.size = CGSize(width: 55, height: 55)
        beeNode.addChild(beeSprite)
        return beeNode
    }

    func animateBee(_ bee: SKNode, index: Int) {
        let duration = Double.random(in: 2.0...5.0)
        let targetX = CGFloat.random(in: 30...size.width - 30)
        let targetY = CGFloat.random(in: 50...size.height - 50)
        let move = SKAction.move(to: CGPoint(x: targetX, y: targetY), duration: duration)
        move.timingMode = .easeInEaseOut
        let moveAndRepeat = SKAction.sequence([
            move,
            SKAction.run { [weak self] in self?.animateBee(bee, index: index) }
        ])
        let wobble = SKAction.sequence([
            SKAction.rotate(byAngle: 0.1, duration: 0.3),
            SKAction.rotate(byAngle: -0.1, duration: 0.3)
        ])
        bee.run(SKAction.group([moveAndRepeat, SKAction.repeatForever(wobble)]))
    }

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
                drip.position = CGPoint(x: CGFloat.random(in: 50...self.size.width - 50), y: self.size.height - 10)
                drip.alpha = 0.8
            }
            drip.run(SKAction.repeatForever(SKAction.sequence([fall, fade, reset])))
        }
    }

    func addPollenParticles() {
        for _ in 0..<15 {
            let pollen = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...4))
            pollen.fillColor = SKColor(red: 0.95, green: 0.85, blue: 0.2, alpha: 0.7)
            pollen.strokeColor = .clear
            pollen.position = CGPoint(x: CGFloat.random(in: 0...size.width), y: CGFloat.random(in: 0...size.height))
            addChild(pollen)
            let float = SKAction.sequence([
                SKAction.moveBy(x: CGFloat.random(in: -20...20), y: CGFloat.random(in: -20...20), duration: Double.random(in: 2...4)),
                SKAction.moveBy(x: CGFloat.random(in: -20...20), y: CGFloat.random(in: -20...20), duration: Double.random(in: 2...4))
            ])
            pollen.run(SKAction.repeatForever(float))
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodes = nodes(at: location)
        for node in nodes {
            if let name = node.name, name.hasPrefix("honeycell"),
               let hex = node as? SKShapeNode,
               let hasMoney = hex.userData?.value(forKey: "hasMoney") as? Bool,
               hasMoney {
                let pulse = SKAction.sequence([
                    SKAction.scale(to: 1.3, duration: 0.1),
                    SKAction.scale(to: 1.0, duration: 0.1)
                ])
                hex.run(pulse)
                hex.fillColor = SKColor(red: 0.25, green: 0.18, blue: 0.08, alpha: 0.9)
                hex.userData?.setValue(false, forKey: "hasMoney")
                showHoneyParticle(at: location)
                NotificationCenter.default.post(name: NSNotification.Name("HoneyCellTapped"), object: nil)
            }
        }
    }

    func showHoneyParticle(at position: CGPoint) {
        let label = SKLabelNode(text: "+🍯")
        label.fontSize = 20
        label.position = position
        addChild(label)
        let moveUp = SKAction.moveBy(x: 0, y: 60, duration: 0.8)
        let fade = SKAction.fadeOut(withDuration: 0.8)
        let remove = SKAction.removeFromParent()
        label.run(SKAction.sequence([SKAction.group([moveUp, fade]), remove]))
    }

    func addQueenBee() {
        let queenNode = SKNode()
        let texture = SKTexture(imageNamed: "bee_sprite")
        let queenSprite = SKSpriteNode(texture: texture)
        queenSprite.size = CGSize(width: 75, height: 75)
        queenNode.addChild(queenSprite)
        let crown = SKLabelNode(text: "👑")
        crown.fontSize = 20
        crown.position = CGPoint(x: 0, y: 38)
        queenNode.addChild(crown)
        let glow = SKShapeNode(circleOfRadius: 35)
        glow.fillColor = SKColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 0.15)
        glow.strokeColor = SKColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 0.4)
        glow.lineWidth = 2
        queenNode.addChild(glow)
        queenNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(queenNode)
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.15, duration: 0.8),
            SKAction.scale(to: 1.0, duration: 0.8)
        ])
        glow.run(SKAction.repeatForever(pulse))
        let radius: CGFloat = 35
        let circle = SKAction.customAction(withDuration: 5.0) { node, elapsed in
            let angle = elapsed / 5.0 * .pi * 2
            node.position = CGPoint(
                x: self.size.width / 2 + radius * cos(angle),
                y: self.size.height / 2 + radius * sin(angle)
            )
        }
        queenNode.run(SKAction.repeatForever(circle))
    }

    override func update(_ currentTime: TimeInterval) {
        time += 0.016
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

    @State private var scene: HiveScene = HiveScene(
        hive: Hive(name: "temp", zoneID: nil, bees: 10),
        zone: Zone(id: UUID(), name: "", imageName: "",
                   habitatDescription: "", yieldPerTick: 0,
                   isUnlocked: true, unlockCost: 0,
                   plantName: "", faunaNotes: "", honeyType: ""),
        size: CGSize(width: 390, height: 500)
    )

    var body: some View {
        ZStack(alignment: .top) {
            Color(red: 0.10, green: 0.07, blue: 0.03).ignoresSafeArea()
            VStack(spacing: 0) {
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

                SpriteView(scene: scene, options: [.allowsTransparency])
                    .frame(height: 380)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .padding(.horizontal)

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
            scene = HiveScene(hive: hive, zone: zone, size: CGSize(width: 390, height: 500))
            scene.scaleMode = .aspectFill
            scene.addQueenBee()
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("HoneyCellTapped"),
                object: nil,
                queue: .main
            ) { _ in
                AudioManager.shared.playHoneyCollect()
            }
        }
        .onDisappear {
            NotificationCenter.default.removeObserver(
                self,
                name: NSNotification.Name("HoneyCellTapped"),
                object: nil
            )
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
