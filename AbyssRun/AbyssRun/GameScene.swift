import SpriteKit

// MARK: - Game state machine
enum GameState { case playing, dying, gameOver, clear }

final class GameScene: SKScene, SKPhysicsContactDelegate {

    // ── World ────────────────────────────────────────────────────────────────
    var worldNode  = SKNode()
    var cameraNode = SKCameraNode()
    var hud        = HUDNode()
    var player:    Player!
    var bgNode:    SKNode!

    // ── Stage data ───────────────────────────────────────────────────────────
    var stage: StageBuilder.BuiltStage!
    var crumbleContacts: Set<ObjectIdentifier> = []  // blocks player is standing on

    // ── Game state ───────────────────────────────────────────────────────────
    var state:      GameState = .playing
    var deathCount: Int = 0
    var timeLeft:   Double = kTimeLimit
    var lastUpdate: TimeInterval = 0
    var stateTimer: Double = 0   // used for dying / clear animations
    var startTime:  TimeInterval = 0

    // ── Contact flags set by didBegin/End (read in update) ───────────────────
    var contactGround   = 0   // reference count
    var contactMovePlat = 0

    // MARK: - Scene entry
    override func didMove(to view: SKView) {
        physicsWorld.gravity   = CGVector(dx: 0, dy: kGravity)
        physicsWorld.contactDelegate = self

        setupBackground()
        setupWorld()
        spawnPlayer()
        setupCamera()
        setupHUD()
    }

    // MARK: - Background (parallax layers)
    func setupBackground() {
        bgNode = SKNode()
        bgNode.zPosition = -10
        addChild(bgNode)

        // Sky gradient via two rectangles
        let skyBottom = SKSpriteNode(color: .abyssBg,
                                     size: CGSize(width: 20000, height: kSceneH))
        skyBottom.position = CGPoint(x: 10000, y: 0)
        bgNode.addChild(skyBottom)

        // Distant pillars / spires for atmosphere (static)
        let pillarCount = 30
        for i in 0..<pillarCount {
            let h = CGFloat.random(in: 60...180)
            let w = CGFloat.random(in: 10...28)
            let pillar = SKSpriteNode(
                color: UIColor(red: CGFloat.random(in: 0.06...0.12),
                               green: CGFloat.random(in: 0.02...0.06),
                               blue: CGFloat.random(in: 0.15...0.28),
                               alpha: 1),
                size: CGSize(width: w, height: h))
            pillar.position = CGPoint(x: CGFloat(i) * 240 + CGFloat.random(in: 0...200),
                                       y: kSceneH * 0.1 + h / 2)
            bgNode.addChild(pillar)
        }

        // Stars
        for _ in 0..<80 {
            let star = SKSpriteNode(color: UIColor(white: 1, alpha: CGFloat.random(in: 0.3...0.9)),
                                    size: CGSize(width: 2, height: 2))
            star.position = CGPoint(x: CGFloat.random(in: 0...8000),
                                     y: CGFloat.random(in: kSceneH * 0.35...kSceneH * 0.95))
            bgNode.addChild(star)
        }
    }

    // MARK: - World / Stage setup
    func setupWorld() {
        addChild(worldNode)
        stage = StageBuilder.build(in: worldNode, groundRow: 0)
    }

    // MARK: - Spawn player
    func spawnPlayer() {
        if player != nil { player.removeFromParent() }
        player = Player.spawn(at: CGPoint(x: kTile * 3, y: kTile * 5))
        worldNode.addChild(player)
        contactGround   = 0
        contactMovePlat = 0
        player.isOnGround = false
        player.stopRiding()
    }

    // MARK: - Camera (follows player X, fixed Y)
    func setupCamera() {
        cameraNode.position = CGPoint(x: kSceneW / 2, y: kSceneH / 2)
        addChild(cameraNode)
        camera = cameraNode
        cameraNode.addChild(hud)
    }

    func setupHUD() {
        // hud is already a child of cameraNode
    }

    // MARK: - Touch forwarding
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Game-over / clear: delegate to scene-level tap
        if state == .gameOver || state == .clear {
            handleUITap(touches)
            return
        }
        touches.forEach { hud.touchDown($0) }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touches.forEach { hud.touchUp($0) }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touches.forEach { hud.touchUp($0) }
    }

    func handleUITap(_ touches: Set<UITouch>) {
        for touch in touches {
            let pt = touch.location(in: cameraNode)
            // Check retry / continue buttons (children of cameraNode named "retryBtn")
            for node in cameraNode.children where node.name == "retryBtn" {
                if node.contains(pt) { fullRestart(); return }
            }
        }
    }

    // MARK: - MAIN UPDATE LOOP
    override func update(_ currentTime: TimeInterval) {
        guard lastUpdate != 0 else { lastUpdate = currentTime; startTime = currentTime; return }
        let dt = min(currentTime - lastUpdate, 0.05)
        lastUpdate = currentTime

        switch state {
        case .playing:
            updatePlaying(dt: dt)
        case .dying:
            updateDying(dt: dt)
        case .gameOver, .clear:
            break
        }
    }

    // MARK: - Playing update
    func updatePlaying(dt: Double) {
        // Timer
        timeLeft -= dt
        if timeLeft <= 0 {
            timeLeft = 0
            triggerDeath(cause: "TIME UP!")
            return
        }
        hud.update(timeLeft: timeLeft, deaths: deathCount)

        // isOnGround は didBegin/didEnd で直接 player へセット済み。
        // カウンターが0になったときだけ false に戻す（速度ベース上書きは Player 側で行う）
        if contactGround == 0 && contactMovePlat == 0 {
            player.isOnGround = false
        }
        player.applyInput(left: hud.holdLeft, right: hud.holdRight,
                          jumpBtn: hud.holdJump, dt: dt)
        player.applyPlatformRide()

        // Update special blocks
        updateCrumbling(dt: dt)
        updateVanishing(dt: dt)
        updateMovingPlatforms(dt: dt)

        // Enemy AI
        for enemy in stage.enemies where enemy.parent != nil {
            enemy.updateAI(dt: dt)
        }

        // Camera follows player (clamped so we don't scroll behind start)
        let camX = max(kSceneW / 2, min(player.position.x, stage.stageWidth - kSceneW / 2))
        cameraNode.position.x = camX

        // Out-of-bounds check (fell off sides)
        if player.position.y < -kTile * 4 {
            triggerDeath(cause: "FELL!")
        }
    }

    // MARK: - Crumbling block tracking
    func updateCrumbling(dt: Double) {
        var toRemove: [BlockNode] = []
        for b in stage.crumblingBlocks {
            guard b.parent != nil else { toRemove.append(b); continue }
            let onTop = crumbleContacts.contains(ObjectIdentifier(b))
            if b.updateCrumble(playerOnTop: onTop, dt: dt) {
                crumbleContacts.remove(ObjectIdentifier(b))
                toRemove.append(b)
            }
        }
        for gone in toRemove { stage.crumblingBlocks.removeAll { $0 === gone } }
    }

    func updateVanishing(dt: Double) {
        for b in stage.vanishingBlocks where b.parent != nil {
            b.updateVanish(dt: dt)
        }
    }

    func updateMovingPlatforms(dt: Double) {
        for b in stage.movingBlocks where b.parent != nil {
            let prevX = b.position.x
            let prevY = b.position.y
            b.updateMoving(dt: dt)
            // If player is riding this platform, sync position
            if player.ridingPlatform === b {
                player.platformPrevX = prevX
                player.platformPrevY = prevY
            }
        }
    }

    // MARK: - Dying animation
    func updateDying(dt: Double) {
        stateTimer += dt
        if stateTimer > 1.8 {
            if deathCount >= 30 {
                // After 30 deaths show a compassionate game over
                showGameOver()
            } else {
                fullRestart()
            }
        }
    }

    // MARK: - Death trigger
    func triggerDeath(cause: String = "DEAD") {
        guard state == .playing else { return }
        state = .dying
        stateTimer = 0
        deathCount += 1

        // Visual: red flash, bounce up
        player.physicsBody?.velocity = CGVector(dx: 0, dy: 12)
        player.physicsBody?.collisionBitMask = 0
        player.run(SKAction.sequence([
            SKAction.colorize(with: .red, colorBlendFactor: 1, duration: 0.05),
            SKAction.colorize(with: .abyssPlayer, colorBlendFactor: 0, duration: 0.05),
            SKAction.wait(forDuration: 0.3),
            SKAction.fadeOut(withDuration: 0.4),
        ]))

        hud.showMessage(cause, color: .abyssDanger, duration: 1.5)

        // Screen flash
        let flash = SKSpriteNode(color: UIColor.red.withAlphaComponent(0.4),
                                 size: CGSize(width: kSceneW, height: kSceneH))
        flash.zPosition = 80
        cameraNode.addChild(flash)
        flash.run(SKAction.sequence([
            SKAction.wait(forDuration: 0.05),
            SKAction.fadeOut(withDuration: 0.25),
            SKAction.removeFromParent(),
        ]))
    }

    // MARK: - Full restart (same scene, new stage build)
    func fullRestart() {
        // Remove old world
        worldNode.removeAllChildren()
        worldNode.removeFromParent()
        worldNode = SKNode()
        addChild(worldNode)

        // Rebuild stage
        stage = StageBuilder.build(in: worldNode, groundRow: 0)

        // Reset
        crumbleContacts.removeAll()
        contactGround   = 0
        contactMovePlat = 0
        timeLeft = kTimeLimit
        state    = .playing
        stateTimer = 0
        startTime = lastUpdate

        // Remove overlay buttons
        cameraNode.children
            .filter { $0.name == "retryBtn" || $0.name == "overlay" }
            .forEach { $0.removeFromParent() }

        hud.touchMap.removeAll()
        hud.holdLeft = false; hud.holdRight = false; hud.holdJump = false

        spawnPlayer()
    }

    // MARK: - Stage clear
    func triggerClear() {
        guard state == .playing else { return }
        state = .clear

        player.physicsBody?.velocity = .zero
        player.physicsBody?.isDynamic = false

        let clearTime = lastUpdate - startTime
        showClearScreen(time: clearTime, deaths: deathCount)
    }

    // MARK: - Physics Contacts

    // SpriteKit の contactNormal は「bodyB → bodyA 方向」。
    // bodyA/bodyB の順番は保証されないので、player がどちら側かを確認して
    // 「プレイヤーから見た上向き成分」を正しく算出する。
    private func upwardComponent(_ contact: SKPhysicsContact,
                                 playerCategory: UInt32 = PC.player) -> CGFloat {
        let aIsPlayer = contact.bodyA.categoryBitMask == playerCategory
        // aIsPlayer のとき: normal は B(地面)→A(プレイヤー) = 上向き → dy > 0
        // !aIsPlayer のとき: normal は B(プレイヤー)→A(地面) = 下向き → 符号を反転
        return aIsPlayer ? contact.contactNormal.dy : -contact.contactNormal.dy
    }

    func didBegin(_ contact: SKPhysicsContact) {
        let a = contact.bodyA; let b = contact.bodyB
        let combo = a.categoryBitMask | b.categoryBitMask

        // Player on solid ground
        if combo == (PC.player | PC.solid) {
            let upDY = upwardComponent(contact)
            if upDY > 0.3 {
                contactGround += 1
                player.isOnGround = true   // 直接セット (バッファジャンプに即反映)
            }
            // Crumble detection
            let otherNode = (a.categoryBitMask == PC.player) ? b.node : a.node
            if let block = otherNode as? BlockNode, block.blockType == .crumble, upDY > 0.3 {
                crumbleContacts.insert(ObjectIdentifier(block))
            }
        }

        // Player on moving / vanishing platform
        if combo == (PC.player | PC.movPlat) {
            let upDY = upwardComponent(contact)
            if upDY > 0.3 {
                contactMovePlat += 1
                player.isOnGround = true
                let platNode = (a.categoryBitMask == PC.movPlat) ? a.node : b.node
                if let blockNode = platNode as? BlockNode,
                   (blockNode.blockType == .movingH || blockNode.blockType == .movingV) {
                    player.startRiding(blockNode)
                }
            }
        }

        // Player hits hazard (spike, death floor)
        if combo == (PC.player | PC.hazard) {
            triggerDeath(cause: "SPIKES!")
        }

        // Player touches enemy
        if combo == (PC.player | PC.enemy) {
            let enemyBody  = (a.categoryBitMask == PC.enemy)  ? a : b
            let playerBody = (a.categoryBitMask == PC.player) ? a : b
            guard let enemy  = enemyBody.node  as? Enemy,
                  let _ = playerBody.node as? Player else { return }

            let playerBottom = player.position.y - player.size.height / 2
            let velY = playerBody.velocity.dy
            if enemy.isStomp(playerBottom: playerBottom, playerVelY: velY) {
                enemy.die()
                stage.enemies.removeAll { $0 === enemy }
                // Bounce player
                player.physicsBody?.velocity.dy = kJumpVel * 0.65
                player.isOnGround = false
            } else {
                triggerDeath(cause: "ENEMY!")
            }
        }

        // Player reaches goal
        if combo == (PC.player | PC.goal) {
            triggerClear()
        }
    }

    func didEnd(_ contact: SKPhysicsContact) {
        let a = contact.bodyA; let b = contact.bodyB
        let combo = a.categoryBitMask | b.categoryBitMask

        if combo == (PC.player | PC.solid) {
            let upDY = upwardComponent(contact)
            if upDY > 0.3 {
                contactGround = max(0, contactGround - 1)
                let otherNode = (a.categoryBitMask == PC.player) ? b.node : a.node
                if let block = otherNode as? BlockNode, block.blockType == .crumble {
                    crumbleContacts.remove(ObjectIdentifier(block))
                }
                if contactGround == 0 && contactMovePlat == 0 {
                    player.isOnGround = false
                }
            }
        }

        if combo == (PC.player | PC.movPlat) {
            let upDY = upwardComponent(contact)
            if upDY > 0.3 {
                contactMovePlat = max(0, contactMovePlat - 1)
                if contactMovePlat == 0 {
                    player.stopRiding()
                    if contactGround == 0 { player.isOnGround = false }
                }
            }
        }
    }

    // MARK: - Clear screen
    func showClearScreen(time: TimeInterval, deaths: Int) {
        let overlay = SKSpriteNode(color: UIColor(white: 0, alpha: 0.75),
                                   size: CGSize(width: kSceneW, height: kSceneH))
        overlay.name = "overlay"
        overlay.zPosition = 70
        cameraNode.addChild(overlay)

        let lines: [(String, CGFloat, UIColor)] = [
            ("STAGE CLEAR!", 80, .abyssGoal),
            (String(format: "TIME  %.1fs", time),  20, .white),
            ("DEATH  \(deaths)",               20, deaths > 5 ? .abyssDanger : .white),
        ]
        var yOff: CGFloat = 60
        for (text, size, color) in lines {
            let lbl = SKLabelNode(text: text)
            lbl.fontName = "AvenirNext-Bold"
            lbl.fontSize = size
            lbl.fontColor = color
            lbl.position = CGPoint(x: 0, y: yOff)
            lbl.zPosition = 72
            overlay.addChild(lbl)
            yOff -= size + 14
        }

        // Particle-like celebration: many tiny gold squares
        for _ in 0..<40 {
            let spark = SKSpriteNode(color: .abyssGoal,
                                     size: CGSize(width: 6, height: 6))
            spark.position = CGPoint(x: CGFloat.random(in: -kSceneW/2...kSceneW/2),
                                      y: kSceneH / 2)
            spark.zPosition = 73
            overlay.addChild(spark)
            spark.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: CGFloat.random(in: -100...100),
                                    y: -CGFloat.random(in: 100...300),
                                    duration: 1.0),
                    SKAction.fadeOut(withDuration: 1.0),
                ]),
                SKAction.removeFromParent(),
            ]))
        }

        // Retry button (acts as "TITLE" since only 1 stage)
        let btn = makeOverlayButton("PLAY AGAIN", y: -90)
        btn.name = "retryBtn"
        btn.zPosition = 75
        cameraNode.addChild(btn)
    }

    // MARK: - Helper: overlay button
    private func makeOverlayButton(_ label: String, y: CGFloat) -> SKNode {
        let container = SKNode()
        container.position = CGPoint(x: 0, y: y)

        let bg = SKShapeNode(rectOf: CGSize(width: 200, height: 44), cornerRadius: 8)
        bg.fillColor   = .abyssGoal
        bg.strokeColor = .clear
        container.addChild(bg)

        let lbl = SKLabelNode(text: label)
        lbl.fontName = "AvenirNext-Bold"
        lbl.fontSize = 22
        lbl.fontColor = .black
        lbl.verticalAlignmentMode = .center
        container.addChild(lbl)
        return container
    }

    // MARK: - Game over screen
    func showGameOver() {
        state = .gameOver
        let overlay = SKSpriteNode(color: UIColor(white: 0, alpha: 0.78),
                                   size: CGSize(width: kSceneW, height: kSceneH))
        overlay.name = "overlay"
        overlay.zPosition = 70
        cameraNode.addChild(overlay)

        let title = SKLabelNode(text: "GAME OVER")
        title.fontName = "AvenirNext-Bold"
        title.fontSize = 72
        title.fontColor = .abyssDanger
        title.position = CGPoint(x: 0, y: 40)
        title.zPosition = 72
        overlay.addChild(title)

        let sub = SKLabelNode(text: "DEATH: \(deathCount)")
        sub.fontName = "Courier-Bold"
        sub.fontSize = 22
        sub.fontColor = .white
        sub.position = CGPoint(x: 0, y: -20)
        sub.zPosition = 72
        overlay.addChild(sub)

        let btn = makeOverlayButton("RETRY", y: -70)
        btn.name = "retryBtn"
        btn.zPosition = 75
        cameraNode.addChild(btn)
    }
}
