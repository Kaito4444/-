import UIKit
import SpriteKit

// MARK: - Physics Bitmasks
struct PC {
    static let player:  UInt32 = 1 << 0  // 1
    static let solid:   UInt32 = 1 << 1  // 2  ground/stone/crumbling (while solid)
    static let enemy:   UInt32 = 1 << 2  // 4
    static let hazard:  UInt32 = 1 << 3  // 8  spikes, death floor
    static let goal:    UInt32 = 1 << 4  // 16
    static let movPlat: UInt32 = 1 << 5  // 32 moving / vanishing platforms
}

// MARK: - Scene / World Dimensions
let kTile:    CGFloat = 40   // pixels per tile
let kSceneW:  CGFloat = 812  // scene reference width  (landscape)
let kSceneH:  CGFloat = 375  // scene reference height

// MARK: - Physics Tuning
let kGravity:    CGFloat = -22
let kJumpVel:    CGFloat = 16.5   // initial jump velocity (physics units)
let kJumpExtra:  CGFloat = 360    // extra force while holding jump (per frame)
let kMaxJumpHold: Double = 0.26   // seconds of variable-height window
let kWalkSpeed:  CGFloat = 190
let kMaxFall:    CGFloat = -700

// MARK: - Game Rules
let kTimeLimit: Double = 90   // seconds per stage

// MARK: - Dark Fantasy Palette
extension UIColor {
    static let abyssBg        = UIColor(red: 0.05,  green: 0.02, blue: 0.12, alpha: 1)
    static let abyssBgTop     = UIColor(red: 0.09,  green: 0.04, blue: 0.20, alpha: 1)
    static let abyssGround    = UIColor(red: 0.235, green: 0.235, blue: 0.27, alpha: 1)
    static let abyssGroundEdge = UIColor(red: 0.30, green: 0.30, blue: 0.35, alpha: 1)
    static let abyssStone     = UIColor(red: 0.17,  green: 0.17, blue: 0.21, alpha: 1)
    static let abyssCrumble   = UIColor(red: 0.43,  green: 0.28, blue: 0.13, alpha: 1)
    static let abyssVanish    = UIColor(red: 0.36,  green: 0.10, blue: 0.54, alpha: 1)
    static let abyssVanishGlow = UIColor(red: 0.65, green: 0.25, blue: 0.95, alpha: 0.8)
    static let abyssSpikeTip  = UIColor(red: 0.88,  green: 0.10, blue: 0.10, alpha: 1)
    static let abyssSpikeBase = UIColor(red: 0.20,  green: 0.20, blue: 0.23, alpha: 1)
    static let abyssGoal      = UIColor(red: 0.98,  green: 0.82, blue: 0.12, alpha: 1)
    static let abyssGoalGlow  = UIColor(red: 1.00,  green: 0.95, blue: 0.50, alpha: 1)
    static let abyssPlayer    = UIColor(red: 0.25,  green: 0.68, blue: 1.00, alpha: 1)
    static let abyssPlayerDark = UIColor(red: 0.12, green: 0.40, blue: 0.75, alpha: 1)
    static let abyssEnemy     = UIColor(red: 0.82,  green: 0.12, blue: 0.12, alpha: 1)
    static let abyssEnemyEye  = UIColor(red: 1.00,  green: 0.85, blue: 0.00, alpha: 1)
    static let abyssPlat      = UIColor(red: 0.18,  green: 0.52, blue: 0.30, alpha: 1)
    static let abyssPlatEdge  = UIColor(red: 0.25,  green: 0.72, blue: 0.40, alpha: 1)
    static let abyssBtn       = UIColor(white: 1, alpha: 0.18)
    static let abyssBtnBorder = UIColor(white: 1, alpha: 0.50)
    static let abyssHUDText   = UIColor(white: 1, alpha: 0.92)
    static let abyssHUDBg     = UIColor(white: 0, alpha: 0.55)
    static let abyssDanger    = UIColor(red: 0.95, green: 0.20, blue: 0.20, alpha: 1)
}
