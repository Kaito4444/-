import SwiftUI

struct CardView: View {
    let card: Card?
    var faceDown: Bool = false
    var width: CGFloat = 50

    var height: CGFloat { width * 1.4 }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(faceDown ? Color.blue : Color.white)
                .shadow(radius: 2)

            if faceDown {
                RoundedRectangle(cornerRadius: 5)
                    .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                    .padding(4)
                Image(systemName: "suit.spade.fill")
                    .foregroundColor(.white.opacity(0.3))
                    .font(.system(size: width * 0.4))
            } else if let card = card {
                VStack(spacing: 0) {
                    HStack {
                        VStack(spacing: 0) {
                            Text(card.rank.symbol)
                                .font(.system(size: width * 0.3, weight: .bold))
                            Text(card.suit.rawValue)
                                .font(.system(size: width * 0.28))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 4)
                    .padding(.top, 3)

                    Spacer()

                    Text(card.suit.rawValue)
                        .font(.system(size: width * 0.45))

                    Spacer()
                }
                .foregroundColor(card.suit.isRed ? .red : .black)
            } else {
                RoundedRectangle(cornerRadius: 5)
                    .strokeBorder(Color.gray.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [4]))
                    .padding(2)
            }
        }
        .frame(width: width, height: height)
    }
}

struct CardHandView: View {
    let cards: [Card]
    var faceDown: Bool = false
    var cardWidth: CGFloat = 50

    var body: some View {
        HStack(spacing: 4) {
            ForEach(cards) { card in
                CardView(card: card, faceDown: faceDown, width: cardWidth)
            }
        }
    }
}
