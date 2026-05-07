import SpriteKit
import UIKit

// MARK: - Physics categories
private let catPlayer:    UInt32 = 0x01
private let catGround:    UInt32 = 0x02
private let catEnemy:     UInt32 = 0x04
private let catProjectile:UInt32 = 0x08
private let catGoal:      UInt32 = 0x10
private let catKill:      UInt32 = 0x20

// MARK: - Enemy types
enum EnemyKind { case goomba, koopa, hammerBro }

// MARK: - Moving platform descriptor
struct MovPlat {
    let node: SKSpriteNode
    let minX: CGFloat; let maxX: CGFloat
    let minY: CGFloat; let maxY: CGFloat
    let speed: CGFloat
    let vertical: Bool
    var goPos: Bool
}

// MARK: - Fire bar descriptor
struct FireBarData {
    let pivot: SKNode
    var angle: CGFloat
    let speed: CGFloat  // radians/sec
}

// MARK: - Bullet Bill launcher
struct LauncherData {
    let node: SKNode
    let dir: CGFloat    // +1 right, -1 left
    let interval: TimeInterval
    var last: TimeInterval
}

// MARK: - Enemy data
struct EnemyData {
    var kind: EnemyKind
    var facingRight: Bool
    var shootTimer: TimeInterval
    var onGround: Bool
}

final class GameScene: SKScene, SKPhysicsContactDelegate {

    // ── Constants ──────────────────────────────────────────────
    let T: CGFloat = 32          // tile size
    let groundY: CGFloat = 170   // y of ground surface in world coords

    // Player physics
    let walkSpeed:  CGFloat = 150
    let runSpeed:   CGFloat = 270
    let jumpImpulse: CGFloat = 16   // applied as impulse
    let maxFallSpeed: CGFloat = -700

    // ── Nodes ──────────────────────────────────────────────────
    var worldNode: SKNode!
    var cameraNode: SKCameraNode!
    var hudNode: SKNode!
    var player: SKSpriteNode!

    // ── Game state ─────────────────────────────────────────────
    enum GState { case playing, dying, gameOver, won }
    var gState: GState = .playing
    var lives = 3
    var score = 0
    var timeLeft: Double = 75
    var deathTimer: Double = 0

    // ── Input ──────────────────────────────────────────────────
    var holdL = false
    var holdR = false
    var holdJump = false
    var holdRun  = false
    var jumpHeld: Double = 0       // seconds jump button held
    var isOnGround = false
    var touchMap: [UITouch: String] = [:]

    // Button nodes (in HUD / camera space)
    var btnL: SKShapeNode!
    var btnR: SKShapeNode!
    var btnA: SKShapeNode!   // jump
    var btnB: SKShapeNode!   // run

    // ── HUD ────────────────────────────────────────────────────
    var lblLives: SKLabelNode!
    var lblScore: SKLabelNode!
    var lblTimer: SKLabelNode!
    var lblMsg:   SKLabelNode!

    // ── Level data ─────────────────────────────────────────────
    var movPlats:   [MovPlat]       = []
    var fireBars:   [FireBarData]   = []
    var launchers:  [LauncherData]  = []
    var enemies:    [SKSpriteNode: EnemyData] = [:]
    var bullets:    [SKSpriteNode]  = []
    var hammers:    [SKSpriteNode]  = []
    var piranhas:   [(node: SKSpriteNode, base: CGFloat, timer: Double, showing: Bool)] = []
    var windZones:  [(minX: CGFloat, maxX: CGFloat)] = []

    // last time tracking
    var lastUpdate: TimeInterval = 0

    // MARK: - Scene entry
    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 0.39, green: 0.58, blue: 0.93, alpha: 1)
        physicsWorld.gravity = CGVector(dx: 0, dy: -25)
        physicsWorld.contactDelegate = self

        worldNode = SKNode()
        addChild(worldNode)

        cameraNode = SKCameraNode()
        addChild(cameraNode)
        camera = cameraNode

        hudNode = SKNode()
        cameraNode.addChild(hudNode)

        buildLevel()
        spawnPlayer()
        setupHUD()
        setupControls()
    }

    // MARK: - Pixel texture helper
    // color code: R=red B=blue S=skin N=brown G=green Y=yellow
    //             K=black W=white O=clear D=dark-brown P=purple
    func px(_ rows: [String], scale s: Int = 2) -> SKTexture {
        let map: [Character: UIColor] = [
            "R": UIColor(red:0.90, green:0.12, blue:0.08, alpha:1),
            "B": UIColor(red:0.15, green:0.30, blue:0.90, alpha:1),
            "S": UIColor(red:1.00, green:0.80, blue:0.55, alpha:1),
            "N": UIColor(red:0.55, green:0.28, blue:0.07, alpha:1),
            "G": UIColor(red:0.10, green:0.72, blue:0.15, alpha:1),
            "Y": UIColor(red:1.00, green:0.88, blue:0.00, alpha:1),
            "K": UIColor.black,
            "W": UIColor.white,
            "D": UIColor(red:0.28, green:0.14, blue:0.00, alpha:1),
            "P": UIColor(red:0.60, green:0.18, blue:0.60, alpha:1),
            "C": UIColor(red:0.75, green:0.50, blue:0.20, alpha:1),  // brick
            "L": UIColor(red:0.45, green:0.25, blue:0.08, alpha:1),  // dark brick
        ]
        let cols = rows[0].count
        let rws  = rows.count
        let iw = cols * s; let ih = rws * s
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: iw, height: ih))
        let img = renderer.image { ctx in
            let g = ctx.cgContext
            for (r, row) in rows.enumerated() {
                for (c, ch) in row.enumerated() {
                    guard ch != "O", let col = map[ch] else { continue }
                    g.setFillColor(col.cgColor)
                    g.fill(CGRect(x: c*s, y: r*s, width: s, height: s))
                }
            }
        }
        return SKTexture(image: img)
    }

    // MARK: - Sprite factories
    func makeMarioTex(small: Bool = false) -> SKTexture {
        // 16×16 NES-ish Mario sprite (upright)
        let rows = [
            "OOORRRRROOOOOOO",
            "OORRRRRRRROOOO",
            "OORNNSSSNNOOO",
            "ORNSSSSWSSNOO",
            "ORNSSSWWSSNOO",
            "OOSSSSSSSSOOO",
            "OOORRRRRROOOO",
            "ORRRRRRRRRROOO",
            "RBBBRRRBBBRROO",
            "RBBBBBBBBBROO",
            "RBBBBBBBBBRROO",
            "OOBBBOOBBBOOOO",
            "ODDBBOOBBBOOOO",
            "ODDBBOODDBOOO",
            "ODDDOOOODDDOO",
        ]
        return px(rows, scale: 2)
    }

    func makeGoombaTexA() -> SKTexture {
        let rows = [
            "OONNNNNNNNNOOO",
            "ONNNNNNNNNNNO",
            "NNNNNNNNNNNNN",
            "NNWWNNNNNWWNN",
            "NWKKWNNWKKWNN",
            "NWWWNNNNWWWNN",
            "NNNNNNNNNNNNN",
            "KNNNNNNNNNNKK",
            "KKNNNNNNNNNKK",
            "KKDDDDDDDDKKO",
            "ODDDDDDDDDDOO",
            "ODDNNNNNNDOO",
            "ODDOOOOOOOOO",
        ]
        return px(rows, scale: 2)
    }

    func makeKoopaTexA() -> SKTexture {
        let rows = [
            "OOGGGGGGOOOOO",
            "OGGGGGGGGGOOO",
            "GGSSGGGGSSOOO",
            "GGSSWWGWSWGOO",
            "GGGSSGGSSGGO",
            "OOGGGGGGGGOOO",
            "OYYYYYYYYOOOO",
            "OYYGYYGYYGOOO",
            "OYYGYYGYYGOO",
            "OYYYYYYYYYYOO",
            "OOGGGOOOGGGOO",
            "OOGGGOOOGGGOO",
            "OONNNOOONNNOO",
        ]
        return px(rows, scale: 2)
    }

    func makeHammerBroTex() -> SKTexture {
        let rows = [
            "OOGGGGGGOOOOO",
            "OGGGGGGGGGOOO",
            "OGGSSGGSSGGO",
            "OGHSSWGWSHGO",
            "OGGSSGGSSGGOO",
            "RRRGGGGGGRRRO",
            "RRRRRRRRRRRRO",
            "BBBRRRBBBRROO",
            "BBBBBBBBBBOOO",
            "OOBBBBBBBBOOO",
            "OOBBBOBBBOOOO",
            "OODDDODDDOOOO",
            "OODDDODDDOOOO",
        ]
        return px(rows, scale: 2)
    }

    func makeBulletTex() -> SKTexture {
        let rows = [
            "OKKKKKKOO",
            "KKKKKKKKO",
            "KKWKKKWKK",
            "KKKKKKKKO",
            "OKKKKKKOO",
        ]
        return px(rows, scale: 2)
    }

    func makeHammerTex() -> SKTexture {
        let rows = [
            "NNNNOOO",
            "NNNNOOO",
            "ONNNOOO",
            "OONNKOO",
            "OOONKOO",
            "OOOONOO",
            "OOOONOO",
        ]
        return px(rows, scale: 2)
    }

    func makeFlagTex() -> SKTexture {
        let rows = [
            "KGGGGGOO",
            "KGGGOOOO",
            "KOOOOOOO",
            "KOOOOOOO",
            "KOOOOOOO",
            "KOOOOOOO",
            "KOOOOOOO",
            "KOOOOOOO",
            "KOOOOOOO",
            "KOOOOOOO",
            "KOOOOOOO",
            "KOOOOOOO",
        ]
        return px(rows, scale: 3)
    }

    func makePipeTex(height: Int) -> SKTexture {
        var rows: [String] = []
        rows.append("GGGGGGGGG")   // rim top
        rows.append("GDDGDGDDG")   // rim detail
        for _ in 0..<(height - 1) {
            rows.append("OGGGDGGGO")
        }
        return px(rows, scale: 4)
    }

    func makeBrickTex() -> SKTexture {
        let rows = [
            "CCCCCCCC",
            "CLCLCLCL",
            "CCCCCCCC",
            "LCLCLCLC",
        ]
        return px(rows, scale: 4)
    }

    func makeGroundTex() -> SKTexture {
        let rows = [
            "CCCCCCCC",
            "CLCLCLCL",
            "CCCCCCCC",
            "LCLCLCLC",
        ]
        return px(rows, scale: 8)
    }

    // MARK: - Level building helpers

    @discardableResult
    func addPlatform(tx: Int, ty: Int, tw: Int, th: Int) -> SKSpriteNode {
        let w = CGFloat(tw) * T
        let h = CGFloat(th) * T
        let x = CGFloat(tx) * T + w / 2
        let y = groundY + CGFloat(ty) * T - h / 2 + T
        let node = SKSpriteNode(texture: makeBrickTex(),
                                size: CGSize(width: w, height: h))
        node.position = CGPoint(x: x, y: y)
        let pb = SKPhysicsBody(rectangleOf: node.size)
        pb.isDynamic = false
        pb.categoryBitMask = catGround
        pb.collisionBitMask = catPlayer | catEnemy
        pb.contactTestBitMask = catPlayer
        pb.friction = 0.6
        node.physicsBody = pb
        worldNode.addChild(node)
        return node
    }

    func addMovingPlatform(tx: Int, ty: Int, tw: Int,
                           minTx: Int, maxTx: Int, speed: CGFloat,
                           vertical: Bool = false,
                           minTy: Int = 0, maxTy: Int = 0,
                           startPos: Bool = true) {
        let w = CGFloat(tw) * T
        let h = T
        let startX = CGFloat(tx) * T + w / 2
        let startY = groundY + CGFloat(ty) * T + h / 2
        let node = SKSpriteNode(color: UIColor(red: 0.3, green: 0.65, blue: 0.3, alpha: 1),
                                size: CGSize(width: w, height: h))
        node.position = CGPoint(x: startX, y: startY)
        let pb = SKPhysicsBody(rectangleOf: node.size)
        pb.isDynamic = false
        pb.categoryBitMask = catGround
        pb.collisionBitMask = catPlayer
        pb.contactTestBitMask = catPlayer
        pb.friction = 0.0  // slippery — harder to stay on
        node.physicsBody = pb
        worldNode.addChild(node)

        let data = MovPlat(
            node: node,
            minX: CGFloat(minTx) * T + w / 2,
            maxX: CGFloat(maxTx) * T + w / 2,
            minY: groundY + CGFloat(minTy) * T + h / 2,
            maxY: groundY + CGFloat(maxTy) * T + h / 2,
            speed: speed,
            vertical: vertical,
            goPos: startPos
        )
        movPlats.append(data)
    }

    func addPipe(tx: Int, pipeHeight: Int, hasPiranha: Bool) {
        let h = CGFloat(pipeHeight) * T + T
        let w = T * 2
        let x = CGFloat(tx) * T + w / 2
        let y = groundY + T + h / 2
        let node = SKSpriteNode(texture: makePipeTex(height: pipeHeight),
                                size: CGSize(width: w, height: h))
        node.position = CGPoint(x: x, y: y)
        let pb = SKPhysicsBody(rectangleOf: node.size)
        pb.isDynamic = false
        pb.categoryBitMask = catGround
        pb.collisionBitMask = catPlayer | catEnemy
        pb.contactTestBitMask = catPlayer
        node.physicsBody = pb
        worldNode.addChild(node)

        if hasPiranha {
            let pw: CGFloat = T * 1.5
            let ph: CGFloat = T * 1.5
            let pNode = SKSpriteNode(color: UIColor(red: 0.85, green: 0.1, blue: 0.1, alpha: 1),
                                     size: CGSize(width: pw, height: ph))
            // piranha drawn as red block with eyes
            pNode.position = CGPoint(x: x, y: y + h / 2 + ph / 2 - 4)
            let epb = SKPhysicsBody(rectangleOf: pNode.size)
            epb.isDynamic = false
            epb.categoryBitMask = catEnemy
            epb.contactTestBitMask = catPlayer
            epb.collisionBitMask = 0
            pNode.physicsBody = epb
            pNode.name = "piranha"
            worldNode.addChild(pNode)

            let topY = y + h / 2 + ph - 4
            let hideY = y + h / 2 - ph  // hidden inside pipe
            piranhas.append((node: pNode, base: topY, timer: 0, showing: true))

            // start hidden, will animate
            pNode.position.y = hideY
        }
    }

    func addEnemy(kind: EnemyKind, tx: Int, ty: Int) {
        let size: CGSize
        let tex: SKTexture
        switch kind {
        case .goomba:
            size = CGSize(width: T, height: T)
            tex = makeGoombaTexA()
        case .koopa:
            size = CGSize(width: T, height: T * 1.5)
            tex = makeKoopaTexA()
        case .hammerBro:
            size = CGSize(width: T, height: T * 1.5)
            tex = makeHammerBroTex()
        }
        let node = SKSpriteNode(texture: tex, size: size)
        let x = CGFloat(tx) * T + T / 2
        let y = groundY + CGFloat(ty) * T + size.height / 2
        node.position = CGPoint(x: x, y: y)
        node.name = "enemy"
        let pb = SKPhysicsBody(rectangleOf: CGSize(width: size.width - 4, height: size.height - 4))
        pb.isDynamic = true
        pb.allowsRotation = false
        pb.categoryBitMask = catEnemy
        pb.contactTestBitMask = catPlayer | catGround
        pb.collisionBitMask = catGround
        pb.linearDamping = 0
        pb.restitution = 0
        node.physicsBody = pb
        worldNode.addChild(node)

        let patrol = CGFloat(4) * T
        enemies[node] = EnemyData(kind: kind,
                                  facingRight: false,
                                  shootTimer: Double.random(in: 0...1.5),
                                  onGround: false)
    }

    func addFireBar(tx: Int, ty: Int, length: Int, speed: CGFloat) {
        let pivot = SKNode()
        pivot.position = CGPoint(x: CGFloat(tx) * T + T / 2,
                                  y: groundY + CGFloat(ty) * T + T / 2)
        worldNode.addChild(pivot)

        for i in 1...length {
            let ball = SKSpriteNode(color: UIColor(red: 1, green: 0.4, blue: 0, alpha: 1),
                                    size: CGSize(width: 10, height: 10))
            ball.position = CGPoint(x: CGFloat(i) * 16, y: 0)
            ball.name = "fireball"
            let pb = SKPhysicsBody(circleOfRadius: 5)
            pb.isDynamic = false
            pb.categoryBitMask = catEnemy
            pb.contactTestBitMask = catPlayer
            pb.collisionBitMask = 0
            ball.physicsBody = pb
            pivot.addChild(ball)
        }
        fireBars.append(FireBarData(pivot: pivot, angle: 0, speed: speed))
    }

    func addLauncher(tx: Int, ty: Int, dir: CGFloat, interval: TimeInterval) {
        let node = SKSpriteNode(color: UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1),
                                size: CGSize(width: T, height: T * 1.5))
        node.position = CGPoint(x: CGFloat(tx) * T + T / 2,
                                 y: groundY + CGFloat(ty) * T + T * 0.75)
        node.name = "launcher"
        worldNode.addChild(node)
        launchers.append(LauncherData(node: node, dir: dir, interval: interval, last: -interval))
    }

    func addGoal(tx: Int) {
        // Flag pole
        let poleH: CGFloat = T * 8
        let pole = SKSpriteNode(color: UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1),
                                size: CGSize(width: 6, height: poleH))
        pole.position = CGPoint(x: CGFloat(tx) * T + T / 2,
                                 y: groundY + T + poleH / 2)
        worldNode.addChild(pole)

        let flag = SKSpriteNode(texture: makeFlagTex(),
                                size: CGSize(width: T * 1.5, height: T * 2))
        flag.position = CGPoint(x: CGFloat(tx) * T + T,
                                 y: groundY + T + poleH - T)
        flag.name = "goal"
        let gpb = SKPhysicsBody(rectangleOf: flag.size)
        gpb.isDynamic = false
        gpb.categoryBitMask = catGoal
        gpb.contactTestBitMask = catPlayer
        gpb.collisionBitMask = 0
        flag.physicsBody = gpb
        worldNode.addChild(flag)
    }

    func addDeathPit(fromTx: Int, toTx: Int) {
        let w = CGFloat(toTx - fromTx) * T
        let x = CGFloat(fromTx) * T + w / 2
        let zone = SKSpriteNode(color: .clear, size: CGSize(width: w, height: T * 2))
        zone.position = CGPoint(x: x, y: groundY - T)
        zone.name = "kill"
        let kpb = SKPhysicsBody(rectangleOf: zone.size)
        kpb.isDynamic = false
        kpb.categoryBitMask = catKill
        kpb.contactTestBitMask = catPlayer
        kpb.collisionBitMask = 0
        zone.physicsBody = kpb
        worldNode.addChild(zone)
    }

    // MARK: - Build the level
    func buildLevel() {
        // Global death floor
        let floor = SKSpriteNode(color: .clear, size: CGSize(width: 20000, height: T * 3))
        floor.position = CGPoint(x: 10000, y: groundY - T * 2)
        let fpb = SKPhysicsBody(rectangleOf: floor.size)
        fpb.isDynamic = false
        fpb.categoryBitMask = catKill
        fpb.contactTestBitMask = catPlayer
        fpb.collisionBitMask = 0
        floor.physicsBody = fpb
        worldNode.addChild(floor)

        // ── §1  Opening – narrow platforms with instant gaps ──
        addPlatform(tx:0,  ty:0, tw:4, th:3)   // start
        addDeathPit(fromTx:4, toTx:7)
        addPlatform(tx:7,  ty:0, tw:2, th:3)   // one goomba
        addEnemy(kind:.goomba, tx:7, ty:3)
        addDeathPit(fromTx:9, toTx:13)
        addPlatform(tx:13, ty:0, tw:2, th:3)   // single tile land
        addDeathPit(fromTx:15, toTx:19)
        addPlatform(tx:19, ty:0, tw:3, th:3)
        addEnemy(kind:.goomba, tx:19, ty:3)
        addEnemy(kind:.goomba, tx:20, ty:3)
        addDeathPit(fromTx:22, toTx:27)
        addPlatform(tx:27, ty:0, tw:4, th:3)
        addEnemy(kind:.koopa, tx:28, ty:3)

        // ── §2  Moving platform hell over huge pit ──
        addDeathPit(fromTx:31, toTx:48)
        addMovingPlatform(tx:32, ty:4, tw:2, minTx:31, maxTx:38, speed:62)
        addMovingPlatform(tx:40, ty:3, tw:2, minTx:37, maxTx:45, speed:88, startPos:false)
        addLauncher(tx:29, ty:2, dir:1, interval:3.0)
        addLauncher(tx:50, ty:2, dir:-1, interval:2.8)

        // ── §3  After pit – Hammer Bros ──
        addPlatform(tx:48, ty:0, tw:6, th:3)
        addEnemy(kind:.hammerBro, tx:50, ty:3)
        addEnemy(kind:.hammerBro, tx:53, ty:3)

        // ── §4  Pipe gauntlet (Piranha Plants) ──
        addDeathPit(fromTx:54, toTx:57)
        addPlatform(tx:57, ty:0, tw:12, th:3)
        addPipe(tx:58, pipeHeight:3, hasPiranha:true)
        addPipe(tx:61, pipeHeight:2, hasPiranha:true)
        addPipe(tx:64, pipeHeight:3, hasPiranha:true)
        addEnemy(kind:.goomba, tx:60, ty:3)
        addEnemy(kind:.goomba, tx:63, ty:3)

        // ── §5  Elevated narrow ledges + Fire bars ──
        addDeathPit(fromTx:69, toTx:73)
        addPlatform(tx:73, ty:0, tw:2, th:3)
        addDeathPit(fromTx:75, toTx:79)
        addPlatform(tx:79, ty:4, tw:3, th:1)   // elevated
        addFireBar(tx:80, ty:5, length:4, speed:2.3)
        addDeathPit(fromTx:82, toTx:86)
        addPlatform(tx:86, ty:2, tw:3, th:1)   // mid-height shelf
        addDeathPit(fromTx:89, toTx:93)
        addPlatform(tx:93, ty:0, tw:2, th:3)
        addEnemy(kind:.koopa, tx:93, ty:3)

        // ── §6  Vertical moving platforms ──
        addDeathPit(fromTx:95, toTx:110)
        addMovingPlatform(tx:97,  ty:3, tw:2, minTx:0, maxTx:0,
                          speed:70, vertical:true, minTy:3, maxTy:8, startPos:true)
        addMovingPlatform(tx:102, ty:6, tw:2, minTx:0, maxTx:0,
                          speed:95, vertical:true, minTy:2, maxTy:7, startPos:false)
        addMovingPlatform(tx:107, ty:4, tw:2, minTx:0, maxTx:0,
                          speed:80, vertical:true, minTy:4, maxTy:9, startPos:true)

        // ── §7  Solid ground – enemy gauntlet ──
        addPlatform(tx:110, ty:0, tw:16, th:3)
        addEnemy(kind:.goomba,    tx:112, ty:3)
        addEnemy(kind:.goomba,    tx:114, ty:3)
        addEnemy(kind:.koopa,     tx:116, ty:3)
        addEnemy(kind:.hammerBro, tx:118, ty:3)
        addEnemy(kind:.koopa,     tx:121, ty:3)
        addEnemy(kind:.goomba,    tx:124, ty:3)
        addLauncher(tx:109, ty:2, dir:1,  interval:2.5)
        addLauncher(tx:127, ty:2, dir:-1, interval:2.3)

        // ── §8  Ascending staircase with Koopas ──
        addDeathPit(fromTx:126, toTx:130)
        for i in 0..<5 {
            addPlatform(tx:130+i*2, ty:0, tw:2, th:3+i)
        }
        addEnemy(kind:.koopa, tx:132, ty:5)
        addEnemy(kind:.koopa, tx:134, ty:6)
        addEnemy(kind:.koopa, tx:136, ty:7)
        // Descent
        for i in 0..<5 {
            addPlatform(tx:140+i*2, ty:0, tw:2, th:7-i)
        }
        addEnemy(kind:.hammerBro, tx:148, ty:3)

        // ── §9  Final death corridor — single-tile platforms ──
        addDeathPit(fromTx:150, toTx:175)
        addPlatform(tx:150, ty:0, tw:1, th:3)  // 1-tile wide
        // 2-tile gap
        addPlatform(tx:153, ty:0, tw:1, th:3)
        addEnemy(kind:.goomba, tx:153, ty:3)
        // 2-tile gap
        addPlatform(tx:156, ty:0, tw:1, th:3)
        // 2-tile gap
        addPlatform(tx:159, ty:0, tw:1, th:3)
        addEnemy(kind:.goomba, tx:159, ty:3)
        // 2-tile gap
        addPlatform(tx:162, ty:0, tw:2, th:3)
        addEnemy(kind:.hammerBro, tx:162, ty:3)
        // 2-tile gap
        addPlatform(tx:165, ty:0, tw:2, th:3)
        addEnemy(kind:.hammerBro, tx:166, ty:3)
        addLauncher(tx:148, ty:3, dir:1, interval:2.0)   // rapid fire

        // ── GOAL ──
        addDeathPit(fromTx:167, toTx:171)
        addPlatform(tx:171, ty:0, tw:8, th:3)
        addGoal(tx:175)
    }

    // MARK: - Player spawn
    func spawnPlayer() {
        if player == nil {
            player = SKSpriteNode(texture: makeMarioTex(),
                                   size: CGSize(width: T, height: T * 1.5))
            player.name = "player"
            let pb = SKPhysicsBody(rectangleOf: CGSize(width: T - 4, height: T * 1.5 - 4))
            pb.allowsRotation = false
            pb.categoryBitMask = catPlayer
            pb.contactTestBitMask = catGround | catEnemy | catProjectile | catGoal | catKill
            pb.collisionBitMask = catGround
            pb.linearDamping = 0
            pb.restitution = 0
            pb.friction = 0.5
            player.physicsBody = pb
            worldNode.addChild(player)
        }
        player.position = CGPoint(x: T * 2, y: groundY + T * 5)
        player.physicsBody?.velocity = .zero
        isOnGround = false
        holdL = false; holdR = false; holdJump = false; holdRun = false
        jumpHeld = 0
        player.alpha = 1
    }

    // MARK: - HUD
    func setupHUD() {
        // Background strip
        let bar = SKSpriteNode(color: UIColor(white: 0, alpha: 0.55),
                               size: CGSize(width: 390, height: 44))
        bar.position = CGPoint(x: 0, y: 844/2 - 22)
        bar.zPosition = 10
        hudNode.addChild(bar)

        let style: (SKLabelNode) -> Void = { lbl in
            lbl.fontName = "Courier-Bold"
            lbl.fontSize = 16
            lbl.fontColor = .white
            lbl.zPosition = 11
        }

        lblLives = SKLabelNode(text: "❤️ 3")
        lblLives.position = CGPoint(x: -150, y: 844/2 - 32)
        style(lblLives)
        hudNode.addChild(lblLives)

        lblScore = SKLabelNode(text: "SCORE:0")
        lblScore.position = CGPoint(x: 0, y: 844/2 - 32)
        style(lblScore)
        hudNode.addChild(lblScore)

        lblTimer = SKLabelNode(text: "TIME:75")
        lblTimer.position = CGPoint(x: 150, y: 844/2 - 32)
        style(lblTimer)
        hudNode.addChild(lblTimer)

        lblMsg = SKLabelNode(text: "")
        lblMsg.fontName = "Courier-Bold"
        lblMsg.fontSize = 28
        lblMsg.fontColor = .yellow
        lblMsg.zPosition = 20
        lblMsg.position = CGPoint(x: 0, y: 0)
        hudNode.addChild(lblMsg)
    }

    // MARK: - Controls (virtual D-pad)
    func setupControls() {
        // Button geometry: bottom of screen
        let bY: CGFloat = -844/2 + 60
        let btnSize: CGFloat = 64

        func makeBtn(_ label: String, x: CGFloat, y: CGFloat, color: UIColor) -> SKShapeNode {
            let n = SKShapeNode(rectOf: CGSize(width: btnSize, height: btnSize), cornerRadius: 12)
            n.fillColor = color.withAlphaComponent(0.55)
            n.strokeColor = UIColor.white.withAlphaComponent(0.7)
            n.lineWidth = 2
            n.position = CGPoint(x: x, y: y)
            n.zPosition = 15
            let lbl = SKLabelNode(text: label)
            lbl.fontName = "Courier-Bold"
            lbl.fontSize = 22
            lbl.fontColor = .white
            lbl.verticalAlignmentMode = .center
            n.addChild(lbl)
            hudNode.addChild(n)
            return n
        }

        btnL = makeBtn("◀", x: -390/2 + 44, y: bY, color: .gray)
        btnR = makeBtn("▶", x: -390/2 + 116, y: bY, color: .gray)
        btnB = makeBtn("B", x: 390/2 - 116, y: bY, color: UIColor(red:0.7,green:0.2,blue:0.7,alpha:1))
        btnA = makeBtn("A", x: 390/2 - 44, y: bY, color: UIColor(red:0.8,green:0.1,blue:0.1,alpha:1))
    }

    // MARK: - Touch input
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if gState == .gameOver {
            lives = 3
            score = 0
            timeLeft = 75
            hudNode.childNode(withName: "retryLabel")?.removeFromParent()
            restartLevel()
            return
        }
        for t in touches {
            let pt = t.location(in: hudNode)
            if btnL.contains(pt)       { touchMap[t] = "L"; holdL = true }
            else if btnR.contains(pt)  { touchMap[t] = "R"; holdR = true }
            else if btnA.contains(pt)  { touchMap[t] = "A"; holdJump = true }
            else if btnB.contains(pt)  { touchMap[t] = "B"; holdRun = true }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            switch touchMap[t] {
            case "L": holdL = false
            case "R": holdR = false
            case "A": holdJump = false; jumpHeld = 0
            case "B": holdRun = false
            default: break
            }
            touchMap.removeValue(forKey: t)
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }

    // MARK: - Physics contact
    func didBegin(_ contact: SKPhysicsContact) {
        let a = contact.bodyA; let b = contact.bodyB
        let combo = a.categoryBitMask | b.categoryBitMask

        // Player hits kill zone
        if combo == (catPlayer | catKill) {
            triggerDeath()
            return
        }

        // Player touches ground → on ground
        if combo == (catPlayer | catGround) {
            let normal = contact.contactNormal
            if normal.dy > 0.5 {
                isOnGround = true
            }
        }

        // Player hits enemy
        if combo == (catPlayer | catEnemy) {
            let playerBody = (a.categoryBitMask == catPlayer) ? a : b
            let enemyBody  = (a.categoryBitMask == catEnemy)  ? a : b
            let vel = playerBody.velocity
            if vel.dy < -80 {
                // Stomp
                if let eNode = enemyBody.node as? SKSpriteNode {
                    eNode.run(SKAction.sequence([
                        SKAction.scaleY(to: 0.1, duration: 0.05),
                        SKAction.removeFromParent()
                    ]))
                    enemies.removeValue(forKey: eNode)
                }
                playerBody.applyImpulse(CGVector(dx: 0, dy: 8))
                score += 100
            } else {
                triggerDeath()
            }
            return
        }

        // Player hit by projectile
        if combo == (catPlayer | catProjectile) {
            triggerDeath()
            return
        }

        // Player reaches goal
        if combo == (catPlayer | catGoal) {
            triggerWin()
            return
        }
    }

    // MARK: - Death / win
    func triggerDeath() {
        guard gState == .playing else { return }
        gState = .dying
        deathTimer = 0
        lives -= 1
        player.physicsBody?.velocity = CGVector(dx: 0, dy: 14)
        player.physicsBody?.affectedByGravity = true
        player.run(SKAction.sequence([
            SKAction.colorize(with: .red, colorBlendFactor: 1, duration: 0.05),
            SKAction.wait(forDuration: 0.1),
            SKAction.colorize(with: .white, colorBlendFactor: 0, duration: 0.05),
        ]))
        lblMsg.text = lives > 0 ? "MISS!" : "GAME OVER"
        lblMsg.fontColor = lives > 0 ? .yellow : .red
    }

    func triggerWin() {
        guard gState == .playing else { return }
        gState = .won
        lblMsg.text = "CLEAR!!"
        lblMsg.fontColor = UIColor(red: 0.3, green: 1.0, blue: 0.3, alpha: 1)
        player.physicsBody?.velocity = .zero
        player.physicsBody?.isDynamic = false
        let celebrate = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 20, duration: 0.2),
            SKAction.moveBy(x: 0, y: -20, duration: 0.2),
        ])
        player.run(SKAction.repeat(celebrate, count: 5))
    }

    // MARK: - Restart
    func restartLevel() {
        // Tear down world completely and rebuild
        player?.removeFromParent()
        player = nil
        worldNode.removeAllChildren()

        bullets.removeAll()
        hammers.removeAll()
        launchers.removeAll()
        movPlats.removeAll()
        fireBars.removeAll()
        enemies.removeAll()
        piranhas.removeAll()

        buildLevel()
        spawnPlayer()
        gState = .playing
        timeLeft = 75
        lblMsg.text = ""
        isOnGround = false
        holdL = false; holdR = false; holdJump = false; holdRun = false
        jumpHeld = 0
    }

    // MARK: - Update loop
    override func update(_ currentTime: TimeInterval) {
        let dt: Double
        if lastUpdate == 0 { dt = 0.016 } else { dt = min(currentTime - lastUpdate, 0.05) }
        lastUpdate = currentTime

        guard gState != .won else { return }

        if gState == .dying {
            deathTimer += dt
            if deathTimer > 2.0 {
                if lives <= 0 {
                    gState = .gameOver
                    showGameOver()
                } else {
                    restartLevel()
                }
            }
            return
        }

        if gState == .gameOver { return }

        // ── Timer ──
        timeLeft -= dt
        if timeLeft <= 0 {
            timeLeft = 0
            triggerDeath()
        }
        let t = Int(ceil(timeLeft))
        lblTimer.text = "TIME:\(t)"
        lblTimer.fontColor = t < 15 ? .red : .white

        // ── Player movement ──
        updatePlayer(dt: dt)

        // ── Camera ──
        let camX = max(195, player.position.x)
        cameraNode.position = CGPoint(x: camX, y: 422)

        // ── Moving platforms ──
        for i in 0..<movPlats.count {
            var mp = movPlats[i]
            if mp.vertical {
                let step = CGFloat(mp.goPos ? 1 : -1) * mp.speed * CGFloat(dt)
                mp.node.position.y += step
                if mp.node.position.y >= mp.maxY { mp.goPos = false }
                if mp.node.position.y <= mp.minY { mp.goPos = true }
            } else {
                let step = CGFloat(mp.goPos ? 1 : -1) * mp.speed * CGFloat(dt)
                mp.node.position.x += step
                if mp.node.position.x >= mp.maxX { mp.goPos = false }
                if mp.node.position.x <= mp.minX { mp.goPos = true }
            }
            // Sync physics body
            mp.node.physicsBody?.velocity = .zero
            movPlats[i] = mp
        }

        // ── Fire bars ──
        for i in 0..<fireBars.count {
            fireBars[i].angle += fireBars[i].speed * CGFloat(dt)
            fireBars[i].pivot.zRotation = fireBars[i].angle
        }

        // ── Bullet bill launchers ──
        for i in 0..<launchers.count {
            let gap = currentTime - launchers[i].last
            if gap >= launchers[i].interval {
                launchers[i].last = currentTime
                fireBullet(from: launchers[i].node.position, dir: launchers[i].dir)
            }
        }

        // ── Update bullets (remove off-screen) ──
        bullets = bullets.filter { b in
            if b.position.x < cameraNode.position.x - 250 ||
               b.position.x > cameraNode.position.x + 250 {
                b.removeFromParent(); return false
            }
            return b.parent != nil
        }

        // ── Hammers ──
        hammers = hammers.filter { h in
            if h.parent == nil { return false }
            if h.position.y < groundY - T * 3 { h.removeFromParent(); return false }
            return true
        }

        // ── Enemy AI ──
        updateEnemies(dt: dt, currentTime: currentTime)

        // ── Piranha plants ──
        updatePiranhas(dt: dt)

        // ── HUD ──
        lblLives.text = "❤ \(lives)"
        lblScore.text = "SCORE:\(score)"
    }

    // MARK: - Player physics update
    func updatePlayer(dt: Double) {
        guard let pb = player.physicsBody else { return }

        let speed = holdRun ? runSpeed : walkSpeed
        var vx: CGFloat = 0

        if holdL { vx = -speed; player.xScale = -1 }
        if holdR { vx =  speed; player.xScale =  1 }

        // Keep horizontal momentum, just override with input
        pb.velocity.dx = vx

        // Jump: only when on ground
        if holdJump {
            if isOnGround && jumpHeld == 0 {
                // Initial jump
                let jvel: CGFloat = holdRun ? 20 : 17
                pb.velocity = CGVector(dx: pb.velocity.dx, dy: jvel)
                isOnGround = false
                jumpHeld = dt
            } else if jumpHeld > 0 && jumpHeld < 0.25 {
                // Variable jump height — extend upward force while held
                pb.applyForce(CGVector(dx: 0, dy: pb.mass * 200))
                jumpHeld += dt
            }
        } else {
            jumpHeld = 0
        }

        // Cap fall speed
        if pb.velocity.dy < maxFallSpeed {
            pb.velocity.dy = maxFallSpeed
        }

        // Reset ground state (re-check each frame via contact)
        if pb.velocity.dy > 0.5 { isOnGround = false }
    }

    // MARK: - Enemy AI
    func updateEnemies(dt: Double, currentTime: TimeInterval) {
        var toRemove: [SKSpriteNode] = []
        for (node, var data) in enemies {
            guard node.parent != nil else { toRemove.append(node); continue }

            // Off screen far left → remove
            if node.position.x < cameraNode.position.x - 400 {
                toRemove.append(node); node.removeFromParent(); continue
            }

            switch data.kind {
            case .goomba, .koopa:
                // Walk patrol
                let spd: CGFloat = data.kind == .koopa ? 55 : 45
                let vx = data.facingRight ? spd : -spd
                node.physicsBody?.velocity.dx = vx
                node.xScale = data.facingRight ? 1 : -1
                // Reverse direction at edges (simple: reverse every 3s based on x drift)
                // Actually use velocity-based detection: if x hasn't changed, reverse
                if let v = node.physicsBody?.velocity, abs(v.dx) < 5 {
                    data.facingRight = !data.facingRight
                }

            case .hammerBro:
                // Stand still, throw hammers periodically
                node.physicsBody?.velocity.dx = 0
                data.shootTimer -= dt
                if data.shootTimer <= 0 {
                    data.shootTimer = 1.2   // throw every 1.2 seconds — very fast
                    throwHammers(from: node.position)
                }
                // Face player
                data.facingRight = player.position.x > node.position.x
                node.xScale = data.facingRight ? 1 : -1
            }
            enemies[node] = data
        }
        for n in toRemove { enemies.removeValue(forKey: n) }
    }

    func throwHammers(from pos: CGPoint) {
        // Throw 3 hammers in a spread pattern
        let angles: [CGFloat] = [.pi * 0.25, .pi * 0.4, .pi * 0.55]
        let facingRight = player.position.x > pos.x
        for angle in angles {
            let h = SKSpriteNode(texture: makeHammerTex(),
                                  size: CGSize(width: 14, height: 18))
            h.position = pos
            let speed: CGFloat = 220
            let vx = facingRight ? cos(angle) * speed : -cos(angle) * speed
            let vy = sin(angle) * speed
            let pb = SKPhysicsBody(rectangleOf: CGSize(width: 10, height: 14))
            pb.categoryBitMask = catProjectile
            pb.contactTestBitMask = catPlayer
            pb.collisionBitMask = 0
            pb.velocity = CGVector(dx: vx, dy: vy)
            pb.linearDamping = 0
            h.physicsBody = pb
            h.name = "hammer"
            // Spin animation
            h.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: 0.3)))
            worldNode.addChild(h)
            hammers.append(h)
        }
    }

    func fireBullet(from pos: CGPoint, dir: CGFloat) {
        let b = SKSpriteNode(texture: makeBulletTex(),
                              size: CGSize(width: 22, height: 18))
        b.position = pos
        b.name = "bullet"
        b.xScale = dir > 0 ? 1 : -1
        let pb = SKPhysicsBody(rectangleOf: CGSize(width: 18, height: 14))
        pb.categoryBitMask = catProjectile
        pb.contactTestBitMask = catPlayer
        pb.collisionBitMask = 0
        pb.velocity = CGVector(dx: dir * 220, dy: 0)
        pb.linearDamping = 0
        pb.affectedByGravity = false
        b.physicsBody = pb
        worldNode.addChild(b)
        bullets.append(b)
    }

    // MARK: - Piranha plants
    func updatePiranhas(dt: Double) {
        for i in 0..<piranhas.count {
            piranhas[i].timer += dt
            let cycleLen: Double = 2.5   // total cycle duration
            let showLen:  Double = 1.8   // time visible (danger window)
            let phase = piranhas[i].timer.truncatingRemainder(dividingBy: cycleLen)

            let shouldShow = phase < showLen
            if shouldShow != piranhas[i].showing {
                piranhas[i].showing = shouldShow
                let node = piranhas[i].node
                // base is fully up, base - height is hidden
                let topY = piranhas[i].base
                let hideY = topY - node.size.height * 2
                let targetY = shouldShow ? topY : hideY
                node.run(SKAction.moveTo(y: targetY, duration: 0.25))
            }
        }
    }

    // MARK: - Game over screen
    func showGameOver() {
        lblMsg.text = "GAME OVER"
        lblMsg.fontColor = .red

        let sub = SKLabelNode(text: "Tap to retry")
        sub.fontName = "Courier-Bold"
        sub.fontSize = 20
        sub.fontColor = .white
        sub.position = CGPoint(x: 0, y: -40)
        sub.name = "retryLabel"
        sub.zPosition = 20
        hudNode.addChild(sub)
    }

}
