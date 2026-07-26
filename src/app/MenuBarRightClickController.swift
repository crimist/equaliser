import AppKit

/// Opens the existing menu bar extra when its status item is right-clicked.
@MainActor
final class MenuBarRightClickController {
    private var eventMonitor: Any?

    func start() {
        guard eventMonitor == nil else { return }

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown) {
            [weak self] event in
            self?.handleRightClick(event) ?? event
        }
    }

    func stop() {
        guard let eventMonitor else { return }
        NSEvent.removeMonitor(eventMonitor)
        self.eventMonitor = nil
    }

    func handleRightClick(_ event: NSEvent) -> NSEvent? {
        guard let button = statusBarButton(at: event) else { return event }
        button.performClick(nil)
        return nil
    }

    private func statusBarButton(at event: NSEvent) -> NSStatusBarButton? {
        var view = event.window?.contentView?.hitTest(event.locationInWindow)

        while let currentView = view {
            if let button = currentView as? NSStatusBarButton {
                return button
            }
            view = currentView.superview
        }

        return nil
    }
}
