import Foundation

enum Suit: String, CaseIterable, Codable {
    case spades = "♠"
    case hearts = "♥"
    case diamonds = "♦"
    case clubs = "♣"

    var isRed: Bool { self == .hearts || self == .diamonds }
}

enum Rank: Int, CaseIterable, Codable, Comparable {
    case two = 2, three, four, five, six, seven, eight, nine, ten
    case jack = 11, queen = 12, king = 13, ace = 14

    var symbol: String {
        switch self {
        case .jack: return "J"
        case .queen: return "Q"
        case .king: return "K"
        case .ace: return "A"
        default: return "\(rawValue)"
        }
    }

    static func < (lhs: Rank, rhs: Rank) -> Bool { lhs.rawValue < rhs.rawValue }
}

struct Card: Identifiable, Equatable, Codable {
    let id = UUID()
    let rank: Rank
    let suit: Suit

    var display: String { "\(rank.symbol)\(suit.rawValue)" }
}
