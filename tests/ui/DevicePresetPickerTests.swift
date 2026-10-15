import AppKit
import SwiftUI
import XCTest
@testable import Equaliser

@MainActor
final class DevicePresetPickerTests: XCTestCase {
    func testControlWidthDoesNotDependOnSelectedTitle() throws {
        let selections: [String?] = [nil, "Flat", "A much longer preset name"]
        for selection in selections {
            let host = NSHostingView(rootView: DevicePresetPicker(
                names: ["Flat", "A much longer preset name"],
                selection: .constant(selection),
                label: "Preset for speakers"
            ).frame(width: 160, height: 24))
            host.frame = NSRect(x: 0, y: 0, width: 160, height: 24)
            host.layoutSubtreeIfNeeded()

            let button = try XCTUnwrap(popup(in: host))
            XCTAssertEqual(button.frame.width, 160, accuracy: 1)
            XCTAssertEqual(button.title, DevicePresetPicker.title(for: selection))
        }
    }

    func testSelectingPresetUpdatesBinding() throws {
        var selection: String? = "Flat"
        let host = NSHostingView(rootView: DevicePresetPicker(
            names: ["DUSK", "Flat"],
            selection: Binding(get: { selection }, set: { selection = $0 }),
            label: "Preset for headphones"
        ).frame(width: 160, height: 24))
        host.frame = NSRect(x: 0, y: 0, width: 160, height: 24)
        host.layoutSubtreeIfNeeded()
        let button = try XCTUnwrap(popup(in: host))

        // Default first, then a separator, then the rest.
        XCTAssertEqual(button.itemTitles, ["Flat (default)", "", "DUSK"])
        button.selectItem(at: 2)
        button.sendAction(button.action, to: button.target)
        XCTAssertEqual(selection, "DUSK")
        XCTAssertEqual(button.frame.width, 160, accuracy: 1)
    }

    func testNotSetOnlyShownWithoutDefaultPreset() throws {
        let host = NSHostingView(rootView: DevicePresetPicker(
            names: ["DUSK"],
            selection: .constant(nil),
            label: "Preset for speakers"
        ).frame(width: 160, height: 24))
        host.frame = NSRect(x: 0, y: 0, width: 160, height: 24)
        host.layoutSubtreeIfNeeded()
        let button = try XCTUnwrap(popup(in: host))
        XCTAssertEqual(button.titleOfSelectedItem, "Not set")
    }

    private func popup(in view: NSView) -> NSPopUpButton? {
        if let button = view as? NSPopUpButton { return button }
        return view.subviews.lazy.compactMap { self.popup(in: $0) }.first
    }
}
