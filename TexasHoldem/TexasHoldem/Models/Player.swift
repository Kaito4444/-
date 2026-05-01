import Foundation

enum PlayerAction: String {
    case fold = "フォールド"
    case check = "チェック"
    case call = "コール"
    case raise = "レイズ"
    case allIn = "オールイン"
}

enum PlayerStatus {
    case active, folded, allIn, out
}

class Player: ObservableObject, Identifiable {
    let id = UUID()
    let name: String
    let isHuman: Bool

    @Published var chips: Int
    @Published var holeCards: [Card] = []
    @Published var currentBet: Int = 0
    @Published var status: PlayerStatus = .active
    @Published var lastAction: PlayerAction?
    @Published var handDescription: String = ""

    init(name: String, chips: Int, isHuman: Bool = false) {
        self.name = name
        self.chips = chips
        self.isHuman = isHuman
    }

    var isActive: Bool { status == .active }
    var canAct: Bool { status == .active || status == .allIn }

    func reset() {
        holeCards = []
        currentBet = 0
        status = chips > 0 ? .active : .out
        lastAction = nil
        handDescription = ""
    }
}
