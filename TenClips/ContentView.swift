import SwiftUI

struct ContentView: View {
    @StateObject private var manager = ClipboardManager()

    var body: some View {
        if manager.items.isEmpty {
            Button("剪贴板空空如也") {}
                .disabled(true)
        } else {
            ForEach(manager.items) { item in
                // 核心修复点：使用纯文本 String 初始化 Button，放弃在 Label 里写 if-else 视图
                let displayTitle = getDisplayTitle(for: item)
                
                Button(displayTitle) {
                    manager.copyToPasteboard(item)
                    
                    // 延迟触发粘贴，等待菜单收起
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        manager.simulatePaste()
                    }
                }
            }
        }
        
        Divider()
        
        Button("清空记录") {
            manager.items.removeAll()
        }
        
        Button("退出 TenClips") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
    
    // MARK: - 辅助方法
    
    /// 将剪贴板内容转换为安全、无换行符的单行文本
    private func getDisplayTitle(for item: ClipboardItem) -> String {
        if item.type == .image {
            return "[图片]"
        } else if let text = item.text {
            // 关键修复：把所有换行符和制表符替换成空格，防止原生菜单渲染崩溃
            let cleanText = text
                .replacingOccurrences(of: "\n", with: " ")
                .replacingOccurrences(of: "\r", with: " ")
                .replacingOccurrences(of: "\t", with: " ")
            
            // 截取前 30 个字符（注意要把 prefix 返回的 Substring 转回 String）
            if cleanText.count > 30 {
                return String(cleanText.prefix(30)) + "..."
            } else {
                return cleanText
            }
        }
        return "未知内容"
    }
}
