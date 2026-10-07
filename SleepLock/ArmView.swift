import SwiftUI

struct ArmView: View {
    @EnvironmentObject var model: AppModel
    @State private var hours: Int = 6
    @State private var showSetup = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Sleep Lock")
                .font(.largeTitle.bold())
                .onLongPressGesture(minimumDuration: 1.5) {
                    // Hidden test option: lock in 15 minutes.
                    if model.state == .idle { model.armTest() }
                }

            if model.state == .armed, let lockAt = model.lockAt {
                armedBody(lockAt: lockAt)
            } else {
                idleBody
            }

            if let err = model.errorMessage {
                Text(err).foregroundColor(.red).font(.footnote)
            }
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showSetup) {
            SetupView()
                .environmentObject(model)
        }
    }

    private var idleBody: some View {
        VStack(spacing: 24) {
            Text("Lock starts in")
                .foregroundColor(.secondary)
            Stepper(value: $hours, in: 1...12) {
                Text("\(hours) hour\(hours == 1 ? "" : "s")")
                    .font(.title2.monospacedDigit())
            }
            .padding(.horizontal, 40)

            Button {
                model.arm(hours: hours)
            } label: {
                Text("Arm")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)

            Button("Change allowed apps") { showSetup = true }
                .font(.footnote)
        }
    }

    private func armedBody(lockAt: Date) -> some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = max(0, lockAt.timeIntervalSince(context.date))
            VStack(spacing: 24) {
                Text("Armed")
                    .font(.title2)
                    .foregroundColor(.orange)
                Text(format(remaining))
                    .font(.system(size: 52, weight: .bold, design: .monospaced))
                Text("until lock")
                    .foregroundColor(.secondary)
                if remaining > 0 {
                    Button("Cancel", role: .destructive) { model.cancel() }
                        .buttonStyle(.bordered)
                }
            }
        }
    }

    private func format(_ t: TimeInterval) -> String {
        let total = Int(t)
        return String(format: "%02d:%02d:%02d", total / 3600, (total % 3600) / 60, total % 60)
    }
}
