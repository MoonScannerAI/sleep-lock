import SwiftUI

struct LogView: View {
    @State private var lines: [String] = []

    var body: some View {
        List(Array(lines.enumerated()), id: \.offset) { _, line in
            Text(line)
                .font(.system(.footnote, design: .monospaced))
        }
        .navigationTitle("Log")
        .onAppear { lines = Shared.logLines().reversed() }
        .refreshable { lines = Shared.logLines().reversed() }
    }
}
