import SwiftUI

struct PresetDevice: Identifiable {
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
        for uid in store.presetManager.outputPresets.keys where names[uid] == nil {
            names[uid] = uid
        }
        let available = Set(store.outputDevices.filter(\.isValidForSelection).map(\.uid))
        return names.map { uid, name in
            PresetDevice(
                uid: uid,
                name: name,
                isAvailable: available.contains(uid),
                isSelected: uid == store.selectedOutputDeviceID
            )
        }.sorted {
            let order = $0.name.localizedCaseInsensitiveCompare($1.name)
            return order == .orderedSame ? $0.uid < $1.uid : order == .orderedAscending
        }
    }

    var presets: [Preset] { store.presetManager.presets }

    func presetName(for uid: String) -> String? {
        store.presetManager.preset(forOutputDevice: uid)?.metadata.name
    }

    func updatePreset(named name: String?, for uid: String) {
        store.presetManager.updateOutputPreset(named: name, for: uid)
        if uid == store.selectedOutputDeviceID, let name {
            store.loadPreset(named: name)
        }
    }
}
