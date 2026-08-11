import SwiftUI

@main
struct TenClipsApp: App {
    @StateObject private var manager = ClipboardManager()

    var body: some Scene {
        MenuBarExtra("TenClips", systemImage: "paperclip") {
            ContentView(manager: manager)
        }
        .menuBarExtraStyle(.window)

        Window("关于 TenClips", id: "aboutWindow") {
            AboutView()
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
    }
}
