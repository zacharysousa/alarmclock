import SwiftUI

struct TypingMissionView: View {
    let mission: MissionConfig
    let onComplete: () -> Void

    private let defaultPhrases = [
        "The early bird catches the worm",
        "Rise and shine, it is a beautiful day",
        "Wake up and be awesome",
        "Today is a great day to be alive",
        "Every morning is a fresh beginning",
    ]

    private var targetPhrase: String {
        mission.customPhrase ?? defaultPhrases.randomElement() ?? defaultPhrases[0]
    }

    @State private var userInput = ""
    @State private var isComplete = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 24) {
            Text("Typing Mission")
                .font(.headline)
                .foregroundStyle(.gray)

            Spacer()

            VStack(spacing: 16) {
                Text("Type this phrase exactly:")
                    .font(.subheadline)
                    .foregroundStyle(.gray)

                Text(targetPhrase)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color(white: 0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)

            characterDisplay

            TextField("Type here...", text: $userInput, axis: .vertical)
                .focused($isFocused)
                .foregroundStyle(.white)
                .tint(.orange)
                .padding()
                .background(Color(white: 0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onChange(of: userInput) { _, new in
                    checkCompletion(new)
                }

            Spacer()
        }
        .padding()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { isFocused = true }
        }
    }

    private var characterDisplay: some View {
        let lowTarget = targetPhrase.lowercased()
        let lowInput = userInput.lowercased()
        return FlowLayout(spacing: 0) {
            ForEach(Array(lowTarget.enumerated()), id: \.offset) { i, char in
                let color: Color = {
                    if i < lowInput.count {
                        let idx = lowInput.index(lowInput.startIndex, offsetBy: i)
                        return lowInput[idx] == char ? .green : .red
                    }
                    return .gray.opacity(0.4)
                }()
                Text(String(char))
                    .foregroundStyle(color)
                    .font(.body.monospaced())
            }
        }
        .padding(.horizontal)
    }

    private func checkCompletion(_ input: String) {
        if input.lowercased() == targetPhrase.lowercased() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { onComplete() }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        layout(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: ProposedViewSize(bounds.size), subviews: subviews)
        for (subview, frame) in zip(subviews, result.frames) {
            subview.place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: ProposedViewSize(frame.size))
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var frames: [CGRect] = []
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0; y += rowHeight + spacing; rowHeight = 0
            }
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), frames)
    }
}
