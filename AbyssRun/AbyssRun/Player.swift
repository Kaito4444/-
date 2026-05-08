import SpriteKit

// MARK: - Player Node
final class Player: SKSpriteNode {

    // Ground state (set by GameScene contact callbacks)
    var isOnGround   = false
    var wasOnGround  = false   // previous frame, for coyote time

    // Jump feel
    var jumpHeld: Double     = 0
    var jumpBuffer: Double   = 0   // 入力バッファ: 空中でボタンを押しても着地後に発動
    var coyoteTime: Double   = 0   // コヨーテタイム: 崖から落ちた直後も数フレームジャンプ可

    var prevJumpBtn  = false
    var facingRight  = true

    // Platform riding
    var ridingPlatform: SKNode? = nil
    var platformPrevX: CGFloat  = 0
    var platformPrevY: CGFloat  = 0

    // Animation
    private var runFrameTime: Double = 0
    private var runFrame = 0
    private let runFrames = [Tex.playerIdle, Tex.playerRun]

    // Tuning constants
    private let kJumpBufferWindow: Double = 0.14  // 押してから何秒以内に着地したら飛べるか
    private let kCoyoteWindow:     Double = 0.10  // 崖から落ちて何秒以内にジャンプできるか

    // MARK: - Factory
    static func spawn(at pos: CGPoint) -> Player {
        let p = Player(texture: Tex.playerIdle,
                       color: .clear,
                       size: CGSize(width: 24, height: 36))
        p.position = pos
        p.name = "player"
        p.zPosition = 10

        let body = SKPhysicsBody(rectangleOf: CGSize(width: 18, height: 32))
        body.mass = 1.0
        body.allowsRotation = false
        body.categoryBitMask    = PC.player
        body.contactTestBitMask = PC.solid | PC.movPlat | PC.enemy | PC.hazard | PC.goal
        body.collisionBitMask   = PC.solid | PC.movPlat
        body.linearDamping  = 0.5
        body.restitution    = 0
        body.friction       = 0.4
        p.physicsBody = body
        return p
    }

    // MARK: - Input (called every frame from GameScene.update)
    func applyInput(left: Bool, right: Bool, jumpBtn: Bool, dt: Double) {
        guard let pb = physicsBody else { return }

        // ── 横移動 ──
        var targetVX: CGFloat = 0
        if left  { targetVX = -kWalkSpeed; facingRight = false }
        if right { targetVX =  kWalkSpeed; facingRight = true  }
        let blend: CGFloat = isOnGround ? 0.22 : 0.12
        pb.velocity.dx += (targetVX - pb.velocity.dx) * blend
        xScale = facingRight ? 1 : -1

        // ── 速度ベースの地面チェック (上昇中は強制的に空中扱い) ──
        if pb.velocity.dy > 2.0 { isOnGround = false }

        // ── コヨーテタイム: 前フレームは地面、今フレームは空中 → カウント開始 ──
        if wasOnGround && !isOnGround { coyoteTime = kCoyoteWindow }
        wasOnGround = isOnGround
        coyoteTime  = max(0, coyoteTime - dt)

        // ── ジャンプ入力バッファ: 押した瞬間を記憶 ──
        let justPressed = jumpBtn && !prevJumpBtn
        prevJumpBtn = jumpBtn
        if justPressed { jumpBuffer = kJumpBufferWindow }
        jumpBuffer = max(0, jumpBuffer - dt)

        // ── ジャンプ発動条件: バッファあり かつ (地面 or コヨーテ) ──
        let canJump = isOnGround || coyoteTime > 0

        if jumpBuffer > 0 && canJump {
            pb.velocity.dy = kJumpVel
            isOnGround  = false
            jumpHeld    = dt
            jumpBuffer  = 0
            coyoteTime  = 0

        } else if jumpBtn && jumpHeld > 0 && jumpHeld < kMaxJumpHold {
            // 長押しで追加揚力
            pb.applyForce(CGVector(dx: 0, dy: kJumpExtra * pb.mass))
            jumpHeld += dt

        } else if !jumpBtn {
            jumpHeld = 0
        } else {
            jumpHeld += dt
        }

        // 最大落下速度
        if pb.velocity.dy < kMaxFall { pb.velocity.dy = kMaxFall }

        // ── アニメーション ──
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

    // MARK: - Moving platform sync
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

    func stopRiding() { ridingPlatform = nil }
}
