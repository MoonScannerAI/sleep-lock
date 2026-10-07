import SwiftUI
import UIKit

struct PuzzleView: View {
    @EnvironmentObject var model: AppModel
    @State private var a: Int = Int.random(in: 1000...9999)
    @State private var b: Int = Int.random(in: 1000...9999)
    @State private var answer: String = ""
    @State private var wrong: Bool = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Locked")
                .font(.largeTitle.bold())
            Text("\(a) × \(b) = ?")
                .font(.system(size: 34, weight: .semibold, design: .monospaced))
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            TextField("Answer", text: $answer)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            if wrong {
                Text("Wrong answer. Here is a new problem.")
                    .foregroundColor(.red)
            }

            Button("Submit") { submit() }
                .buttonStyle(.borderedProminent)
                .disabled(answer.isEmpty)
            Spacer()
        }
        .padding()
    }

    private func submit() {
        if Int(answer.trimmingCharacters(in: .whitespaces)) == a * b {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            model.unlock()
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            wrong = true
            answer = ""
            a = Int.random(in: 1000...9999)
            b = Int.random(in: 1000...9999)
        }
    }
}
