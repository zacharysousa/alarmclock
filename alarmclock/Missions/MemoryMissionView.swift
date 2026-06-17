import SwiftUI

struct MemoryTile: Identifiable {
    let id: UUID
    let pairID: Int
    var isFlipped: Bool
    var isMatched: Bool
    let symbol: String
}

struct MemoryMissionView: View {
    let mission: MissionConfig
    let onComplete: () -> Void

    @State private var tiles: [MemoryTile] = []
    @State private var selectedIndices: [Int] = []
    @State private var isChecking = false
    @State private var revealPhase = true
    @State private var revealCountdown = 3

    private var gridSize: Int {
        switch mission.difficulty {
        case 1: return 2
        case 2: return 4
        default: return 4
        }
    }

    private let symbols = ["star", "heart", "moon", "sun.max", "bolt", "flame", "drop", "leaf",
                           "snowflake", "cloud", "wind", "tornado", "sparkles", "diamond", "triangle", "square"]

    var body: some View {
        VStack(spacing: 24) {
            Text("Memory Mission")
                .font(.headline)
                .foregroundStyle(.gray)

            if revealPhase {
                Text("Memorize the tiles: \(revealCountdown)s")
                    .font(.title3.bold())
                    .foregroundStyle(.orange)
                    .contentTransition(.numericText())
            } else {
                Text("Find all matching pairs")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }

            Spacer()

            let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: gridSize)
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(tiles.indices, id: \.self) { i in
                    TileView(tile: tiles[i])
                        .onTapGesture {
                            guard !revealPhase else { return }
                            tapTile(at: i)
                        }
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .padding()
        .onAppear(perform: setupGame)
    }

    private func setupGame() {
        let pairCount = gridSize * gridSize / 2
        var newTiles: [MemoryTile] = []
        for pair in 0..<pairCount {
            let sym = symbols[pair % symbols.count]
            newTiles.append(MemoryTile(id: UUID(), pairID: pair, isFlipped: true, isMatched: false, symbol: sym))
            newTiles.append(MemoryTile(id: UUID(), pairID: pair, isFlipped: true, isMatched: false, symbol: sym))
        }
        tiles = newTiles.shuffled()

        let displayDuration = mission.difficulty == 1 ? 3 : 5
        revealCountdown = displayDuration

        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
            revealCountdown -= 1
            if revealCountdown <= 0 {
                t.invalidate()
                withAnimation { revealPhase = false }
                for i in tiles.indices { tiles[i].isFlipped = false }
            }
        }
    }

    private func tapTile(at index: Int) {
        guard !isChecking,
              !tiles[index].isMatched,
              !tiles[index].isFlipped,
              selectedIndices.count < 2,
              !selectedIndices.contains(index) else { return }

        withAnimation(.spring(duration: 0.3)) { tiles[index].isFlipped = true }
        selectedIndices.append(index)

        if selectedIndices.count == 2 {
            isChecking = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                checkMatch()
            }
        }
    }

    private func checkMatch() {
        let a = selectedIndices[0], b = selectedIndices[1]
        if tiles[a].pairID == tiles[b].pairID {
            withAnimation { tiles[a].isMatched = true; tiles[b].isMatched = true }
            if tiles.allSatisfy(\.isMatched) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { onComplete() }
            }
        } else {
            withAnimation(.spring(duration: 0.3)) {
                tiles[a].isFlipped = false
                tiles[b].isFlipped = false
            }
        }
        selectedIndices = []
        isChecking = false
    }
}

struct TileView: View {
    let tile: MemoryTile

    var body: some View {
        ZStack {
            if tile.isFlipped || tile.isMatched {
                RoundedRectangle(cornerRadius: 10)
                    .fill(tile.isMatched ? Color.green.opacity(0.3) : Color(white: 0.2))
                Image(systemName: tile.symbol)
                    .font(.title2)
                    .foregroundStyle(tile.isMatched ? .green : .orange)
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(white: 0.12))
                Image(systemName: "questionmark")
                    .font(.title3)
                    .foregroundStyle(.gray)
            }
        }
        .frame(height: 70)
        .rotation3DEffect(
            .degrees(tile.isFlipped || tile.isMatched ? 0 : 180),
            axis: (x: 0, y: 1, z: 0)
        )
    }
}
