import SwiftUI

// MARK: - 1. 快捷窗按钮反馈
struct LiquidGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(10)
            .background(
                Color.primary.opacity(configuration.isPressed ? 0.12 : 0.055),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08))
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - 2. 主视图
struct ClipboardPopupView: View {
    @ObservedObject var manager: ClipboardManager

    var body: some View {
        VStack(spacing: 0) {
            // 🛠️ 顶栏控制区
            HStack {
                Button(action: {
                    withAnimation(.spring()) { manager.items.removeAll() }
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color.primary.opacity(0.7))
                        .frame(width: 26, height: 26)
                        .glassControl()
                }
                .buttonStyle(.plain)
                .help("清空全部记录")

                Spacer()
                Text("TenClips")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(Color.primary.opacity(0.7))
                Spacer()

                Button(action: {
                    FloatingPanelManager.shared.hide()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.primary.opacity(0.7))
                        .frame(width: 26, height: 26)
                        .glassControl()
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 12)
            
            // 📜 剪贴板内容列表
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 10) {
                    if manager.items.isEmpty {
                        Text("剪贴板空空如也")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(.secondary)
                            // 👇 这里同步调小，让空文本在更短的窗口里也能完美居中
                            .frame(height: 180)
                    } else {
                        ForEach(manager.items) { item in
                            ZStack(alignment: .topTrailing) {
                                Button(action: {
                                    manager.copyToPasteboard(item)
                                    FloatingPanelManager.shared.hide()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        manager.simulatePaste()
                                    }
                                }) {
                                    HStack {
                                        if item.type == .text, let text = item.text {
                                            let cleanText = getCleanText(text)
                                            Text(cleanText)
                                                .lineLimit(2)
                                                .multilineTextAlignment(.leading)
                                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                                .foregroundColor(.primary.opacity(0.9))
                                        } else if item.type == .image, item.image != nil {
                                            ClipboardThumbnail(item: item, size: CGSize(width: 220, height: 90))
                                        } else if item.type == .mixed, let text = item.text, item.image != nil {
                                            let cleanText = getCleanText(text)
                                            VStack(alignment: .leading, spacing: 6) {
                                                if !cleanText.isEmpty {
                                                    Text(cleanText)
                                                        .lineLimit(1)
                                                        .multilineTextAlignment(.leading)
                                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                                        .foregroundColor(.primary.opacity(0.9))
                                                }
                                                ClipboardThumbnail(item: item, size: CGSize(width: 220, height: 70))
                                            }
                                        }
                                        Spacer(minLength: 30)
                                    }
                                }
                                .buttonStyle(LiquidGlassButtonStyle())
                                
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        manager.deleteItem(item)
                                    }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 15))
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                                .contentShape(Circle())
                                .zIndex(1)
                                .padding(.top, 8)
                                .padding(.trailing, 8)
                            }
                        }
                    }
                }
                .padding(.horizontal, 2)
                .padding(.bottom, 4)
            }
            // 👇 这里将之前的 360 缩短成了 240，让面板变得更精致紧凑
            .frame(height: 240)
        }
        .padding(16)
        .frame(width: 320)
        .background(
            .regularMaterial,
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.1))
        )
        .shadow(color: Color.black.opacity(0.25), radius: 25, x: 0, y: 15)
        .padding(85)
        .fixedSize(horizontal: true, vertical: true)
    }
    
    private func getCleanText(_ rawText: String) -> String {
        return rawText
            .replacingOccurrences(of: "\u{FFFC}", with: "")
            .replacingOccurrences(of: "\u{FFFD}", with: "")
            .components(separatedBy: .newlines)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private extension View {
    @ViewBuilder
    func glassControl() -> some View {
        if #available(macOS 26.0, *) {
            glassEffect(.regular.interactive(), in: Circle())
        } else {
            background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().strokeBorder(Color.white.opacity(0.18)))
        }
    }
}
