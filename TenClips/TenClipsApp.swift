import SwiftUI

@main
struct TenClipsApp: App {
    @StateObject private var manager = ClipboardManager()
    
    // 👇 新增：用来控制打开独立窗口的环境变量
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        MenuBarExtra("TenClips", systemImage: "paperclip") {
            // 1. 剪贴板列表
            if manager.items.isEmpty {
                Button("剪贴板空空如也") {}
                    .disabled(true)
            } else {
                ForEach(manager.items) { item in
                    Button(getDisplayTitle(for: item)) {
                        manager.copyToPasteboard(item)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            manager.simulatePaste()
                        }
                    }
                }
            }
            
            Divider()
            
            // 2. 辅助功能提示
            Text("快捷窗快捷键: ⌃⌘V")
                .font(.caption)
            
            Button("清空记录") {
                manager.items.removeAll()
            }
            
            Divider() // 增加一道分割线隔离系统级操作
            
            // 👇 新增：关于按钮
            Button("关于 TenClips") {
                // 打开指定 id 的窗口
                openWindow(id: "aboutWindow")
                // 确保关于窗口弹出时能跳到所有软件的最前面
                NSApp.activate(ignoringOtherApps: true)
            }
            
            Button("退出 TenClips") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        
        // 👇 新增：注册独立的“关于”窗口 Scene
        Window("关于 TenClips", id: "aboutWindow") {
            AboutView()
        }
        // 设置窗口不可缩放，紧贴内容大小
        .windowResizability(.contentSize)
        // 隐藏顶部的标题栏栏（让它更像一个小组件弹窗）
        .windowStyle(.hiddenTitleBar)
    }
    
    // 菜单栏专用的极简文字处理
    private func getDisplayTitle(for item: ClipboardItem) -> String {
        if item.type == .image {
            return "[图片]"
        } else if item.type == .mixed, let text = item.text {
            let cleanText = text.replacingOccurrences(of: "\n", with: " ")
            let preview = cleanText.count > 15 ? String(cleanText.prefix(15)) + "..." : cleanText
            return "[图文] \(preview)"
        } else if let text = item.text {
            let cleanText = text.replacingOccurrences(of: "\n", with: " ")
            return cleanText.count > 25 ? String(cleanText.prefix(25)) + "..." : cleanText
        }
        return "未知内容"
    }
}
