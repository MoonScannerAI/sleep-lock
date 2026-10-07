import DeviceActivity
import FamilyControls
import ManagedSettings

final class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        let selection = Shared.loadSelection()
        Shared.applyShields(selection: selection)
        Shared.state = .locked
        Shared.log("Monitor extension: intervalDidStart (\(activity.rawValue)) - shields applied, locked")
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        // Intentionally does NOT clear shields.
        Shared.log("Monitor extension: intervalDidEnd (\(activity.rawValue)) - no action")
    }
}
