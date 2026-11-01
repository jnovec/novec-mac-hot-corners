import AppKit
import SwiftUI
import Foundation

@MainActor
final class NOVECAppDelegate: NSObject, NSApplicationDelegate {
    private let store = CornerStore()
    private var monitor: CornerMonitor?
    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        store.syncDock()
        let agent = CornerMonitor(store: store)
        agent.start()
        monitor = agent
        setupMenuBar()

        if !CommandLine.arguments.contains("--background") {
            showSettings(nil)
        }
    }

    private func setupMenuBar() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(
            systemSymbolName: "square.dashed.inset.filled",
            accessibilityDescription: "NOVEC Hot Corners"
        )
        if item.button?.image == nil { item.button?.title = "⌗" }

        let menu = NSMenu()
        let settings = NSMenuItem(
            title: "Nastavení aktivních rohů…",
            action: #selector(showSettings(_:)),
            keyEquivalent: ","
        )
        settings.target = self
        menu.addItem(settings)
        menu.addItem(NSMenuItem.separator())

        let quit = NSMenuItem(
            title: "Ukončit NOVEC Hot Corners",
            action: #selector(quitApplication(_:)),
            keyEquivalent: "q"
        )
        quit.target = self
        menu.addItem(quit)
        item.menu = menu
        statusItem = item
    }

    @objc private func showSettings(_ sender: Any?) {
        if settingsWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 1120, height: 710),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            window.title = "NOVEC Hot Corners — Nastavení"
            window.contentView = NSHostingView(rootView: SettingsView(store: store))
            window.minSize = NSSize(width: 1060, height: 655)
            window.center()
            window.isReleasedWhenClosed = false
            settingsWindow = window
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quitApplication(_ sender: Any?) {
        NSApp.terminate(nil)
    }
}

if CommandLine.arguments.contains("--self-test") {
    runSelfTest()
} else {
    let app = NSApplication.shared
    let delegate = NOVECAppDelegate()
    app.delegate = delegate
    app.run()
}
