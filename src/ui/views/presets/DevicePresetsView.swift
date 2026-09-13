import SwiftUI

struct DevicePresetsButton: View {
    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            Label("Device Presets", systemImage: "speaker.wave.2")
                .labelStyle(.iconOnly)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .help("Device presets")
        .popover(isPresented: $isPresented) {
            DevicePresetsView()
        }
    }
}

struct DevicePresetsView: View {
    @EnvironmentObject var store: EqualiserStore

    private var viewModel: DevicePresetsViewModel {
        DevicePresetsViewModel(store: store)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Device Presets")
                .font(.headline)
            Text("Choose the preset to load when each output is selected.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if viewModel.devices.isEmpty {
                Text("Connect an output device to assign a preset.")
                    .foregroundStyle(.secondary)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(viewModel.devices) { device in
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(device.name)
                                        .lineLimit(2)
                                    if !device.isAvailable {
                                        Text("Unavailable")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    } else if device.isSelected {
                                        Text("Current output")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .help(device.uid)
                                .frame(maxWidth: .infinity, alignment: .leading)

                                Picker("Preset for \(device.name)", selection: Binding(
                                    get: { viewModel.presetName(for: device.uid) },
                                    set: { viewModel.updatePreset(named: $0, for: device.uid) }
                                )) {
                                    Text("None — Keep Current").tag(String?.none)
                                    ForEach(viewModel.presets) { preset in
                                        Text(preset.metadata.name).tag(Optional(preset.metadata.name))
                                    }
                                }
                                .labelsHidden()
                                .frame(width: 200)
                            }
                            .frame(minHeight: 44)
                        }
                    }
                }
                .frame(height: min(CGFloat(viewModel.devices.count) * 56, 320))
            }

            Text("Changing the current output’s assignment loads it now. Other assignments take effect when you switch outputs.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(width: 480)
    }
}
