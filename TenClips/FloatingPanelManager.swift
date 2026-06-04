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
        
        // 👇 核心修复 1：强行剥夺底层图层的裁剪权限 👇
        hostingController.view.wantsLayer = true
        hostingController.view.layer?.backgroundColor = NSColor.clear.cgColor
        hostingController.view.layer?.masksToBounds = false // 绝对不允许裁剪超出边界的阴影
        
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
        
        // 👇 核心修复 2：在计算尺寸前，强行命令底层完成渲染，确保拿到包含 50px Padding 的真实尺寸
        contentView.layoutSubtreeIfNeeded()
        let panelSize = contentView.fittingSize
        
        let mouseLocation = NSEvent.mouseLocation
        
        // 因为我们加了 50px 的透明边距，为了让面板实体依然贴紧光标，这里需要手动偏移抵消掉
        let x = mouseLocation.x - 75
        let y = mouseLocation.y - panelSize.height + 75
    
        panel.setFrame(NSRect(origin: NSPoint(x: x, y: y), size: panelSize), display: true)
        panel.makeKeyAndOrderFront(nil)
        
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
