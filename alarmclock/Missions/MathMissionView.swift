import SwiftUI

struct MathProblem {
    let question: String
    let answer: Int

    static func generate(difficulty: Int) -> MathProblem {
        switch difficulty {
        case 1:
            let a = Int.random(in: 1...20)
            let b = Int.random(in: 1...20)
            let add = Bool.random()
            if add {
                return MathProblem(question: "\(a) + \(b) = ?", answer: a + b)
            } else {
                let big = max(a, b), small = min(a, b)
                return MathProblem(question: "\(big) - \(small) = ?", answer: big - small)
            }
        case 2:
            let a = Int.random(in: 2...12)
            let b = Int.random(in: 2...12)
            return MathProblem(question: "\(a) × \(b) = ?", answer: a * b)
        default:
            let a = Int.random(in: 10...50)
            let b = Int.random(in: 2...10)
            let c = Int.random(in: 1...20)
            return MathProblem(question: "(\(a) + \(c)) × \(b) = ?", answer: (a + c) * b)
        }
    }
}

struct MathMissionView: View {
    let mission: MissionConfig
    let onComplete: () -> Void

    @State private var currentProblem: MathProblem
    @State private var userInput = ""
    @State private var correctCount = 0
    @State private var shakeOffset: CGFloat = 0
    @State private var showWrong = false
    @FocusState private var isInputFocused: Bool

    init(mission: MissionConfig, onComplete: @escaping () -> Void) {
        self.mission = mission
        self.onComplete = onComplete
        _currentProblem = State(initialValue: MathProblem.generate(difficulty: mission.difficulty))
    }

    var body: some View {
        VStack(spacing: 32) {
            Text("Math Mission")
                .font(.headline)
                .foregroundStyle(.gray)

            progressView

            Spacer()

            questionView

            inputView

            Spacer()
        }
        .padding()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isInputFocused = true
            }
        }
    }

    private var progressView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                ForEach(0..<mission.requiredCount, id: \.self) { i in
                    Circle()
                        .fill(i < correctCount ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: 10, height: 10)
                }
            }
            Text("\(correctCount) / \(mission.requiredCount) correct")
                .font(.caption)
                .foregroundStyle(.gray)
        }
    }

    private var questionView: some View {
        VStack(spacing: 16) {
            Text(currentProblem.question)
                .font(.system(size: 52, weight: .thin, design: .rounded))
                .foregroundStyle(.white)
                .offset(x: shakeOffset)
                .animation(.default, value: shakeOffset)

            if showWrong {
                Text("Wrong answer, try again")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .transition(.opacity)
            }
        }
    }

    private var inputView: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(white: 0.12))
                    .frame(height: 56)

                TextField("Your answer", text: $userInput)
                    .keyboardType(.numberPad)
                    .focused($isInputFocused)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .tint(.orange)
                    .multilineTextAlignment(.center)
            }

            Button {
                submitAnswer()
            } label: {
                Text("SUBMIT")
                    .font(.headline.bold())
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(userInput.isEmpty ? Color.gray : Color.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(userInput.isEmpty)
        }
    }

    private func submitAnswer() {
        guard let value = Int(userInput) else {
            triggerWrong()
            return
        }

        if value == currentProblem.answer {
            correctCount += 1
            userInput = ""
            if correctCount >= mission.requiredCount {
                onComplete()
            } else {
                currentProblem = MathProblem.generate(difficulty: mission.difficulty)
                withAnimation { showWrong = false }
            }
        } else {
            triggerWrong()
        }
    }

    private func triggerWrong() {
        userInput = ""
        withAnimation { showWrong = true }
        let sequence: [CGFloat] = [-12, 12, -10, 10, -6, 6, 0]
        for (i, offset) in sequence.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.06) {
                shakeOffset = offset
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { showWrong = false }
        }
    }
}
