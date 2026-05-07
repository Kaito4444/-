import SpriteKit

final class TitleScene: SKScene {

    override func didMove(to view: SKView) {
        backgroundColor = .abyssBg
        buildTitle()
        buildAtmosphere()
    }

    // MARK: - Title elements
    private func buildTitle() {
        // Dark gradient sky
        let sky = SKSpriteNode(color: .abyssBgTop, size: CGSize(width: kSceneW, height: kSceneH * 0.6))
        sky.position = CGPoint(x: kSceneW / 2, y: kSceneH * 0.7)
        addChild(sky)

        // Title text with glow effect
        let titleShadow = SKLabelNode(text: "ABYSS RUN")
        titleShadow.fontName = "AvenirNext-Bold"
        titleShadow.fontSize = 58
        titleShadow.fontColor = UIColor(red: 0.5, green: 0, blue: 0.8, alpha: 0.6)
        titleShadow.position = CGPoint(x: kSceneW / 2 + 3, y: kSceneH * 0.62 - 3)
        addChild(titleShadow)

        let title = SKLabelNode(text: "ABYSS RUN")
        title.fontName = "AvenirNext-Bold"
        title.fontSize = 58
        title.fontColor = UIColor(red: 0.75, green: 0.35, blue: 1.0, alpha: 1)
        title.position = CGPoint(x: kSceneW / 2, y: kSceneH * 0.62)
        addChild(title)

        // Subtitle
        let sub = SKLabelNode(text: "〜 死にゲー・鬼畜プラットフォーマー 〜")
        sub.fontName = "HiraginoSans-W3"
        sub.fontSize = 14
        sub.fontColor = UIColor(white: 0.65, alpha: 1)
        sub.position = CGPoint(x: kSceneW / 2, y: kSceneH * 0.52)
        addChild(sub)

        // Tap to start — blinking
        let tapLabel = SKLabelNode(text: "TAP TO START")
        tapLabel.fontName = "Courier-Bold"
        tapLabel.fontSize = 22
        tapLabel.fontColor = .abyssGoal
        tapLabel.position = CGPoint(x: kSceneW / 2, y: kSceneH * 0.35)
        addChild(tapLabel)
        tapLabel.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.2, duration: 0.6),
            SKAction.fadeAlpha(to: 1.0, duration: 0.6),
        ])))

        // Controls hint
        let hint1 = SKLabelNode(text: "◀ ▶  移動    JUMP  ジャンプ（長押しで高く）")
        hint1.fontName = "Courier"
        hint1.fontSize = 13
        hint1.fontColor = UIColor(white: 0.55, alpha: 1)
        hint1.position = CGPoint(x: kSceneW / 2, y: kSceneH * 0.22)
        addChild(hint1)

        let hint2 = SKLabelNode(text: "敵の上から踏むと倒せる　横から触れると即死")
        hint2.fontName = "HiraginoSans-W3"
        hint2.fontSize = 13
        hint2.fontColor = UIColor(white: 0.55, alpha: 1)
        hint2.position = CGPoint(x: kSceneW / 2, y: kSceneH * 0.14)
        addChild(hint2)

        // Ground floor decoration
        let ground = SKSpriteNode(color: .abyssGround,
                                  size: CGSize(width: kSceneW, height: kTile))
        ground.position = CGPoint(x: kSceneW / 2, y: kTile / 2)
        addChild(ground)

        // Mini player sprite on title screen
        let miniPlayer = SKSpriteNode(texture: Tex.playerIdle,
                                       size: CGSize(width: 24, height: 36))
        miniPlayer.position = CGPoint(x: kSceneW * 0.15, y: kTile + 18)
        addChild(miniPlayer)
        let bounce = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 8, duration: 0.35),
            SKAction.moveBy(x: 0, y: -8, duration: 0.35),
        ])
        miniPlayer.run(SKAction.repeatForever(bounce))

        // Mini enemy on title
        let miniEnemy = SKSpriteNode(texture: Tex.enemyA,
                                      size: CGSize(width: 24, height: 30))
        miniEnemy.position = CGPoint(x: kSceneW * 0.85, y: kTile + 15)
        addChild(miniEnemy)
        let walk = SKAction.sequence([
            SKAction.moveBy(x: -30, y: 0, duration: 0.6),
            SKAction.scaleX(to: -1, duration: 0),
            SKAction.moveBy(x:  30, y: 0, duration: 0.6),
            SKAction.scaleX(to:  1, duration: 0),
        ])
        miniEnemy.run(SKAction.repeatForever(walk))
    }

    // MARK: - Atmosphere
    private func buildAtmosphere() {
        // Stars
        for _ in 0..<60 {
            let star = SKSpriteNode(color: UIColor(white: 1, alpha: CGFloat.random(in: 0.3...0.9)),
                                    size: CGSize(width: 2, height: 2))
            star.position = CGPoint(x: CGFloat.random(in: 0...kSceneW),
                                     y: CGFloat.random(in: kSceneH * 0.4...kSceneH))
            star.zPosition = -5
            addChild(star)
            star.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.1, duration: CGFloat.random(in: 0.8...2.0)),
                SKAction.fadeAlpha(to: 0.9, duration: CGFloat.random(in: 0.8...2.0)),
            ])))
        }
    }

    // MARK: - Touch → start game
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let gameScene = GameScene(size: size)
        gameScene.scaleMode = scaleMode
        view?.presentScene(gameScene, transition: .fade(withDuration: 0.6))
    }
}
