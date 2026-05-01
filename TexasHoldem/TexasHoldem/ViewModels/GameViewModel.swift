import Foundation
import Combine

class GameViewModel: ObservableObject {
    @Published var players: [Player] = []
    @Published var communityCards: [Card] = []
    @Published var phase: GamePhase = .waiting
    @Published var pot: Int = 0
    @Published var currentPlayerIndex: Int = 0
    @Published var dealerIndex: Int = 0
    @Published var currentBet: Int = 0
    @Published var smallBlind: Int = 10
    @Published var bigBlind: Int = 20
    @Published var message: String = ""
    @Published var winners: [Player] = []
    @Published var showWinnerAlert: Bool = false
    @Published var isPlayerTurn: Bool = false
    @Published var minRaise: Int = 20
    @Published var showHoleCards: Bool = false

    private var deck = Deck()
    private var lastRaiserIndex: Int = -1
    private var actionCount: Int = 0

    let humanName = "あなた"
    let startingChips = 1000

    init() {
        setupGame()
    }

    func setupGame() {
        players = [
            Player(name: humanName, chips: startingChips, isHuman: true),
            Player(name: "CPU Alice", chips: startingChips),
            Player(name: "CPU Bob", chips: startingChips),
            Player(name: "CPU Carol", chips: startingChips),
        ]
        phase = .waiting
        message = "ゲームを開始してください"
    }

    // MARK: - Game Flow

    func startNewRound() {
        guard activePlayers.count >= 2 else {
            endGame()
            return
        }

        deck = Deck()
        deck.shuffle()
        communityCards = []
        pot = 0
        currentBet = 0
        winners = []
        showHoleCards = false

        for player in players { player.reset() }

        // Advance dealer
        dealerIndex = nextActiveIndex(after: dealerIndex)
        let sbIndex = nextActiveIndex(after: dealerIndex)
        let bbIndex = nextActiveIndex(after: sbIndex)

        // Deal hole cards
        for player in activePlayers {
            player.holeCards = deck.dealMany(2)
        }

        // Post blinds
        postBlind(at: sbIndex, amount: smallBlind)
        postBlind(at: bbIndex, amount: bigBlind)
        currentBet = bigBlind
        minRaise = bigBlind * 2

        phase = .preflop
        message = "プリフロップ"

        // First to act is after BB
        currentPlayerIndex = nextActiveIndex(after: bbIndex)
        lastRaiserIndex = bbIndex
        actionCount = 0

        scheduleAITurnIfNeeded()
    }

    private func postBlind(at index: Int, amount: Int) {
        let player = players[index]
        let actual = min(amount, player.chips)
        player.chips -= actual
        player.currentBet = actual
        pot += actual
        if player.chips == 0 { player.status = .allIn }
    }

    // MARK: - Actions

    func humanFold() { guard isPlayerTurn else { return }; performAction(.fold, playerIndex: currentPlayerIndex) }
    func humanCheck() { guard isPlayerTurn else { return }; performAction(.check, playerIndex: currentPlayerIndex) }
    func humanCall() { guard isPlayerTurn else { return }; performAction(.call, playerIndex: currentPlayerIndex) }
    func humanRaise(amount: Int) { guard isPlayerTurn else { return }; performRaise(amount: amount, playerIndex: currentPlayerIndex) }
    func humanAllIn() { guard isPlayerTurn else { return }; performAllIn(playerIndex: currentPlayerIndex) }

    private func performAction(_ action: PlayerAction, playerIndex: Int) {
        let player = players[playerIndex]
        player.lastAction = action

        switch action {
        case .fold:
            player.status = .folded
            message = "\(player.name) がフォールドしました"
        case .check:
            message = "\(player.name) がチェックしました"
        case .call:
            let toCall = currentBet - player.currentBet
            let actual = min(toCall, player.chips)
            player.chips -= actual
            player.currentBet += actual
            pot += actual
            if player.chips == 0 { player.status = .allIn }
            message = "\(player.name) がコールしました (\(actual))"
        default:
            break
        }

        actionCount += 1
        advanceTurn()
    }

    private func performRaise(amount: Int, playerIndex: Int) {
        let player = players[playerIndex]
        let totalBet = amount
        let additional = totalBet - player.currentBet
        let actual = min(additional, player.chips)
        player.chips -= actual
        player.currentBet += actual
        pot += actual
        if player.chips == 0 { player.status = .allIn }
        currentBet = player.currentBet
        minRaise = currentBet + (currentBet - (lastRaiserIndex >= 0 ? players[lastRaiserIndex].currentBet : 0))
        player.lastAction = .raise
        lastRaiserIndex = playerIndex
        actionCount = 1
        message = "\(player.name) がレイズしました (\(player.currentBet))"
        advanceTurn()
    }

    private func performAllIn(playerIndex: Int) {
        let player = players[playerIndex]
        let totalBet = player.currentBet + player.chips
        if totalBet > currentBet {
            performRaise(amount: totalBet, playerIndex: playerIndex)
        } else {
            let additional = player.chips
            pot += additional
            player.currentBet += additional
            player.chips = 0
            player.status = .allIn
            player.lastAction = .allIn
            message = "\(player.name) がオールインしました"
            actionCount += 1
            advanceTurn()
        }
    }

    private func advanceTurn() {
        // Check if only one player remains
        if activePlayers.filter({ $0.status == .active || $0.status == .allIn }).count <= 1 {
            runoutBoard()
            return
        }

        // Check if betting round is over
        if isBettingRoundOver() {
            advancePhase()
            return
        }

        // Move to next active player
        currentPlayerIndex = nextActiveIndex(after: currentPlayerIndex)
        // Skip players who are all-in or folded
        while players[currentPlayerIndex].status == .folded || players[currentPlayerIndex].status == .allIn {
            currentPlayerIndex = nextActiveIndex(after: currentPlayerIndex)
            if isBettingRoundOver() {
                advancePhase()
                return
            }
        }

        scheduleAITurnIfNeeded()
    }

    private func isBettingRoundOver() -> Bool {
        let active = players.filter { $0.status == .active }
        if active.isEmpty { return true }
        // All active players have matched the current bet
        let allMatched = active.allSatisfy { $0.currentBet == currentBet }
        // Everyone has acted at least once after last raise
        return allMatched && actionCount >= active.count
    }

    private func advancePhase() {
        // Reset bets for next round
        for player in players { player.currentBet = 0 }
        currentBet = 0
        minRaise = bigBlind

        switch phase {
        case .preflop:
            communityCards = deck.dealMany(3)
            phase = .flop
            message = "フロップ"
        case .flop:
            communityCards += deck.dealMany(1)
            phase = .turn
            message = "ターン"
        case .turn:
            communityCards += deck.dealMany(1)
            phase = .river
            message = "リバー"
        case .river:
            phase = .showdown
            showdown()
            return
        default:
            return
        }

        // Set first actor (left of dealer)
        let sbIndex = nextActiveIndex(after: dealerIndex)
        currentPlayerIndex = sbIndex
        // Skip folded/allin to first active
        while players[currentPlayerIndex].status != .active {
            currentPlayerIndex = nextActiveIndex(after: currentPlayerIndex)
        }
        actionCount = 0
        lastRaiserIndex = -1

        scheduleAITurnIfNeeded()
    }

    private func runoutBoard() {
        // Deal remaining community cards
        while communityCards.count < 5 {
            if let card = deck.deal() { communityCards.append(card) }
        }
        showdown()
    }

    // MARK: - Showdown

    private func showdown() {
        phase = .showdown
        showHoleCards = true

        let eligible = players.filter { $0.status != .folded && $0.status != .out }

        if eligible.count == 1 {
            winners = eligible
            awardPot(to: eligible)
            message = "\(eligible[0].name) の勝利！"
        } else {
            // Evaluate hands
            var results: [(player: Player, result: HandResult)] = []
            for player in eligible {
                let allCards = player.holeCards + communityCards
                let result = HandEvaluator.best(from: allCards)
                player.handDescription = result.description
                results.append((player, result))
            }

            let best = results.max { $0.result < $1.result }!
            let winnerResults = results.filter { $0.result == best.result }
            winners = winnerResults.map(\.player)
            awardPot(to: winners)

            if winners.count == 1 {
                message = "\(winners[0].name) の勝利！ (\(best.result.description))"
            } else {
                let names = winners.map(\.name).joined(separator: ", ")
                message = "チョップ！ \(names) (\(best.result.description))"
            }
        }

        showWinnerAlert = true

        // Check game over
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let stillIn = self.players.filter { $0.chips > 0 }
            if stillIn.count <= 1 {
                self.phase = .gameOver
            }
        }
    }

    private func awardPot(to winners: [Player]) {
        let share = pot / winners.count
        let remainder = pot % winners.count
        for (i, winner) in winners.enumerated() {
            winner.chips += share + (i == 0 ? remainder : 0)
        }
        pot = 0
    }

    private func endGame() {
        phase = .gameOver
        if let winner = players.filter({ $0.chips > 0 }).first {
            message = "\(winner.name) がチャンピオン！"
        }
    }

    // MARK: - AI

    private func scheduleAITurnIfNeeded() {
        let player = players[currentPlayerIndex]
        isPlayerTurn = player.isHuman

        guard !player.isHuman && player.status == .active else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.performAIAction(playerIndex: self.currentPlayerIndex)
        }
    }

    private func performAIAction(playerIndex: Int) {
        guard playerIndex < players.count else { return }
        let player = players[playerIndex]
        guard player.status == .active else {
            advanceTurn()
            return
        }

        let toCall = currentBet - player.currentBet
        let random = Int.random(in: 0...100)

        if toCall == 0 {
            // Can check or raise
            if random < 70 {
                performAction(.check, playerIndex: playerIndex)
            } else {
                let raiseAmount = currentBet + bigBlind * Int.random(in: 1...3)
                performRaise(amount: min(raiseAmount, player.currentBet + player.chips), playerIndex: playerIndex)
            }
        } else if toCall >= player.chips {
            // All-in or fold
            if random < 40 {
                performAction(.fold, playerIndex: playerIndex)
            } else {
                performAllIn(playerIndex: playerIndex)
            }
        } else {
            if random < 25 {
                performAction(.fold, playerIndex: playerIndex)
            } else if random < 75 {
                performAction(.call, playerIndex: playerIndex)
            } else {
                let raiseAmount = currentBet + bigBlind * Int.random(in: 1...3)
                performRaise(amount: min(raiseAmount, player.currentBet + player.chips), playerIndex: playerIndex)
            }
        }
    }

    // MARK: - Helpers

    var activePlayers: [Player] { players.filter { $0.status != .out } }
    var humanPlayer: Player? { players.first(where: \.isHuman) }

    var canCheck: Bool {
        guard let human = humanPlayer else { return false }
        return currentBet == human.currentBet
    }

    var callAmount: Int {
        guard let human = humanPlayer else { return 0 }
        return min(currentBet - human.currentBet, human.chips)
    }

    private func nextActiveIndex(after index: Int) -> Int {
        var next = (index + 1) % players.count
        while players[next].status == .out {
            next = (next + 1) % players.count
        }
        return next
    }
}
