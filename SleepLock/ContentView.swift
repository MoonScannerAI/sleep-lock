import SwiftUI

struct ContentView: View {
    @EnvironmentObject var model: AppModel
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            Group {
                if model.state == .locked {
                    // Always reachable while locked, even if auth status reads stale.
                    PuzzleView()
                } else if !model.isReady && model.state == .idle {
                    SetupView()
                } else {
                    ArmView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        LogView()
                    } label: {
                        Image(systemName: "list.bullet.rectangle")
                    }
                }
            }
        }
        .onReceive(ticker) { _ in
            model.refresh()
            model.checkLock()
        }
    }
}
