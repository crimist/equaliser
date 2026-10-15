import AppKit
import SwiftUI

struct DevicePresetPicker: NSViewRepresentable {
    let names: [String]
    @Binding var selection: String?
    let label: String

    enum Entry: Equatable {
        /// Shown only when there is no default preset to fall back to.
        case notSet
        case separator
        case preset(String)
    }

    /// Menu entries in display order: the default preset first, then the rest.
    private var entries: [Entry] {
        let defaultName = PresetManager.defaultOutputPresetName
        var entries: [Entry] = selection == nil ? [.notSet] : []
        if names.contains(defaultName) {
            entries += [.preset(defaultName), .separator]
        }
        return entries + names.filter { $0 != defaultName }.map(Entry.preset)
    }

    func makeNSView(context: Context) -> NSPopUpButton {
        let button = NSPopUpButton()
        button.controlSize = .small
        button.font = .systemFont(ofSize: NSFont.smallSystemFontSize)
        button.setContentHuggingPriority(.defaultLow, for: .horizontal)
        button.target = context.coordinator
        button.action = #selector(Coordinator.selectPreset(_:))
        return button
    }

    func updateNSView(_ button: NSPopUpButton, context: Context) {
        context.coordinator.selection = $selection
        let entries = entries
        if context.coordinator.entries != entries {
            context.coordinator.entries = entries
            button.removeAllItems()
            for (index, entry) in entries.enumerated() {
                let item: NSMenuItem
                switch entry {
                case .separator:
                    item = .separator()
                case .notSet:
                    item = NSMenuItem(title: Self.title(for: nil), action: nil, keyEquivalent: "")
                case .preset(let name):
                    item = NSMenuItem(title: Self.title(for: name), action: nil, keyEquivalent: "")
                    item.attributedTitle = Self.attributedTitle(for: name, font: button.font)
                }
                item.tag = index
                button.menu?.addItem(item)
            }
        }
        let selected = selection.map(Entry.preset) ?? .notSet
        button.selectItem(at: entries.firstIndex(of: selected) ?? 0)
        button.setAccessibilityLabel(label)
    }

    static func title(for name: String?) -> String {
        name.map(PresetManager.displayName(forPreset:)) ?? "Not set"
    }

    /// Dims the "(default)" suffix of the default preset.
    private static func attributedTitle(for name: String, font: NSFont?) -> NSAttributedString {
        let font = font ?? .menuFont(ofSize: 0)
        let attributed = NSMutableAttributedString(string: name, attributes: [.font: font])
        let suffix = title(for: name).dropFirst(name.count)
        if !suffix.isEmpty {
            attributed.append(NSAttributedString(string: String(suffix), attributes: [
                .font: font,
                .foregroundColor: NSColor.secondaryLabelColor,
            ]))
        }
        return attributed
    }

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: NSPopUpButton, context: Context) -> CGSize? {
        CGSize(width: proposal.width ?? nsView.intrinsicContentSize.width, height: 24)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(selection: $selection)
    }

    @MainActor
    final class Coordinator: NSObject {
        var selection: Binding<String?>
        var entries: [Entry] = []

        init(selection: Binding<String?>) {
            self.selection = selection
            super.init()
        }

        @objc func selectPreset(_ sender: NSPopUpButton) {
            guard let tag = sender.selectedItem?.tag, entries.indices.contains(tag),
                  case .preset(let name) = entries[tag] else { return }
            selection.wrappedValue = name
        }
    }
}
