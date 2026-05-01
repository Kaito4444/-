import Foundation

enum GamePhase: String {
    case waiting = "待機中"
    case preflop = "プリフロップ"
    case flop = "フロップ"
    case turn = "ターン"
    case river = "リバー"
    case showdown = "ショーダウン"
    case gameOver = "ゲームオーバー"
}

struct PotInfo {
    var total: Int
    var sidePots: [(amount: Int, eligiblePlayerIds: [UUID])] = []
}
