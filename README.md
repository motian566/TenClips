# TenClips 📎

一款极简、优雅的 macOS 剪贴板管理工具，将液态玻璃（Liquid Glass）之美融入生产力。

![macOS](https://img.shields.io/badge/macOS-12.0+-000000?style=flat-square&logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.0+-FA7343?style=flat-square&logo=swift)
![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)

## ✨ 特性 (Features)

* **💧 毛玻璃 UI**：精心打磨的超薄毛玻璃材质、折射渐变边框与柔和阴影，带来极具未来感的视觉体验。
* **🚀 极速唤醒**：无论在任何界面，按下 `⌃⌘V` (Control + Command + V) 即可在鼠标光标处瞬间呼出剪贴板面板。
* **🧩 智能图文缝合黑魔法**：完美支持纯文本、纯图片以及**图文混合**记录。针对微信、QQ 等软件“分步写入剪贴板”的特殊机制进行了底层数据镜像缝合，确保粘贴排版 100% 原汁原味。
* **🖱️ 丝滑交互**：固定尺寸悬浮窗，支持内部优雅滚动。每条记录配备独立的精致删除按钮，点击记录即可自动写回剪贴板并模拟粘贴。
* **🖥️ 原生菜单栏支持**：提供便捷的状态栏常驻入口，随时查看、清空记录或查阅关于信息。

## 🛠️ 安装与运行 (Installation)

1.  克隆本项目到本地：
    ```bash
    git clone [https://github.com/你的用户名/TenClips.git](https://github.com/你的用户名/TenClips.git)
    ```
2.  使用 **Xcode** 打开 `TenClips.xcodeproj`。
3.  按 `Cmd + R` 编译并运行项目。

> **⚠️ 注意事项 (Accessibility Permission)** > TenClips 需要模拟 `Cmd + V` 按键来实现“点击自动粘贴”的功能。首次运行后，请前往 Mac 的 **系统设置 -> 隐私与安全性 -> 辅助功能** 中，勾选并允许 TenClips。

## 💻 技术栈 (Tech Stack)

* **框架**: SwiftUI, AppKit
* **语言**: Swift
* **核心 API**: `NSPasteboard`, `NSEvent`, `CGEvent` (用于底层事件监听与模拟按键)

## 📄 开源协议 (License)

本项目基于 **MIT License** 开源。

Copyright (c) 2026 motian566. All rights reserved.

欢迎提交 Pull Request 或 Issue 来一起完善这个项目！如果这个工具提高了你的效率，或者它的 UI 设计启发了你，欢迎给一个 ⭐️ Star！
