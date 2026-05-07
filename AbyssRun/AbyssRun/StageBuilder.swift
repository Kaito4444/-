import SpriteKit

// MARK: - Tile placement descriptor
struct TileDef {
    let type: BlockType
    let col: Int   // column in section-local coords
    let row: Int   // 0 = ground floor
    let width: Int
    init(_ type: BlockType, _ col: Int, _ row: Int, w: Int = 1) {
        self.type = type; self.col = col; self.row = row; self.width = w
    }
}

struct EnemyDef {
    let col: Int
    let row: Int       // top of block the enemy stands on
    let rangeL: Int    // patrol range left (section-local cols)
    let rangeR: Int    // patrol range right
    let speed: CGFloat
    init(_ col: Int, _ row: Int, l: Int, r: Int, spd: CGFloat = 80) {
        self.col=col; self.row=row; rangeL=l; rangeR=r; speed=spd
    }
}

// One section of the stage (~15-22 tiles wide)
struct SectionDef {
    let width: Int           // tile-columns wide
    let tiles: [TileDef]
    let enemies: [EnemyDef]

    // Moving platform config (if any): anchorCol, anchorRow, rangeMin(local col), rangeMax(local col), speed, vertical
    struct MovPlatDef {
        let col: Int; let row: Int; let w: Int
        let min: Int; let max: Int
        let speed: CGFloat; let vertical: Bool
        init(_ col: Int, _ row: Int, w: Int=3, min: Int, max: Int, spd: CGFloat=65, v: Bool=false){
            self.col=col; self.row=row; self.w=w
            self.min=min; self.max=max; speed=spd; vertical=v
        }
    }
    let movPlats: [MovPlatDef]
}

// MARK: - Section Library
//   Ground row = row 0 in section coords. Actual world row depends on groundRow offset.
//   "row" in TileDef is relative: 0=floor, 1=1 tile above floor, etc.

private let groundH = 3  // ground blocks stacked 3 tiles high (rows 0,1,2)

// Floor tiles helper
private func floor(_ c: Int, _ w: Int = 1) -> TileDef { TileDef(.ground, c, 0, w: w) }
private func floor2(_ c: Int, _ w: Int = 1) -> TileDef { TileDef(.ground, c, 1, w: w) }
private func floor3(_ c: Int, _ w: Int = 1) -> TileDef { TileDef(.ground, c, 2, w: w) }

// Helper to make a 1-col-wide ground stack 3 tiles tall
private func groundStack(_ c: Int) -> [TileDef] {
    [floor(c), floor2(c), floor3(c)]
}
private func groundStacks(_ cols: [Int]) -> [TileDef] {
    cols.flatMap { groundStack($0) }
}

// MARK: - Tutorial Section (always first, col offset = 0)
let sectionTutorial = SectionDef(
    width: 22,
    tiles: groundStacks(Array(0..<6))          // 6 tiles of solid start
         + groundStacks(Array(8..<14))         // gap at col 6-7
         + groundStacks(Array(14..<20))        // platform continues
         + [TileDef(.stone, 3, 3),             // hint block above start
            TileDef(.spike, 6, 3),             // SPIKE in the gap (falls in = die)
            TileDef(.spike, 7, 3)],
    enemies: [EnemyDef(11, 3, l: 9, r: 13)],  // one goomba to practice stomp
    movPlats: []
)

// MARK: - Random Section Templates (6-7, pick 5 in random order)

// S1: Gap + spike corridor
let sectionGaps = SectionDef(
    width: 20,
    tiles: groundStacks(Array(0..<4))
         + groundStacks(Array(7..<10))
         + groundStacks(Array(13..<16))
         + groundStacks(Array(19..<20))
         + [TileDef(.spike, 4, 3), TileDef(.spike, 5, 3), TileDef(.spike, 6, 3),  // pit 1 spikes
            TileDef(.spike, 10, 3), TileDef(.spike, 11, 3), TileDef(.spike, 12, 3)], // pit 2
    enemies: [EnemyDef(8, 3, l: 7, r: 9), EnemyDef(14, 3, l: 13, r: 15)],
    movPlats: []
)

// S2: Horizontal moving platforms over pit
let sectionMovH = SectionDef(
    width: 22,
    tiles: groundStacks(Array(0..<3))
         + groundStacks(Array(19..<22))
         + [TileDef(.spike, 3, 3), TileDef(.spike, 4, 3),
            TileDef(.spike, 15, 3), TileDef(.spike, 16, 3)],
    enemies: [EnemyDef(20, 3, l: 19, r: 21, spd: 60)],
    movPlats: [
        SectionDef.MovPlatDef(4, 4, w: 3, min: 3, max: 10, spd: 70),
        SectionDef.MovPlatDef(12, 5, w: 3, min: 10, max: 18, spd: 85),
    ]
)

// S3: Vertical moving platforms (上下) — hardest of moving sections
let sectionMovV = SectionDef(
    width: 20,
    tiles: groundStacks(Array(0..<2))
         + groundStacks(Array(18..<20))
         + [TileDef(.stone, 8, 4), TileDef(.stone, 9, 4),   // mid-height solid platform
            TileDef(.spike, 2, 3), TileDef(.spike, 16, 3)],  // spike pits
    enemies: [EnemyDef(9, 5, l: 8, r: 10)],
    movPlats: [
        SectionDef.MovPlatDef(4, 3, w: 2, min: 3, max: 7, spd: 75, v: true),   // up-down
        SectionDef.MovPlatDef(13, 6, w: 2, min: 2, max: 7, spd: 90, v: true),  // fast up-down
    ]
)

// S4: Crumbling bridge — sprint section
let sectionCrumble = SectionDef(
    width: 22,
    tiles: groundStacks(Array(0..<3))
         + groundStacks(Array(19..<22))
         + [TileDef(.crumble, 3, 3), TileDef(.crumble, 4, 3),
            TileDef(.crumble, 5, 3), TileDef(.crumble, 6, 3),
            TileDef(.crumble, 7, 3), TileDef(.crumble, 8, 3),
            TileDef(.crumble, 9, 3), TileDef(.crumble, 10, 3),
            TileDef(.crumble, 11, 3), TileDef(.crumble, 12, 3),
            // Mid-bridge stone island with enemy
            TileDef(.stone, 13, 3),
            TileDef(.crumble, 14, 3), TileDef(.crumble, 15, 3),
            TileDef(.crumble, 16, 3), TileDef(.crumble, 17, 3),
            TileDef(.crumble, 18, 3),
            // Spike pit below (z=-1 from ground = below the floor)
            TileDef(.spike, 3, -1), TileDef(.spike, 4, -1),
            TileDef(.spike, 5, -1), TileDef(.spike, 6, -1)],
    enemies: [EnemyDef(13, 4, l: 13, r: 13)],   // standing on stone island (no patrol)
    movPlats: []
)

// S5: Vanishing platforms
let sectionVanish2 = SectionDef(
    width: 22,
    tiles: groundStacks(Array(0..<2))
         + groundStacks(Array(20..<22))
         + [TileDef(.stone, 9, 5), TileDef(.stone, 10, 5),
            TileDef(.spike, 2, 3), TileDef(.spike, 12, 3),
            TileDef(.spike, 14, 3), TileDef(.spike, 19, 3),
            // Vanishing platforms
            TileDef(.vanish, 3,  4), TileDef(.vanish, 5,  4),
            TileDef(.vanish, 7,  4), TileDef(.vanish, 12, 3),
            TileDef(.vanish, 15, 3), TileDef(.vanish, 17, 3)],
    enemies: [EnemyDef(10, 6, l: 9, r: 11)],
    movPlats: []
)

// S6: Narrow-ledge enemy gauntlet — must stomp enemies or die
let sectionNarrow = SectionDef(
    width: 20,
    tiles: groundStacks(Array(0..<2))
         + groundStacks(Array(18..<20))
         + [// Narrow ledges at varying heights
            TileDef(.stone, 3, 3), TileDef(.stone, 3, 4),  // 1-wide high ledge
            TileDef(.stone, 6, 3),                          // 1-wide low ledge
            TileDef(.stone, 9, 4),
            TileDef(.stone, 12, 3), TileDef(.stone, 12, 4),
            TileDef(.stone, 15, 4),
            TileDef(.stone, 17, 3),
            TileDef(.spike, 4, 3), TileDef(.spike, 5, 3),
            TileDef(.spike, 7, 3), TileDef(.spike, 8, 3),
            TileDef(.spike, 10, 3), TileDef(.spike, 11, 3),
            TileDef(.spike, 13, 3), TileDef(.spike, 14, 3),
            TileDef(.spike, 16, 3)],
    enemies: [EnemyDef(3, 5, l: 3, r: 3),   // on ledge, stationary
              EnemyDef(9, 5, l: 9, r: 9),
              EnemyDef(15, 5, l: 15, r: 15, spd: 0)],
    movPlats: []
)

// Final Section — hardest combo, always last random section
let sectionFinal = SectionDef(
    width: 26,
    tiles: groundStacks(Array(0..<2))
         + groundStacks(Array(24..<26))
         + [// High stone platform series
            TileDef(.stone, 3, 4, w: 2), TileDef(.stone, 7, 5, w: 2),
            TileDef(.stone, 12, 4, w: 1), TileDef(.stone, 16, 3, w: 2),
            TileDef(.stone, 20, 4, w: 2), TileDef(.stone, 23, 3, w: 2),
            // Spikes in gaps
            TileDef(.spike, 2, 3), TileDef(.spike, 5, 3),
            TileDef(.spike, 6, 3), TileDef(.spike, 9, 3),
            TileDef(.spike, 10, 3), TileDef(.spike, 11, 3),
            TileDef(.spike, 13, 3), TileDef(.spike, 14, 3),
            TileDef(.spike, 15, 3), TileDef(.spike, 18, 3),
            TileDef(.spike, 19, 3), TileDef(.spike, 22, 3),
            // Crumbling approach
            TileDef(.crumble, 4, 3)],
    enemies: [EnemyDef(3,  5, l: 3,  r: 4,  spd: 90),
              EnemyDef(7,  6, l: 7,  r: 8,  spd: 95),
              EnemyDef(16, 4, l: 16, r: 17, spd: 80)],
    movPlats: [SectionDef.MovPlatDef(10, 5, w: 2, min: 9, max: 14, spd: 80)]
)

// Goal section (always appended last)
let sectionGoal = SectionDef(
    width: 8,
    tiles: groundStacks(Array(0..<8))
         + [TileDef(.goal, 5, 3)],   // goal block on top of ground
    enemies: [],
    movPlats: []
)

// MARK: - Stage Builder
struct StageBuilder {

    static let randomPool: [SectionDef] = [
        sectionGaps, sectionMovH, sectionMovV,
        sectionCrumble, sectionVanish2, sectionNarrow
    ]

    struct BuiltStage {
        var crumblingBlocks: [BlockNode] = []
        var vanishingBlocks: [BlockNode] = []
        var movingBlocks:    [BlockNode] = []
        var enemies:         [Enemy]    = []
        var stageWidth:      CGFloat    = 0
    }

    static func build(in world: SKNode,
                      groundRow: Int = 0) -> BuiltStage {
        var result = BuiltStage()

        // Assemble sections: tutorial + 5 random + final + goal
        var shuffled = randomPool.shuffled()
        if shuffled.count > 5 { shuffled = Array(shuffled.prefix(5)) }
        let sections = [sectionTutorial] + shuffled + [sectionFinal, sectionGoal]

        var colOffset = 2  // leave 2 cols empty at very start
        for section in sections {
            buildSection(section,
                         colOffset: colOffset,
                         groundRow: groundRow,
                         world: world,
                         result: &result)
            colOffset += section.width + 1  // 1-tile gap between sections
        }

        result.stageWidth = CGFloat(colOffset + 4) * kTile

        // Death floor (kill zone below stage)
        let floorW = result.stageWidth + 200
        let floor = SKSpriteNode(color: .clear,
                                 size: CGSize(width: floorW, height: kTile))
        floor.position = CGPoint(x: floorW / 2 - 100, y: -kTile * 3)
        floor.name = "killFloor"
        let fpb = SKPhysicsBody(rectangleOf: floor.size)
        fpb.isDynamic = false
        fpb.categoryBitMask    = PC.hazard
        fpb.contactTestBitMask = PC.player
        fpb.collisionBitMask   = 0
        floor.physicsBody = fpb
        world.addChild(floor)

        return result
    }

    // MARK: - Build one section
    private static func buildSection(_ sec: SectionDef,
                                     colOffset: Int,
                                     groundRow: Int,
                                     world: SKNode,
                                     result: inout BuiltStage) {
        let rowBase = groundRow

        // Place tiles
        for td in sec.tiles {
            let absCol = colOffset + td.col
            let absRow = rowBase  + td.row
            let block = BlockNode.make(type: td.type,
                                       col: absCol,
                                       row: absRow,
                                       width: td.width,
                                       in: world)
            switch td.type {
            case .crumble: result.crumblingBlocks.append(block)
            case .vanish:  result.vanishingBlocks.append(block)
            default: break
            }
        }

        // Place moving platforms
        for mp in sec.movPlats {
            let absCol = colOffset + mp.col
            let absRow = rowBase  + mp.row
            let block  = BlockNode.make(type: mp.vertical ? .movingV : .movingH,
                                        col: absCol,
                                        row: absRow,
                                        width: mp.w,
                                        in: world)
            block.movMin    = CGFloat(colOffset + mp.min) * kTile + block.size.width / 2
            block.movMax    = CGFloat(colOffset + mp.max) * kTile + block.size.width / 2
            if mp.vertical {
                let baseY       = CGFloat(absRow) * kTile + kTile / 2
                block.movMin    = baseY
                block.movMax    = baseY + CGFloat(mp.max - mp.min) * kTile
            }
            block.movSpeed  = mp.speed
            block.movGoingPos = Bool.random()
            result.movingBlocks.append(block)
        }

        // Place enemies
        for ed in sec.enemies {
            let absCol = colOffset + ed.col
            let absRow = rowBase  + ed.row
            let worldX = CGFloat(absCol) * kTile + kTile / 2
            let worldY = CGFloat(absRow) * kTile + kTile / 2 + 15  // offset above block top
            let patLeft  = CGFloat(colOffset + ed.rangeL) * kTile
            let patRight = CGFloat(colOffset + ed.rangeR) * kTile + kTile
            let enemy = Enemy.make(at: CGPoint(x: worldX, y: worldY),
                                   patrolLeft: patLeft,
                                   patrolRight: patRight,
                                   speed: ed.speed)
            world.addChild(enemy)
            result.enemies.append(enemy)
        }
    }
}
