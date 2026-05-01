import SwiftUI

struct GameView: View {
    @StateObject private var vm = GameViewModel()
    @State private var raiseAmount: Double = 0
    @State private var showRaiseSlider = false

    var humanPlayer: Player? { vm.humanPlayer }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(colors: [Color(red: 0.1, green: 0.35, blue: 0.1), Color(red: 0.05, green: 0.2, blue: 0.05)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top opponents
                topOpponentsSection

                Spacer()

                // Community cards + pot
                tableSection

                Spacer()

                // Human player
                bottomPlayerSection

                // Action buttons
                if vm.phase != .waiting && vm.phase != .showdown && vm.phase != .gameOver {
                    actionButtons
                }

                // Start / Next round button
                if vm.phase == .waiting || vm.phase == .gameOver {
                    startButton
                } else if vm.phase == .showdown {
                    nextRoundButton
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .alert(vm.message, isPresented: $vm.showWinnerAlert) {
            Button("OK") { vm.showWinnerAlert = false }
        }
    }

    // MARK: - Sections

    private var topOpponentsSection: some View {
        HStack(spacing: 8) {
            ForEach(Array(vm.players.enumerated()), id: \.element.id) { index, player in
                if !player.isHuman {
                    PlayerView(
                        player: player,
                        isDealer: index == vm.dealerIndex,
                        isCurrentTurn: index == vm.currentPlayerIndex && vm.phase != .showdown,
                        showCards: vm.showHoleCards,
                        isCompact: true
                    )
                }
            }
        }
    }

    private var tableSection: some View {
        VStack(spacing: 8) {
            // Phase label
            Text(vm.phase.rawValue)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.black.opacity(0.4)))

            // Community cards
            HStack(spacing: 6) {
                ForEach(0..<5, id: \.self) { i in
                    if i < vm.communityCards.count {
                        CardView(card: vm.communityCards[i], width: 56)
                    } else {
                        CardView(card: nil, width: 56)
                    }
                }
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.black.opacity(0.3)))

            // Pot
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(.yellow)
                Text("ポット: ¥\(vm.pot)")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.yellow)
            }

            // Message
            Text(vm.message)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    private var bottomPlayerSection: some View {
        Group {
            if let human = humanPlayer {
                PlayerView(
                    player: human,
                    isDealer: vm.players.firstIndex(where: \.isHuman).map { $0 == vm.dealerIndex } ?? false,
                    isCurrentTurn: vm.isPlayerTurn && vm.phase != .showdown,
                    showCards: true
                )
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 8) {
            if showRaiseSlider, let human = humanPlayer {
                VStack(spacing: 6) {
                    Text("レイズ額: ¥\(Int(raiseAmount))")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    Slider(value: $raiseAmount,
                           in: Double(vm.minRaise)...Double(human.chips + human.currentBet),
                           step: Double(vm.bigBlind))
                        .accentColor(.yellow)
                        .padding(.horizontal)
                    HStack(spacing: 12) {
                        Button("キャンセル") {
                            showRaiseSlider = false
                        }
                        .buttonStyle(ActionButtonStyle(color: .gray))

                        Button("レイズ ¥\(Int(raiseAmount))") {
                            vm.humanRaise(amount: Int(raiseAmount))
                            showRaiseSlider = false
                        }
                        .buttonStyle(ActionButtonStyle(color: .orange))
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.6)))
            } else {
                HStack(spacing: 10) {
                    Button("フォールド") { vm.humanFold() }
                        .buttonStyle(ActionButtonStyle(color: .red))
                        .disabled(!vm.isPlayerTurn)

                    if vm.canCheck {
                        Button("チェック") { vm.humanCheck() }
                            .buttonStyle(ActionButtonStyle(color: .blue))
                            .disabled(!vm.isPlayerTurn)
                    } else {
                        Button("コール ¥\(vm.callAmount)") { vm.humanCall() }
                            .buttonStyle(ActionButtonStyle(color: .blue))
                            .disabled(!vm.isPlayerTurn)
                    }

                    Button("レイズ") {
                        raiseAmount = Double(vm.minRaise)
                        showRaiseSlider = true
                    }
                    .buttonStyle(ActionButtonStyle(color: .orange))
                    .disabled(!vm.isPlayerTurn)

                    Button("オールイン") { vm.humanAllIn() }
                        .buttonStyle(ActionButtonStyle(color: .purple))
                        .disabled(!vm.isPlayerTurn)
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var startButton: some View {
        Button(vm.phase == .gameOver ? "もう一度" : "ゲームスタート") {
            if vm.phase == .gameOver { vm.setupGame() }
            vm.startNewRound()
        }
        .buttonStyle(ActionButtonStyle(color: .green, large: true))
        .padding(.vertical, 8)
    }

    private var nextRoundButton: some View {
        Button("次のラウンドへ") {
            vm.startNewRound()
        }
        .buttonStyle(ActionButtonStyle(color: .green, large: true))
        .padding(.vertical, 8)
    }
}

struct ActionButtonStyle: ButtonStyle {
    let color: Color
    var large: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: large ? 16 : 13, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, large ? 32 : 12)
            .padding(.vertical, large ? 14 : 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(configuration.isPressed ? color.opacity(0.6) : color)
            )
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
    }
}
