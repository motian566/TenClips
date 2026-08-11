import AppKit
import SwiftUI

struct ContentView: View {
    @ObservedObject var manager: ClipboardManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 0) {
            header

            if manager.items.isEmpty {
                emptyState
            } else {
                ScrollView {
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
                .frame(maxHeight: 430)
            }

            Divider()
                .opacity(0.55)

            footer
        }
        .frame(width: 360)
        .background(.regularMaterial)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "paperclip")
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 30, height: 30)
                .liquidGlass(in: Circle())

            VStack(alignment: .leading, spacing: 1) {
                Text("TenClips")
                    .font(.headline)
                Text(manager.items.isEmpty ? "最近没有复制内容" : "最近 \(manager.items.count) 条记录")
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
                .liquidGlassButton()
                .help("清空记录")
                .accessibilityLabel("清空记录")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "clipboard")
                .font(.system(size: 30, weight: .light))
                .foregroundStyle(.secondary)
            Text("剪贴板空空如也")
                .font(.system(size: 14, weight: .medium))
            Text("复制文本或图片后会显示在这里")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 190)
    }

    private var footer: some View {
        HStack(spacing: 6) {
            Label("⌃⌘V 打开快捷窗", systemImage: "keyboard")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Button("关于") {
                dismiss()
                openWindow(id: "aboutWindow")
                NSApp.activate(ignoringOtherApps: true)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .liquidGlass(in: Capsule())

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Image(systemName: "power")
                    .frame(width: 27, height: 27)
            }
            .buttonStyle(.plain)
            .liquidGlassButton()
            .help("退出 TenClips")
            .accessibilityLabel("退出 TenClips")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func paste(_ item: ClipboardItem) {
        manager.copyToPasteboard(item)
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            manager.simulatePaste()
        }
    }
}

struct ClipboardMenuRow: View {
    let item: ClipboardItem
    let action: () -> Void
    let onDelete: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 10) {
            Button(action: action) {
                HStack(spacing: 10) {
                    ClipboardThumbnail(item: item, size: CGSize(width: 68, height: 54))

                    VStack(alignment: .leading, spacing: 5) {
                        Text(item.menuTitle)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        HStack(spacing: 5) {
                            Image(systemName: item.type.symbolName)
                            Text(item.timestamp, style: .relative)
                        }
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    }

                    Spacer(minLength: 4)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isHovering {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("删除这条记录")
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(9)
        .frame(minHeight: 72)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isHovering ? Color.primary.opacity(0.085) : Color.primary.opacity(0.04))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(isHovering ? 0.12 : 0.06))
        }
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.14)) {
                isHovering = hovering
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint("点按以粘贴")
    }
}

struct ClipboardThumbnail: View {
    let item: ClipboardItem
    let size: CGSize

    var body: some View {
        Group {
            if let image = item.image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .accessibilityLabel(item.type == .mixed ? "图文缩略图" : "图片缩略图")
            } else {
                ZStack {
                    Color.accentColor.opacity(0.1)
                    Image(systemName: "text.alignleft")
                        .font(.system(size: min(size.width, size.height) * 0.30, weight: .medium))
                        .foregroundStyle(Color.accentColor.opacity(0.8))
                }
                .accessibilityHidden(true)
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.1))
        }
    }
}

extension ClipboardItem {
    var menuTitle: String {
        guard let text else {
            return type == .image ? "图片" : "未知内容"
        }

        let cleanText = text
            .replacingOccurrences(of: "\u{FFFC}", with: "")
            .replacingOccurrences(of: "\u{FFFD}", with: "")
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        if cleanText.isEmpty {
            return type == .mixed ? "图片和文本" : "文本"
        }
        return cleanText.count > 64 ? String(cleanText.prefix(64)) + "…" : cleanText
    }
}

extension ClipboardItem.ItemType {
    var symbolName: String {
        switch self {
        case .text: "text.alignleft"
        case .image: "photo"
        case .mixed: "photo.on.rectangle.angled"
        }
    }
}

private extension View {
    @ViewBuilder
    func liquidGlass<S: Shape>(in shape: S) -> some View {
        if #available(macOS 26.0, *) {
            glassEffect(.regular, in: shape)
        } else {
            background(.ultraThinMaterial, in: shape)
                .overlay(shape.stroke(Color.white.opacity(0.18)))
        }
    }

    @ViewBuilder
    func liquidGlassButton() -> some View {
        if #available(macOS 26.0, *) {
            glassEffect(.regular.interactive(), in: Circle())
        } else {
            background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().strokeBorder(Color.white.opacity(0.18)))
        }
    }
}
