import SwiftUI
import FamilyControls
import DeviceActivity
import UserNotifications

@MainActor
final class AppModel: ObservableObject {
    @Published var state: LockState = .idle
    @Published var lockAt: Date? = nil
    @Published var authorized: Bool = false
    @Published var errorMessage: String? = nil
    @Published var selection: FamilyActivitySelection = FamilyActivitySelection() {
        didSet { Shared.saveSelection(selection) }
    }

    init() {
        selection = Shared.loadSelection()
        refresh()
    }

    var hasSelection: Bool { !selection.applicationTokens.isEmpty }
    var isReady: Bool { authorized && hasSelection }

    /// Reloads state written by extensions or earlier runs.
    func refresh() {
        authorized = AuthorizationCenter.shared.authorizationStatus == .approved
        let s = Shared.state
        if s != state { state = s }
        let l = Shared.lockAt
        if l != lockAt { lockAt = l }
    }

    func requestPermissions() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            Shared.log("Screen Time authorization granted")
        } catch {
            errorMessage = "Screen Time authorization failed: \(error.localizedDescription)"
            Shared.log("Screen Time authorization failed: \(error.localizedDescription)")
        }
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
            Shared.log("Notification authorization: \(granted)")
        } catch {
            Shared.log("Notification authorization error: \(error.localizedDescription)")
        }
        refresh()
    }

    func arm(hours: Int) {
        arm(seconds: TimeInterval(hours) * 3600, label: "\(hours)h")
    }

    /// Hidden test arm: 15 minutes (DeviceActivity minimum interval).
    func armTest() {
        arm(seconds: 15 * 60, label: "TEST 15 min")
    }

    private func arm(seconds: TimeInterval, label: String) {
        guard state == .idle, isReady else { return }
        let center = DeviceActivityCenter()
        let lock = Date().addingTimeInterval(seconds)
        let end = lock.addingTimeInterval(3600)
        let cal = Calendar.current
        let comps: Set<Calendar.Component> = [.calendar, .year, .month, .day, .hour, .minute, .second]
        let schedule = DeviceActivitySchedule(
            intervalStart: cal.dateComponents(comps, from: lock),
            intervalEnd: cal.dateComponents(comps, from: end),
            repeats: false
        )
        do {
            center.stopMonitoring([Shared.activityName])
            try center.startMonitoring(Shared.activityName, during: schedule)
        } catch {
            errorMessage = "Could not schedule lock: \(error.localizedDescription)"
            Shared.log("Arm failed (\(label)): \(error.localizedDescription)")
            return
        }
        Shared.lockAt = lock
        Shared.state = .armed
        Shared.log("Armed (\(label)), lock at \(ISO8601DateFormatter().string(from: lock))")
        errorMessage = nil
        refresh()
    }

    func cancel() {
        guard state == .armed, let l = lockAt, Date() < l else { return }
        DeviceActivityCenter().stopMonitoring([Shared.activityName])
        Shared.clearShields()
        Shared.lockAt = nil
        Shared.state = .idle
        Shared.log("Cancelled before lock")
        refresh()
    }

    /// Fallback if the monitor extension never fired.
    func checkLock() {
        guard Shared.state == .armed, let l = Shared.lockAt, Date() >= l else { return }
        Shared.applyShields(selection: selection)
        Shared.state = .locked
        Shared.log("App fallback: applied shields and set locked")
        refresh()
    }

    func unlock() {
        Shared.clearShields()
        DeviceActivityCenter().stopMonitoring([Shared.activityName])
        Shared.lockAt = nil
        Shared.state = .idle
        Shared.log("Unlocked after solving puzzle")
        refresh()
    }
}
