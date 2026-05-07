import SpriteKit
import UIKit

// MARK: - Pixel-art texture helper
// Palette codes: O=clear W=white K=black B=blue b=dark-blue R=red r=dark-red
//  G=gray N=dark-gray S=brown(stone) P=purple Y=yellow E=green X=orange
func pxTex(_ rows: [String], s: Int = 3) -> SKTexture {
    let pal: [Character: UIColor] = [
        "W": .white,
        "K": .black,
        "B": .abyssPlayer,
        "b": .abyssPlayerDark,
        "R": .abyssEnemy,
        "r": UIColor(red: 0.55, green: 0.05, blue: 0.05, alpha: 1),
        "G": .abyssGround,
        "N": .abyssStone,
        "S": .abyssCrumble,
        "P": .abyssVanish,
        "Y": .abyssGoal,
        "E": .abyssPlat,
        "e": .abyssPlatEdge,
        "X": .abyssSpikeTip,
        "x": UIColor(red: 0.55, green: 0.05, blue: 0.05, alpha: 1),
        "Z": .abyssSpikeBase,
        "Q": .abyssEnemyEye,
    ]
    let cols = rows.reduce(0) { max($0, $1.count) }
    let rws  = rows.count
    let iw = cols * s
    let ih = rws  * s
    guard iw > 0, ih > 0 else { return SKTexture() }
    let renderer = UIGraphicsImageRenderer(size: CGSize(width: iw, height: ih))
    let img = renderer.image { ctx in
        let g = ctx.cgContext
        for (ri, row) in rows.enumerated() {
            for (ci, ch) in row.enumerated() {
                guard ch != "O", let col = pal[ch] else { continue }
                g.setFillColor(col.cgColor)
                g.fill(CGRect(x: ci*s, y: ri*s, width: s, height: s))
            }
        }
    }
    return SKTexture(image: img)
}

// MARK: - Sprite Texture Library
enum Tex {

    // Player: 8×12 px (scale 3 → 24×36 pt)
    static let playerIdle = pxTex([
        "OOBBBBBOO",
        "OBWBBBWBO",
        "OBBBBBBBО",
        "ObbbBbbbo",
        "OBBBbBBBO",
        "OBBBbBBBO",
        "OBBBbBBBO",
        "OObBBBbOO",
        "OObBBBbOO",
        "OObbObbOO",
        "OObbObbOO",
        "OObbObbOO",
    ], s: 3)

    static let playerRun = pxTex([
        "OOBBBBBOO",
        "OBWBBBWBO",
        "OBBBBBBBО",
        "ObbbBbbbo",
        "BBBBbBBBB",
        "OBBBbBBBO",
        "OBBBbBBBO",
        "OObBBBbOO",
        "OObBbBOOO",
        "OObbOOOOO",
        "OObbOOOOO",
        "ObbOOOOOO",
    ], s: 3)

    // Enemy: 8×10 px (scale 3 → 24×30 pt)
    static let enemyA = pxTex([
        "RrOOOOOOrR",
        "rRROOOORRr",
        "ORRRRRRRRO",
        "ORRQORRQRO",
        "ORRRRRRRRО",
        "ORRrrrRRRO",
        "ORRRRRRRRО",
        "ORRRRRRRRО",
        "OrRROORRrO",
        "OrrROORrrO",
    ], s: 3)

    static let enemyB = pxTex([
        "rROOOOOrR",
        "RRROOORRR",
        "ORRQOQRRO",
        "ORRRRRRRО",
        "ORrRRRrRO",
        "ORRRRRRRO",
        "ORrRrRrRO",
        "OrROORRrO",
        "OrrOOrrOO",
    ], s: 3)

    // Ground block tile: 8×8 (scale 5 → 40×40 pt)
    static let blockGround = pxTex([
        "GGGGGGGG",
        "GNNGGNNG",
        "GGGGGGGGG",
        "GGGGGGGG",
        "GNNGGNNG",
        "GGGGGGGGG",
        "GGGGGGGG",
        "GNNGGNNG",
    ], s: 5)

    // Stone block
    static let blockStone = pxTex([
        "NNNNNNNN",
        "NKKNKNKN",
        "NNNNNNNN",
        "NKKNKNKN",
        "NNNNNNNN",
        "NKNKNKKN",
        "NNNNNNNN",
        "NKNKNKKN",
    ], s: 5)

    // Crumbling block
    static let blockCrumble = pxTex([
        "SSSSSSSS",
        "SSSKSSS",
        "SKSSSKSS",
        "SKSSKSSS",
        "SSSSKSSS",
        "SKSSSKSS",
        "SSSSSSSK",
        "SKSSSSSS",
    ], s: 5)

    // Vanishing block (bright purple)
    static let blockVanish = pxTex([
        "PPPPPPPP",
        "PWWPPPWP",
        "PPWPPWPP",
        "PPPPPPPP",
        "PPWPPWPP",
        "PPWPPPWP",
        "PPPPPPPP",
        "PWPPPPWP",
    ], s: 5)

    // Moving platform: 3×1 tile rendered as 3×8 px
    static let platMoving = pxTex([
        "eeeeeeeeeeeeee",
        "EEEEEEEEEEEEEE",
        "EEEEEEEEEEEEEE",
        "EEEEEEEEEEEEEE",
        "EEEEEEEEEEEEEE",
        "EEEEeeEEEEeeEE",
        "EEEEEEEEEEEEEE",
        "eeeeeeeeeeeeee",
    ], s: 5)

    // Goal flag + pole (just the flag; pole is separate node)
    static let goalFlag = pxTex([
        "YYYYYYYY",
        "YYYYYY",
        "YYYY",
        "YY",
    ], s: 5)

    // Spike (single spike unit, 1×1 tile): triangle via px array
    static let spikeUnit = pxTex([
        "OOOOXOOO",
        "OOOXOOOO",
        "OOOXXXOO",
        "OOXXXOOO",
        "OXXXXOOO",
        "OXXXXXXO",
        "XXXXXXXO",
        "ZZZZZZZZ",
    ], s: 5)
}
