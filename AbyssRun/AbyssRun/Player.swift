import SpriteKit

// MARK: - Player Node
final class Player: SKSpriteNode {

    // Physics state
    var isOnGround   = false
    var jumpHeld: Double = 0      // seconds holding jump this press
    var prevJumpBtn  = false      // edge-detect jump
    var facingRight  = true

    // Platform riding
    var ridingPlatform: SKNode? = nil
    var platformPrevX:  CGFloat = 0
    var platformPrevY:  CGFloat = 0

    // Animation
    private var runFrameTime: Double = 0
    private var runFrame = 0
    private let runFrames = [Tex.playerIdle, Tex.playerRun]

    static func spawn(at pos: CGPoint) -> Player {
        let p = Player(texture: Tex.playerIdle,
                       color: .clear,
                       size: CGSize(width: 24, height: 36))
        p.position = pos
        p.name = "player"
        p.zPosition = 10

        // Slightly narrower hitbox for fairness
        let body = SKPhysicsBody(rectangleOf: CGSize(width: 18, height: 32))
        body.mass = 1.0
        body.allowsRotation = false
        body.categoryBitMask    = PC.player
        body.contactTestBitMask = PC.solid | PC.movPlat | PC.enemy | PC.hazard | PC.goal
        body.collisionBitMask   = PC.solid | PC.movPlat
        body.linearDamping  = 0.5   // slight drag (gives inertia feel)
        body.restitution    = 0
        body.friction       = 0.4
        p.physicsBody = body
        return p
    }

    // MARK: - Input drive (called from GameScene.update)
    func applyInput(left: Bool, right: Bool, jumpBtn: Bool, dt: Double) {
        guard let pb = physicsBody else { return }

        // Horizontal
        var targetVX: CGFloat = 0
        if left  { targetVX = -kWalkSpeed; facingRight = false }
        if right { targetVX =  kWalkSpeed; facingRight = true  }

        // Blend toward target (gives inertia: ~0.12s to full speed)
        let blend: CGFloat = isOnGround ? 0.22 : 0.12
        pb.velocity.dx += (targetVX - pb.velocity.dx) * blend

        // Flip sprite
        xScale = facingRight ? 1 : -1

        // --- Jump ---
        let jumpDown = jumpBtn && !prevJumpBtn  // rising edge
        prevJumpBtn = jumpBtn

        if jumpDown && isOnGround {
            pb.velocity.dy = kJumpVel
            isOnGround = false
            jumpHeld = dt
        } else if jumpBtn && jumpHeld > 0 && jumpHeld < kMaxJumpHold {
            // Variable height: extra force while held
            pb.applyForce(CGVector(dx: 0, dy: kJumpExtra * pb.mass))
            jumpHeld += dt
        } else if !jumpBtn {
            jumpHeld = 0
        } else {
            jumpHeld += dt
        }

        // Cap fall speed
        if pb.velocity.dy < kMaxFall { pb.velocity.dy = kMaxFall }

        // --- Animation ---
        if isOnGround && (left || right) {
            runFrameTime += dt
            if runFrameTime > 0.12 {
                runFrameTime = 0
                runFrame = (runFrame + 1) % runFrames.count
                texture = runFrames[runFrame]
            }
        } else {
            texture = Tex.playerIdle
            runFrameTime = 0
        }
    }

    // MARK: - Platform riding correction
    func applyPlatformRide() {
        guard let plat = ridingPlatform else { return }
        let dx = plat.position.x - platformPrevX
        let dy = plat.position.y - platformPrevY
        position.x += dx
        position.y += dy
        platformPrevX = plat.position.x
        platformPrevY = plat.position.y
    }

    func startRiding(_ plat: SKNode) {
        ridingPlatform = plat
        platformPrevX  = plat.position.x
        platformPrevY  = plat.position.y
    }

    func stopRiding() {
        ridingPlatform = nil
    }
}
