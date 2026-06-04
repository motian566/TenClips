import SwiftUI

struct AboutView: View {
    // 自动获取当前年份
    private let currentYear = Calendar.current.component(.year, from: Date())
    
    var body: some View {
        VStack(spacing: 20) {
            // 💡 图标区：如果以后有了正式的 App Icon，可以把这里换成 Image("AppIcon")
            Image(nsImage: NSImage(named: NSImage.applicationIconName) ?? NSImage())
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                // 给图标加一点精致的渐变色
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue.opacity(0.8), .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 3)
            
            // 📝 文字介绍区
            VStack(spacing: 6) {
                Text("TenClips")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                
                // 可以配合 Xcode 里的 Version 和 Build 号自动读取
                Text("Version 1.0.0")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Text("一款极简优雅的 macOS 剪贴板管理工具")
                .font(.system(size: 13))
                .multilineTextAlignment(.center)
                .foregroundColor(.primary.opacity(0.8))
                .lineSpacing(4)
            
            // 🔗 开源链接与版权区
            VStack(spacing: 8) {
                Link(destination: URL(string: "https://github.com/motian566/TenClips")!) {
                    HStack(spacing: 6) {
                        Image(systemName: "link")
                        Text("GitHub")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                
                Text("基于 MIT 协议开源")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.8))
            }
            .padding(.top, 10)
            
            // 署名区
            Text("Copyright © \(String(currentYear)) motian566. All rights reserved.")
                .font(.system(size: 10))
                .foregroundColor(.secondary.opacity(0.6))
                .padding(.top, 10)
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 30)
        .frame(width: 320)
        // 锁定关于页面的窗口大小，禁止拉伸变形
        .fixedSize()
        // 添加一点底层材质，让独立窗口也有高级感
        .background(Material.ultraThin)
    }
}
