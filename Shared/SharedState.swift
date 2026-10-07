import Foundation
import FamilyControls
import ManagedSettings
import DeviceActivity

enum LockState: String {
    case idle
    case armed
    case locked
}

enum Shared {
    static let storeName = ManagedSettingsStore.Name("sleeplock")
    static let activityName = DeviceActivityName("sleeplock.night")

    /// Read from each target's Info.plist (key `AppGroupID`).
    static var appGroupID: String {
        (Bundle.main.object(forInfoDictionaryKey: "AppGroupID") as? String) ?? ""
    }

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    private enum Key {
        static let selection = "selection"
        static let state = "state"
        static let lockAt = "lockAt"
        static let log = "log"
    }

    // MARK: State

    static var state: LockState {
        get {
            LockState(rawValue: defaults.string(forKey: Key.state) ?? "") ?? .idle
        }
        set {
            defaults.set(newValue.rawValue, forKey: Key.state)
        }
    }

    static var lockAt: Date? {
        get { defaults.object(forKey: Key.lockAt) as? Date }
        set {
            if let newValue = newValue {
                defaults.set(newValue, forKey: Key.lockAt)
            } else {
                defaults.removeObject(forKey: Key.lockAt)
            }
        }
    }

    // MARK: Selection

    static func loadSelection() -> FamilyActivitySelection {
        guard let data = defaults.data(forKey: Key.selection),
              let sel = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
        else { return FamilyActivitySelection() }
        return sel
    }

    static func saveSelection(_ selection: FamilyActivitySelection) {
        if let data = try? JSONEncoder().encode(selection) {
            defaults.set(data, forKey: Key.selection)
        }
    }

    // MARK: Log

    static func log(_ message: String) {
        let stamp = ISO8601DateFormatter().string(from: Date())
        var lines = defaults.stringArray(forKey: Key.log) ?? []
        lines.append("\(stamp) — \(message)")
        if lines.count > 200 {
            lines.removeFirst(lines.count - 200)
        }
        defaults.set(lines, forKey: Key.log)
    }

    /// Oldest first, as stored.
    static func logLines() -> [String] {
        defaults.stringArray(forKey: Key.log) ?? []
    }

    // MARK: Shields

    static func applyShields(selection: FamilyActivitySelection) {
        let store = ManagedSettingsStore(named: storeName)
        store.shield.applicationCategories = .all(except: selection.applicationTokens)
        store.shield.webDomainCategories = .all()
        store.application.denyAppRemoval = true
    }

    static func clearShields() {
        let store = ManagedSettingsStore(named: storeName)
        store.clearAllSettings()
    }
}
