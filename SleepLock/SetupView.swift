import SwiftUI
import FamilyControls

struct SetupView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var showPicker = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Setup")
                .font(.largeTitle.bold())

            if !model.authorized {
                Text("Sleep Lock needs Screen Time access and notifications.")
                    .multilineTextAlignment(.center)
                Button("Authorize Screen Time & Notifications") {
                    Task { await model.requestPermissions() }
                }
                .buttonStyle(.borderedProminent)
            } else {
                Label("Screen Time authorized", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)

                Text("Select Phone, Messages and Maps")
                    .font(.headline)
                Button("Choose allowed apps") { showPicker = true }
                    .buttonStyle(.borderedProminent)
                Text("\(model.selection.applicationTokens.count) apps selected")
                    .foregroundColor(.secondary)

                Button("Done") { dismiss() }
                    .buttonStyle(.bordered)
                    .disabled(!model.hasSelection)
            }

            if let err = model.errorMessage {
                Text(err).foregroundColor(.red).font(.footnote)
            }
            Spacer()
        }
        .padding()
        .familyActivityPicker(isPresented: $showPicker, selection: $model.selection)
    }
}
