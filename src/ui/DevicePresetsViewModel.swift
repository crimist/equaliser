import SwiftUI

struct PresetDevice: Identifiable {
    /// Output preset key, which matches the CoreAudio UID for most devices.
    let uid: String
    let name: String
    let isAvailable: Bool
    let isSelected: Bool

    var id: String { uid }
}

@MainActor
@Observable
final class DevicePresetsViewModel {
    private unowned let store: EqualiserStore

    init(store: EqualiserStore) {
        self.store = store
    }

    var devices: [PresetDevice] {
        var names = store.presetManager.outputDeviceNames
        for uid in Array(store.presetManager.outputPresets.keys) + store.presetManager.outputsOff where names[uid] == nil {
            names[uid] = uid
        }
        let available = Set(store.outputDevices.filter(\.isValidForSelection).map { OutputPresetKey.make(for: $0.uid) })
        let selected = selectedKey
        return names.map { uid, name in
            PresetDevice(
                uid: uid,
                name: name,
                isAvailable: available.contains(uid),
                isSelected: uid == selected
            )
        }.sorted {
            let order = $0.name.localizedCaseInsensitiveCompare($1.name)
            return order == .orderedSame ? $0.uid < $1.uid : order == .orderedAscending
        }
    }

    var presets: [Preset] { store.presetManager.presets }

    private var selectedKey: String? {
        store.selectedOutputDeviceID.map(OutputPresetKey.make)
    }

    func presetName(for uid: String) -> String? {
        store.presetManager.assignment(forOutputDevice: uid).presetName
    }

    func updatePreset(named name: String?, for uid: String) {
        store.setOutputPreset(named: name, forOutputDevice: uid)
    }

    func isEQEnabled(for uid: String) -> Bool {
        store.presetManager.assignment(forOutputDevice: uid).eqEnabled
    }

    func setEQEnabled(_ enabled: Bool, for uid: String) {
        store.setOutputEQEnabled(enabled, forOutputDevice: uid)
    }

    /// Forgets an output that is no longer connected.
    func remove(_ device: PresetDevice) {
        guard !device.isAvailable else { return }
        store.presetManager.forgetOutputDevice(device.uid)
    }
}
