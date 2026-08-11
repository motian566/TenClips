import AppKit
import SwiftUI

class FloatingPanelManager {
    static let shared = FloatingPanelManager()
    private var panel: NSPanel?
    
    private var globalEventMonitor: Any?
    private var localEventMonitor: Any?

    private func setupIfNeeded(manager: ClipboardManager) {
        if panel != nil { return }
        
        let contentView = ClipboardPopupView(manager: manager)
        let hostingController = NSHostingController(rootView: contentView)
        
        hostingController.view.wantsLayer = true
        hostingController.view.layer?.backgroundColor = NSColor.clear.cgColor
        hostingController.view.layer?.masksToBounds = false
        
        panel = NSPanel(
            contentRect: .zero,
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )
        panel?.isFloatingPanel = true
        panel?.level = .popUpMenu
        panel?.backgroundColor = NSColor.clear
        panel?.isOpaque = false
        panel?.hasShadow = false
        panel?.isMovableByWindowBackground = true
        panel?.contentView = hostingController.view
    }

    func toggle(manager: ClipboardManager) {
        setupIfNeeded(manager: manager)
        
        guard let panel = panel else { return }
        if panel.isVisible {
            hide()
        } else {
            showAtCursor()
        }
    }

    private func showAtCursor() {
        guard let panel = panel, let contentView = panel.contentView else { return }
        
        contentView.layoutSubtreeIfNeeded()
        let panelSize = contentView.fittingSize
        let mouseLocation = NSEvent.mouseLocation

        let screen = NSScreen.screens.first { NSMouseInRect(mouseLocation, $0.frame, false) } ?? NSScreen.main
        let visibleFrame = screen?.visibleFrame ?? .zero
        let shadowInset: CGFloat = 30

        let desiredX = mouseLocation.x - shadowInset - 18
        let desiredY = mouseLocation.y - panelSize.height + shadowInset + 12
        let maxX = max(visibleFrame.minX, visibleFrame.maxX - panelSize.width)
        let maxY = max(visibleFrame.minY, visibleFrame.maxY - panelSize.height)
        let x = min(max(desiredX, visibleFrame.minX), maxX)
        let y = min(max(desiredY, visibleFrame.minY), maxY)

        panel.setFrame(NSRect(origin: NSPoint(x: x, y: y), size: panelSize), display: true)
        panel.alphaValue = 0
        panel.makeKeyAndOrderFront(nil)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.14
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
        }

        startMonitoringClicks()
    }

    func hide() {
        panel?.orderOut(nil)
        stopMonitoringClicks()
    }
    
    private func startMonitoringClicks() {
        stopMonitoringClicks()
        
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.hide()
        }
        
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let panel = self?.panel, event.window != panel {
                self?.hide()
            }
            return event
        }
    }

    private func stopMonitoringClicks() {
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
            globalEventMonitor = nil
        }
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
    }
}
