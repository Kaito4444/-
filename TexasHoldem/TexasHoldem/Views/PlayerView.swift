import SwiftUI

struct PlayerView: View {
    @ObservedObject var player: Player
    var isDealer: Bool = false
    var isCurrentTurn: Bool = false
    var showCards: Bool = false
    var isCompact: Bool = false

    var body: some View {
        VStack(spacing: 4) {
            // Cards
            HStack(spacing: 3) {
                if player.holeCards.isEmpty {
                    CardView(card: nil, width: isCompact ? 32 : 40)
                    CardView(card: nil, width: isCompact ? 32 : 40)
                } else if showCards || player.isHuman {
                    ForEach(player.holeCards) { card in
                        CardView(card: card, faceDown: false, width: isCompact ? 32 : 40)
                    }
                } else {
                    CardView(card: player.holeCards[0], faceDown: player.status == .folded, width: isCompact ? 32 : 40)
                    CardView(card: player.holeCards[1], faceDown: player.status == .folded, width: isCompact ? 32 : 40)
                }
            }
            .opacity(player.status == .folded ? 0.4 : 1.0)

            // Info box
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isCurrentTurn ? Color.yellow.opacity(0.9) : Color.black.opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(isCurrentTurn ? Color.yellow : Color.white.opacity(0.3), lineWidth: isCurrentTurn ? 2 : 1)
                    )

                VStack(spacing: 2) {
                    HStack(spacing: 4) {
                        if isDealer {
                            Text("D")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.black)
                                .frame(width: 16, height: 16)
                                .background(Circle().fill(Color.white))
                        }
                        Text(player.name)
                            .font(.system(size: isCompact ? 10 : 12, weight: .semibold))
                            .foregroundColor(isCurrentTurn ? .black : .white)
                            .lineLimit(1)
                    }

                    Text("¥\(player.chips)")
                        .font(.system(size: isCompact ? 11 : 13, weight: .bold, design: .monospaced))
                        .foregroundColor(isCurrentTurn ? .black : .green)

                    if let action = player.lastAction {
                        Text(action.rawValue)
                            .font(.system(size: 10))
                            .foregroundColor(isCurrentTurn ? .black : .orange)
                    }

                    if !player.handDescription.isEmpty {
                        Text(player.handDescription)
                            .font(.system(size: 9))
                            .foregroundColor(isCurrentTurn ? .black : .cyan)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            .frame(minWidth: isCompact ? 80 : 100)

            if player.currentBet > 0 {
                Text("BET: \(player.currentBet)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.yellow)
            }
        }
        .opacity(player.status == .out ? 0.3 : 1.0)
    }
}
