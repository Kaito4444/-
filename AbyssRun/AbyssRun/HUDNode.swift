import SpriteKit

// MARK: - HUD + Controls overlay (attached to cameraNode)
final class HUDNode: SKNode {

    // Labels
    private let timerLabel  = SKLabelNode()
    private let deathLabel  = SKLabelNode()
    private let msgLabel    = SKLabelNode()

    // Control button nodes (in camera space)
    private(set) var btnLeft:  SKShapeNode!
    private(set) var btnRight: SKShapeNode!
    private(set) var btnJump:  SKShapeNode!

    // Touch → button mapping for multi-touch
    var touchMap: [UITouch: String] = [:]
    var holdLeft  = false
    var holdRight = false
    var holdJump  = false

    override init() {
        super.init()
        buildHUD()
        buildControls()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Build HUD bar (top)
    private func buildHUD() {
        let barW = kSceneW
        let barH: CGFloat = 36
        let bar = SKSpriteNode(color: .abyssHUDBg,
                               size: CGSize(width: barW, height: barH))
        bar.position = CGPoint(x: 0, y: kSceneH / 2 - barH / 2)
        bar.zPosition = 50
        addChild(bar)

        // Timer
        styleLabel(timerLabel)
        timerLabel.position = CGPoint(x: 0, y: kSceneH / 2 - 26)
        timerLabel.zPosition = 51
        addChild(timerLabel)

        // Death count (right)
        styleLabel(deathLabel)
        deathLabel.horizontalAlignmentMode = .right
        deathLabel.position = CGPoint(x: kSceneW / 2 - 16, y: kSceneH / 2 - 26)
        deathLabel.zPosition = 51
        addChild(deathLabel)

        // Message (center)
        msgLabel.fontName = "AvenirNext-Bold"
        msgLabel.fontSize = 32
        msgLabel.fontColor = .abyssDanger
        msgLabel.zPosition = 60
        msgLabel.position = CGPoint(x: 0, y: 30)
        msgLabel.alpha = 0
        addChild(msgLabel)
    }

    private func styleLabel(_ lbl: SKLabelNode) {
        lbl.fontName = "Courier-Bold"
        lbl.fontSize = 16
        lbl.fontColor = .abyssHUDText
        lbl.horizontalAlignmentMode = .center
        lbl.verticalAlignmentMode   = .baseline
    }

    // MARK: - Build virtual buttons (bottom)
    private func buildControls() {
        let bY: CGFloat = -kSceneH / 2 + 48  // bottom of screen
        let bSize: CGFloat = 68

        btnLeft  = makeButton("◀", x: -kSceneW / 2 + 52,  y: bY, size: bSize)
        btnRight = makeButton("▶", x: -kSceneW / 2 + 130, y: bY, size: bSize)
        btnJump  = makeButton("JUMP", x: kSceneW / 2 - 62, y: bY, size: 90, round: true)
    }

    @discardableResult
    private func makeButton(_ label: String, x: CGFloat, y: CGFloat,
                             size: CGFloat, round: Bool = false) -> SKShapeNode {
        let shape: SKShapeNode
        if round {
            shape = SKShapeNode(circleOfRadius: size / 2)
        } else {
            shape = SKShapeNode(rectOf: CGSize(width: size, height: size), cornerRadius: 10)
        }
        shape.fillColor   = .abyssBtn
        shape.strokeColor = .abyssBtnBorder
        shape.lineWidth   = 2
        shape.position    = CGPoint(x: x, y: y)
        shape.zPosition   = 50

        let lbl = SKLabelNode(text: label)
        lbl.fontName = round ? "AvenirNext-Bold" : "Courier-Bold"
        lbl.fontSize = round ? 16 : 22
        lbl.fontColor = .white
        lbl.verticalAlignmentMode = .center
        shape.addChild(lbl)
        addChild(shape)
        return shape
    }

    // MARK: - Touch handling
    func touchDown(_ touch: UITouch) {
        let pt = touch.location(in: self)
        if btnLeft.contains(pt)  { touchMap[touch] = "L"; holdLeft  = true }
        if btnRight.contains(pt) { touchMap[touch] = "R"; holdRight = true }
        if btnJump.contains(pt)  { touchMap[touch] = "J"; holdJump  = true }
    }

    func touchUp(_ touch: UITouch) {
        switch touchMap[touch] {
        case "L": holdLeft  = false
        case "R": holdRight = false
        case "J": holdJump  = false
        default: break
        }
        touchMap.removeValue(forKey: touch)
    }

    // MARK: - Update displays
    func update(timeLeft: Double, deaths: Int) {
        let t = max(0, Int(ceil(timeLeft)))
        timerLabel.text = String(format: "TIME  %02d", t)
        timerLabel.fontColor = t < 15 ? .abyssDanger : .abyssHUDText

        deathLabel.text = "DEATH:\(deaths)"
    }

    // MARK: - Flash message
    func showMessage(_ text: String, color: UIColor = .abyssDanger, duration: Double = 1.2) {
        msgLabel.text = text
        msgLabel.fontColor = color
        msgLabel.removeAllActions()
        msgLabel.alpha = 1
        msgLabel.run(SKAction.sequence([
            SKAction.wait(forDuration: duration),
            SKAction.fadeOut(withDuration: 0.3),
        ]))
    }
}
