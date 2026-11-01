import AppKit
import ApplicationServices
import Foundation

enum Diagnostics {
    static let url = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Logs/NOVEC-HotCorners.log")

    static func write(_ message: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let bytes = Data("\(timestamp) \(message)\n".utf8)
        if !FileManager.default.fileExists(atPath: url.path) {
            _ = FileManager.default.createFile(atPath: url.path, contents: nil)
        }
        guard let file = FileHandle(forWritingAtPath: url.path) else { return }
        file.seekToEndOfFile()
        file.write(bytes)
        file.closeFile()
    }
}

@MainActor
final class CornerMonitor {
    private let store: CornerStore
    private var timer: Timer?
    private var currentCorner: CornerID?
    private var entryTime: Date?
    private var armed = true
    private var lastActivation = Date.distantPast
    private let threshold: CGFloat = 8
    private let cooldown: TimeInterval = 2.0

    init(store: CornerStore) {
        self.store = store
    }

    func start() {
        if !AXIsProcessTrusted() { store.requestAccessibility() }
        Diagnostics.write("v0.2 monitor started; accessibility=\(AXIsProcessTrusted())")
        timer = Timer.scheduledTimer(withTimeInterval: 0.10, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.tick()
            }
        }
    }

    private func tick() {
        let point = NSEvent.mouseLocation
        let hovered = NSScreen.screens.compactMap {
            CornerID.at(point, frame: $0.frame, threshold: threshold)
        }.first

        if hovered != currentCorner {
            currentCorner = hovered
            entryTime = hovered == nil ? nil : Date()
            armed = true
        }

        guard let corner = hovered, let entered = entryTime, armed else { return }
        let rule = store.config.rule(corner)
        guard rule.enabled,
              rule.action != .none,
              rule.action.dockValue == nil,
              Date().timeIntervalSince(entered) >= max(0.2, store.config.hoverDelay),
              Date().timeIntervalSince(lastActivation) >= cooldown else { return }

        armed = false
        lastActivation = Date()
        Diagnostics.write("corner=\(corner.rawValue) action=\(rule.action.rawValue)")
        execute(rule)
    }

    private func execute(_ rule: CornerRule) {
        switch rule.action {
        case .none, .missionControl, .appWindows, .showDesktop:
            return // Native macOS Dock handles these.
        case .screenshot:
            CornerStore.execute("/usr/bin/open", ["-a", "Screenshot"])
            store.status = "Otevřeno: Screenshot"
        case .dictation:
            sendKey(2, flags: .maskSecondaryFn, name: "Fn+D")
        case .enter:
            sendKey(36, flags: [], name: "Enter")
        case .shortcut:
            guard let shortcut = KeyboardShortcut.parse(rule.shortcut) else {
                store.status = "Neplatná klávesová zkratka"
                Diagnostics.write("invalid-shortcut")
                return
            }
            sendKey(shortcut.key, flags: shortcut.flags, name: "Klávesová zkratka")
        case .terminalCommand:
            launchTerminalCommand(rule.command)
        case .launchApplication:
            let path = rule.applicationPath
            guard !path.isEmpty, FileManager.default.fileExists(atPath: path) else {
                store.status = "Aplikace nebyla nalezena"
                return
            }
            if NSWorkspace.shared.open(URL(fileURLWithPath: path)) {
                store.status = "Aplikace spuštěna"
            } else {
                store.status = "Spuštění aplikace selhalo"
            }
        }
    }

    private func sendKey(_ key: CGKeyCode, flags: CGEventFlags, name: String) {
        guard AXIsProcessTrusted() else {
            store.status = "Povol přístupnost pro NOVEC Hot Corners"
            Diagnostics.write("keyboard-event-blocked accessibility=false")
            store.requestAccessibility()
            return
        }
        guard let down = CGEvent(keyboardEventSource: nil, virtualKey: key, keyDown: true),
              let up = CGEvent(keyboardEventSource: nil, virtualKey: key, keyDown: false) else {
            store.status = "Nelze vytvořit klávesovou událost"
            return
        }
        down.flags = flags
        up.flags = flags
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
        store.status = "Odesláno: \(name)"
        Diagnostics.write("key-posted \(name)")
    }

    private func launchTerminalCommand(_ command: String) {
        let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            store.status = "Zadej příkaz pro Terminál"
            return
        }
        // Run ONLY the locally configured command. AppleScript strings are escaped
        // to avoid inserting user input into AppleScript source as executable syntax.
        let escaped = trimmed
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
        let source = "tell application \"Terminal\"\nactivate\ndo script \"\(escaped)\"\nend tell"
        guard let script = NSAppleScript(source: source) else {
            store.status = "Chyba příkazu AppleScript"
            return
        }
        var error: NSDictionary?
        _ = script.executeAndReturnError(&error)
        if let error = error {
            store.status = "Terminál: zkontroluj oprávnění Automatizace"
            Diagnostics.write("terminal-command-failed \(error.count) error fields")
        } else {
            store.status = "Příkaz otevřen v Terminálu"
            Diagnostics.write("terminal-command-started")
        }
    }
}
