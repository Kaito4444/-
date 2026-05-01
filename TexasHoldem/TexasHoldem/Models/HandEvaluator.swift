import Foundation

enum HandRank: Int, Comparable, CustomStringConvertible {
    case highCard = 1, onePair, twoPair, threeOfAKind
    case straight, flush, fullHouse, fourOfAKind, straightFlush, royalFlush

    var description: String {
        switch self {
        case .highCard: return "ハイカード"
        case .onePair: return "ワンペア"
        case .twoPair: return "ツーペア"
        case .threeOfAKind: return "スリーカード"
        case .straight: return "ストレート"
        case .flush: return "フラッシュ"
        case .fullHouse: return "フルハウス"
        case .fourOfAKind: return "フォーカード"
        case .straightFlush: return "ストレートフラッシュ"
        case .royalFlush: return "ロイヤルフラッシュ"
        }
    }

    static func < (lhs: HandRank, rhs: HandRank) -> Bool { lhs.rawValue < rhs.rawValue }
}

struct HandResult: Comparable {
    let rank: HandRank
    let tiebreakers: [Int]
    let description: String

    static func < (lhs: HandResult, rhs: HandResult) -> Bool {
        if lhs.rank != rhs.rank { return lhs.rank < rhs.rank }
        for (l, r) in zip(lhs.tiebreakers, rhs.tiebreakers) {
            if l != r { return l < r }
        }
        return false
    }

    static func == (lhs: HandResult, rhs: HandResult) -> Bool {
        lhs.rank == rhs.rank && lhs.tiebreakers == rhs.tiebreakers
    }
}

struct HandEvaluator {
    static func best(from cards: [Card]) -> HandResult {
        let combos = combinations(cards, choose: 5)
        return combos.map { evaluate($0) }.max()!
    }

    private static func evaluate(_ cards: [Card]) -> HandResult {
        let sorted = cards.sorted { $0.rank > $1.rank }
        let ranks = sorted.map(\.rank.rawValue)
        let suits = sorted.map(\.suit)
        let isFlush = Set(suits).count == 1
        let isStraight = isStraightCheck(ranks)
        let groups = Dictionary(grouping: ranks, by: { $0 }).mapValues(\.count).sorted { $0.value != $1.value ? $0.value > $1.value : $0.key > $1.key }

        if isFlush && isStraight {
            let high = ranks[0]
            return HandResult(rank: high == 14 ? .royalFlush : .straightFlush, tiebreakers: ranks, description: high == 14 ? HandRank.royalFlush.description : HandRank.straightFlush.description)
        }
        if groups[0].value == 4 {
            return HandResult(rank: .fourOfAKind, tiebreakers: groups.map(\.key), description: HandRank.fourOfAKind.description)
        }
        if groups[0].value == 3 && groups[1].value == 2 {
            return HandResult(rank: .fullHouse, tiebreakers: groups.map(\.key), description: HandRank.fullHouse.description)
        }
        if isFlush {
            return HandResult(rank: .flush, tiebreakers: ranks, description: HandRank.flush.description)
        }
        if isStraight {
            return HandResult(rank: .straight, tiebreakers: ranks, description: HandRank.straight.description)
        }
        if groups[0].value == 3 {
            return HandResult(rank: .threeOfAKind, tiebreakers: groups.map(\.key), description: HandRank.threeOfAKind.description)
        }
        if groups[0].value == 2 && groups[1].value == 2 {
            return HandResult(rank: .twoPair, tiebreakers: groups.map(\.key), description: HandRank.twoPair.description)
        }
        if groups[0].value == 2 {
            return HandResult(rank: .onePair, tiebreakers: groups.map(\.key), description: HandRank.onePair.description)
        }
        return HandResult(rank: .highCard, tiebreakers: ranks, description: HandRank.highCard.description)
    }

    private static func isStraightCheck(_ ranks: [Int]) -> Bool {
        let sorted = ranks.sorted(by: >)
        // Normal straight
        if sorted[0] - sorted[4] == 4 && Set(sorted).count == 5 { return true }
        // A-2-3-4-5
        if sorted == [14, 5, 4, 3, 2] { return true }
        return false
    }

    private static func combinations(_ arr: [Card], choose k: Int) -> [[Card]] {
        guard k > 0 else { return [[]] }
        guard arr.count >= k else { return [] }
        if k == arr.count { return [arr] }
        var result: [[Card]] = []
        for (i, item) in arr.enumerated() {
            let rest = combinations(Array(arr[(i+1)...]), choose: k - 1)
            result += rest.map { [item] + $0 }
        }
        return result
    }
}
