import SpriteKit

// MARK: - Block Types
enum BlockType {
    case ground      // solid, static, never moves
    case stone       // solid, static (ceiling/wall blocks)
    case crumble     // solid → falls after player stands ~1.5 s
    case vanish      // cycles visible ↔ invisible on timer
    case spike       // instant-kill hazard
    case movingH     // moving platform, horizontal
    case movingV     // moving platform, vertical
    case goal        // reach = stage clear
}

// MARK: - Crumble State
enum CrumbleState { case solid, crumbling, gone }

// MARK: - Block Node Factory
final class BlockNode: SKSpriteNode {

    var blockType: BlockType = .ground

    // ── Crumble ──
    var crumbleState: CrumbleState = .solid
    var crumbleTimer: Double = 0

    // ── Vanish ──
    var vanishTimer: Double = 0
    var vanishVisible: Bool = true
    static let vanishOnTime:  Double = 1.5
    static let vanishOffTime: Double = 1.0
    static let vanishWarnAt:  Double = 0.3  // blink starts n seconds before hiding

    // ── Moving platform ──
    var movMin: CGFloat = 0
    var movMax: CGFloat = 0
    var movSpeed: CGFloat = 60
    var movGoingPos: Bool = true   // positive direction
    var movAxis: Int = 0           // 0=horizontal, 1=vertical

    // MARK: - Factory
    @discardableResult
    static func make(type: BlockType, col: Int, row: Int,
                     width: Int = 1,
                     in world: SKNode) -> BlockNode {
        let node = BlockNode(texture: texture(for: type, width: width),
                             color: .clear,
                             size: CGSize(width: CGFloat(width) * kTile,
                                         height: kTile))
        node.blockType = type
        node.zPosition = 5
        // Position: col/row in tile coordinates, origin bottom-left of tile
        let cx = CGFloat(col) * kTile + node.size.width  / 2
        let cy = CGFloat(row) * kTile + kTile / 2
        node.position = CGPoint(x: cx, y: cy)

        switch type {
        case .ground, .stone:
            node.name = "solid"
            attachSolidBody(node)

        case .crumble:
            node.name = "crumble"
            attachSolidBody(node)          // starts solid

        case .vanish:
            node.name = "vanish"
            attachMovPlatBody(node)        // uses movPlat category

        case .spike:
            node.name = "spike"
            let body = SKPhysicsBody(rectangleOf: node.size)
            body.isDynamic = false
            body.categoryBitMask    = PC.hazard
            body.contactTestBitMask = PC.player
            body.collisionBitMask   = 0
            node.physicsBody = body

        case .movingH, .movingV:
            node.name = "movPlat"
            attachMovPlatBody(node)
            node.movAxis = (type == .movingH) ? 0 : 1

        case .goal:
            node.name = "goal"
            let body = SKPhysicsBody(rectangleOf: node.size)
            body.isDynamic = false
            body.categoryBitMask    = PC.goal
            body.contactTestBitMask = PC.player
            body.collisionBitMask   = 0
            node.physicsBody = body
        }

        world.addChild(node)
        return node
    }

    // MARK: - Solid physics body
    private static func attachSolidBody(_ node: BlockNode) {
        let body = SKPhysicsBody(rectangleOf: node.size)
        body.isDynamic = false
        body.categoryBitMask    = PC.solid
        body.contactTestBitMask = PC.player
        body.collisionBitMask   = PC.player | PC.enemy
        body.friction = 0.5
        node.physicsBody = body
    }

    private static func attachMovPlatBody(_ node: BlockNode) {
        let body = SKPhysicsBody(rectangleOf: node.size)
        body.isDynamic = false
        body.categoryBitMask    = PC.movPlat
        body.contactTestBitMask = PC.player
        body.collisionBitMask   = PC.player
        body.friction = 0.0   // slippery — extra difficulty
        node.physicsBody = body
    }

    // MARK: - Texture factory
    private static func texture(for type: BlockType, width: Int) -> SKTexture {
        switch type {
        case .ground:   return Tex.blockGround
        case .stone:    return Tex.blockStone
        case .crumble:  return Tex.blockCrumble
        case .vanish:   return Tex.blockVanish
        case .spike:    return Tex.spikeUnit
        case .movingH, .movingV: return Tex.platMoving
        case .goal:
            // Gold block with glow border
            let size = CGSize(width: kTile, height: kTile * 2)
            let renderer = UIGraphicsImageRenderer(size: size)
            let img = renderer.image { ctx in
                let g = ctx.cgContext
                g.setFillColor(UIColor.abyssGoal.cgColor)
                g.fill(CGRect(origin: .zero, size: size))
                g.setFillColor(UIColor.abyssGoalGlow.cgColor)
                g.fill(CGRect(x: 2, y: 2, width: size.width-4, height: 4))
                g.fill(CGRect(x: 2, y: size.height-6, width: size.width-4, height: 4))
            }
            return SKTexture(image: img)
        }
    }

    // MARK: - Per-frame updates
    func updateCrumble(playerOnTop: Bool, dt: Double) -> Bool {
        // returns true if this block just disappeared
        guard crumbleState != .gone else { return false }
        if playerOnTop {
            crumbleTimer += dt
        }
        switch crumbleState {
        case .solid:
            if crumbleTimer > 0.9 {
                crumbleState = .crumbling
                startShake()
            }
        case .crumbling:
            if crumbleTimer > 1.6 {
                crumbleState = .gone
                physicsBody = nil
                run(SKAction.sequence([
                    SKAction.fadeOut(withDuration: 0.12),
                    SKAction.removeFromParent(),
                ]))
                return true
            }
        case .gone: break
        }
        return false
    }

    func updateVanish(dt: Double) {
        vanishTimer += dt
        if vanishVisible {
            let remain = BlockNode.vanishOnTime - vanishTimer
            if remain < BlockNode.vanishWarnAt {
                // Blink warning
                alpha = (vanishTimer * 8).truncatingRemainder(dividingBy: 1) > 0.5 ? 0.3 : 1.0
            }
            if vanishTimer >= BlockNode.vanishOnTime {
                vanishVisible = false
                vanishTimer = 0
                alpha = 0
                physicsBody = nil
            }
        } else {
            if vanishTimer >= BlockNode.vanishOffTime {
                vanishVisible = true
                vanishTimer = 0
                alpha = 1
                BlockNode.attachMovPlatBody(self)
            }
        }
    }

    func updateMoving(dt: Double) {
        let step = movSpeed * CGFloat(dt) * (movGoingPos ? 1 : -1)
        if movAxis == 0 {
            position.x += step
            if position.x > movMax { movGoingPos = false }
            if position.x < movMin { movGoingPos = true  }
        } else {
            position.y += step
            if position.y > movMax { movGoingPos = false }
            if position.y < movMin { movGoingPos = true  }
        }
    }

    private func startShake() {
        let shake = SKAction.repeatForever(SKAction.sequence([
            SKAction.moveBy(x: -2, y: 0, duration: 0.05),
            SKAction.moveBy(x:  4, y: 0, duration: 0.05),
            SKAction.moveBy(x: -2, y: 0, duration: 0.05),
        ]))
        run(shake, withKey: "shake")
    }
}
