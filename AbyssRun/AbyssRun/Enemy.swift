import SpriteKit

// MARK: - Enemy Node
final class Enemy: SKSpriteNode {

    var patrolMinX: CGFloat = 0
    var patrolMaxX: CGFloat = 0
    var moveSpeed: CGFloat  = 80
    var moveRight           = false

    private var frameTime: Double = 0
    private let frames = [Tex.enemyA, Tex.enemyB]
    private var frameIdx = 0

    static func make(at pos: CGPoint,
                     patrolLeft: CGFloat,
                     patrolRight: CGFloat,
                     speed: CGFloat = 80) -> Enemy {
        let e = Enemy(texture: Tex.enemyA,
                      color: .clear,
                      size: CGSize(width: 24, height: 30))
        e.position = pos
        e.name = "enemy"
        e.zPosition = 9
        e.patrolMinX = patrolLeft
        e.patrolMaxX = patrolRight
        e.moveSpeed = speed
        e.moveRight = Bool.random()

        let body = SKPhysicsBody(rectangleOf: CGSize(width: 20, height: 26))
        body.mass = 0.5
        body.allowsRotation  = false
        body.isDynamic       = true
        body.categoryBitMask    = PC.enemy
        body.contactTestBitMask = PC.player
        body.collisionBitMask   = PC.solid   // walk on ground, not pushed by player
        body.linearDamping  = 0
        body.restitution    = 0
        body.friction       = 0.3
        e.physicsBody = body
        return e
    }

    // MARK: - AI Update (called from GameScene.update)
    func updateAI(dt: Double) {
        guard let pb = physicsBody else { return }

        // Patrol back and forth
        if moveRight {
            pb.velocity.dx = moveSpeed
            xScale = 1
            if position.x >= patrolMaxX { moveRight = false }
        } else {
            pb.velocity.dx = -moveSpeed
            xScale = -1
            if position.x <= patrolMinX { moveRight = true }
        }

        // Walk animation
        frameTime += dt
        if frameTime > 0.18 {
            frameTime = 0
            frameIdx = (frameIdx + 1) % frames.count
            texture = frames[frameIdx]
        }
    }

    // MARK: - Stomp check
    // Returns true if player is hitting from above (stomp)
    func isStomp(playerBottom: CGFloat, playerVelY: CGFloat) -> Bool {
        let enemyTop = position.y + size.height * 0.3
        return playerBottom >= enemyTop - 6 && playerVelY <= 0
    }

    func die() {
        physicsBody = nil
        let squash = SKAction.sequence([
            SKAction.scaleY(to: 0.1, duration: 0.08),
            SKAction.wait(forDuration: 0.15),
            SKAction.fadeOut(withDuration: 0.10),
            SKAction.removeFromParent(),
        ])
        run(squash)
    }
}
