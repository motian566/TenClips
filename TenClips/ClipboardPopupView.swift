import SwiftUI

struct ClipboardPopupView: View {
    @ObservedObject var manager: ClipboardManager

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()
                .opacity(0.45)
                .padding(.horizontal, 14)

            content

            Divider()
                .opacity(0.45)
                .padding(.horizontal, 14)

            footer
        }
        .frame(width: 380)
        .popupSurface()
        .shadow(color: .black.opacity(0.22), radius: 24, x: 0, y: 12)
        .padding(30)
        .fixedSize(horizontal: true, vertical: true)
        .onExitCommand {
            FloatingPanelManager.shared.hide()
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.14))
                Image(systemName: "paperclip")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }
            .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text("TenClips")
                    .font(.system(size: 14, weight: .semibold))
                Text(manager.items.isEmpty ? "等待新的复制内容" : "最近 \(manager.items.count) 条剪贴板记录")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !manager.items.isEmpty {
                Button {
                    withAnimation(.snappy) {
                        manager.items.removeAll()
                    }
                } label: {
                    Image(systemName: "trash")
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .glassControl()
                .help("清空全部记录")
                .accessibilityLabel("清空全部记录")
            }

            Button {
                FloatingPanelManager.shared.hide()
            } label: {
                Image(systemName: "xmark")
                    .fontWeight(.semibold)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .glassControl()
            .help("关闭")
            .accessibilityLabel("关闭")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    @ViewBuilder
    private var content: some View {
        if manager.items.isEmpty {
            VStack(spacing: 11) {
                Image(systemName: "clipboard")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(.secondary)

                VStack(spacing: 4) {
                    Text("剪贴板空空如也")
                        .font(.system(size: 14, weight: .medium))
                    Text("复制文本或图片后会自动出现在这里")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 300)
        } else {
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 8) {
                    ForEach(manager.items) { item in
                        ClipboardMenuRow(item: item) {
                            paste(item)
                        } onDelete: {
                            withAnimation(.snappy) {
                                manager.deleteItem(item)
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .frame(height: 326)
        }
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Image(systemName: "cursorarrow.click")
            Text("点按记录即可粘贴")

            Spacer()

            Text("⌃⌘V")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.primary.opacity(0.06), in: Capsule())

            Text("Esc 关闭")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
    }

    private func paste(_ item: ClipboardItem) {
        manager.copyToPasteboard(item)
        FloatingPanelManager.shared.hide()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            manager.simulatePaste()
        }
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

    @ViewBuilder
    func popupSurface() -> some View {
        let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)
        if #available(macOS 26.0, *) {
            glassEffect(.regular, in: shape)
                .overlay(shape.strokeBorder(Color.primary.opacity(0.08)))
        } else {
            background(.regularMaterial, in: shape)
                .overlay(shape.strokeBorder(Color.white.opacity(0.18)))
        }
    }
}
