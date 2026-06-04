import AppKit
import Combine
import SwiftUI

struct ClipboardItem: Identifiable, Equatable {
    let id = UUID()
    let type: ItemType
    let text: String?
    let image: NSImage?
    let rawData: [[NSPasteboard.PasteboardType: Data]]
    let timestamp: Date

    enum ItemType {
        case text, image, mixed
    }

    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        lhs.id == rhs.id
    }
}

class ClipboardManager: ObservableObject {
    @Published var items: [ClipboardItem] = []
    
    private var lastChangeCount = NSPasteboard.general.changeCount
    private var timer: AnyCancellable?
    private let maxItems = 10

    init() {
        timer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.checkPasteboard() }
        
        let targetModifiers: NSEvent.ModifierFlags = [.control, .command]

        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if flags == targetModifiers && event.keyCode == 9 {
                if let self = self { FloatingPanelManager.shared.toggle(manager: self) }
            }
        }
        
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if flags == targetModifiers && event.keyCode == 9 {
                if let self = self { FloatingPanelManager.shared.toggle(manager: self) }
                return nil
            }
            return event
        }
        
        requestAccessibilityPermission()
    }

    private func checkPasteboard() {
        let pb = NSPasteboard.general
        guard pb.changeCount != lastChangeCount else { return }
        lastChangeCount = pb.changeCount
        readPasteboard(pb)
    }

    private func readPasteboard(_ pb: NSPasteboard) {
        guard let pbItems = pb.pasteboardItems, !pbItems.isEmpty else { return }
        
        var rawDataArray: [[NSPasteboard.PasteboardType: Data]] = []
        for item in pbItems {
            var itemDict: [NSPasteboard.PasteboardType: Data] = [:]
            for type in item.types {
                if let data = item.data(forType: type) {
                    itemDict[type] = data
                }
            }
            rawDataArray.append(itemDict)
        }
        
        var foundText: String? = pb.string(forType: .string)
        
        if foundText == nil || foundText!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if let rtfData = pb.data(forType: .rtf),
               let attrStr = NSAttributedString(rtf: rtfData, documentAttributes: nil) {
                foundText = attrStr.string
            } else if let htmlData = pb.data(forType: .html),
                      let attrStr = NSAttributedString(html: htmlData, documentAttributes: nil) {
                foundText = attrStr.string
            }
        }
        
        if let text = foundText {
            let clean = text.replacingOccurrences(of: "\u{FFFC}", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            if clean.isEmpty || clean.hasPrefix("file:///") {
                foundText = nil
            }
        }

        var foundImage: NSImage?
        if let images = pb.readObjects(forClasses: [NSImage.self], options: nil) as? [NSImage], let firstImage = images.first {
            foundImage = firstImage
        }
        
        DispatchQueue.main.async {
            let itemType: ClipboardItem.ItemType
            if foundText != nil && foundImage != nil {
                itemType = .mixed
            } else if foundText != nil {
                itemType = .text
            } else if foundImage != nil {
                itemType = .image
            } else {
                return
            }
            
            let newItem = ClipboardItem(type: itemType, text: foundText, image: foundImage, rawData: rawDataArray, timestamp: Date())
            self.appendItem(newItem)
        }
    }

    private func appendItem(_ item: ClipboardItem) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if let first = items.first {
                if first.type == item.type {
                    if item.type == .text && first.text == item.text { return }
                    let oldSize = first.rawData.first?.values.first?.count ?? 0
                    let newSize = item.rawData.first?.values.first?.count ?? 0
                    if (item.type == .image || item.type == .mixed) && oldSize > 0 && oldSize == newSize { return }
                }
                
                if first.type == .text && item.type == .mixed && first.text == item.text {
                    items[0] = item
                    return
                }
                if first.type == .image && item.type == .mixed {
                    let oldSize = first.rawData.first?.values.first?.count ?? 0
                    let newSize = item.rawData.first?.values.first?.count ?? 0
                    if oldSize > 0 && oldSize == newSize {
                        items[0] = item
                        return
                    }
                }
                
                let timeDiff = Date().timeIntervalSince(first.timestamp)
                if timeDiff < 0.8 {
                    if first.type == .text && item.type == .image {
                        let stitchedItem = ClipboardItem(type: .mixed, text: first.text, image: item.image, rawData: first.rawData + item.rawData, timestamp: Date())
                        items[0] = stitchedItem
                        return
                    }
                    if first.type == .image && item.type == .text {
                        let stitchedItem = ClipboardItem(type: .mixed, text: item.text, image: first.image, rawData: item.rawData + first.rawData, timestamp: Date())
                        items[0] = stitchedItem
                        return
                    }
                }
            }
            
            items.insert(item, at: 0)
            if items.count > maxItems { items.removeLast() }
        }
    }

    func copyToPasteboard(_ item: ClipboardItem) {
        let pb = NSPasteboard.general
        pb.clearContents()
        
        var restoredItems: [NSPasteboardItem] = []
        for rawDict in item.rawData {
            let pbItem = NSPasteboardItem()
            for (type, data) in rawDict {
                pbItem.setData(data, forType: type)
            }
            restoredItems.append(pbItem)
        }
        
        pb.writeObjects(restoredItems)
        lastChangeCount = pb.changeCount
    }
    
    // 👇 新增：删除单条记录的方法
    func deleteItem(_ item: ClipboardItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items.remove(at: index)
        }
    }
    
    func requestAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        if !accessEnabled {
            print("请在系统设置 -> 隐私与安全性 -> 辅助功能 中勾选 TenClips")
        }
    }

    func simulatePaste() {
        let vKeyCode: CGKeyCode = 9
        guard let cmdDown = CGEvent(keyboardEventSource: nil, virtualKey: vKeyCode, keyDown: true),
              let cmdUp = CGEvent(keyboardEventSource: nil, virtualKey: vKeyCode, keyDown: false) else { return }
        cmdDown.flags = .maskCommand
        cmdUp.flags = .maskCommand
        cmdDown.post(tap: .cghidEventTap)
        cmdUp.post(tap: .cghidEventTap)
    }
}
