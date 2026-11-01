import AppKit
import ApplicationServices
import Foundation

/// User-session-only helper. macOS handles the top-left Mission Control corner.
private enum Corner: Equatable {
    case bottomLeft
    case topRight
    case bottomRight

    static func at(_ point: CGPoint, in frame: CGRect, threshold: CGFloat) -> Corner? {
        let left = abs(point.x - frame.minX) <= threshold
        let right = abs(point.x - frame.maxX) <= threshold
        let bottom = abs(point.y - frame.minY) <= threshold
        let top = abs(point.y - frame.maxY) <= threshold

        if left && bottom { return .bottomLeft }
        if right && top { return .topRight }
        if right && bottom { return .bottomRight }
        return nil
    }
}

/// Local, non-sensitive operational diagnostics; writes only state transitions.
private enum Diagnostics {
    static let url = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Logs/NOVEC-HotCorners.log")
    static func log(_ message: String) {
        let stamp = ISO8601DateFormatter().string(from: Date())
        let data = Data("\(stamp) \(message)\n".utf8)
        let fm = FileManager.default
        if !fm.fileExists(atPath: url.path) {
            _ = fm.createFile(atPath: url.path, contents: nil)
        }
        guard let handle = FileHandle(forWritingAtPath: url.path) else { return }
        handle.seekToEndOfFile()
        handle.write(data)
        handle.closeFile()
    }
}

@MainActor
final class HotCorners {
    private var currentCorner: Corner?
    private var enteredAt: Date?
    private var armed = true
    private var lastActivation = Date.distantPast
    private let threshold: CGFloat = 8
    private let dwell: TimeInterval = 0.35
    private let cooldown: TimeInterval = 2.0
    private var timer: Timer?
    private var lastHeartbeat = Date.distantPast
    func run() {
        _ = NSApplication.shared
        NSApp.setActivationPolicy(.accessory)
        let trusted = AXIsProcessTrusted()
        Diagnostics.log("started pid=\(ProcessInfo.processInfo.processIdentifier) screens=\(NSScreen.screens.count) accessibility=\(trusted)")
        if !trusted {
            Diagnostics.log("permission-required for Fn-D/Return; requesting macOS Accessibility consent")
            // Official macOS consent UI. A user must approve; never modify the TCC database.
            _ = AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
        }
        timer = Timer.scheduledTimer(withTimeInterval: 0.10, repeats: true) { [self] _ in
            MainActor.assumeIsolated { tick() }
        }
        RunLoop.main.run()
    }

    private func tick() {
        if Date().timeIntervalSince(lastHeartbeat) > 60 {
            lastHeartbeat = Date()
            Diagnostics.log("heartbeat screens=\(NSScreen.screens.count) accessibility=\(AXIsProcessTrusted())")
        }
        let point = NSEvent.mouseLocation
        let corner = NSScreen.screens.compactMap {
            Corner.at(point, in: $0.frame, threshold: threshold)
        }.first

        if corner != currentCorner {
            if let corner { Diagnostics.log("corner-enter \(corner)") }
            currentCorner = corner
            enteredAt = corner == nil ? nil : Date()
            armed = true
        }

        guard let corner, armed, let enteredAt,
              Date().timeIntervalSince(enteredAt) >= dwell,
              Date().timeIntervalSince(lastActivation) >= cooldown else { return }

        // One activation per entry; re-arm only after moving away or to another corner.
        armed = false
        lastActivation = Date()
        Diagnostics.log("corner-activate \(corner)")
        switch corner {
        case .bottomLeft:
            launchScreenshot()
        case .topRight:
            startDictation()
        case .bottomRight:
            sendKey(36, name: "Return")   // kVK_Return (regular Enter)
        }
    }

    private func launchScreenshot() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        task.arguments = ["-a", "Screenshot"]
        do {
            try task.run()
            Diagnostics.log("screenshot-open-requested")
        } catch {
            Diagnostics.log("screenshot-failed \(error.localizedDescription)")
        }
    }

    // Apple's system-wide Fn-D starts or stops Dictation without
    // remapping the physical F5 microphone key.
    private func startDictation() {
        guard AXIsProcessTrusted() else {
            Diagnostics.log("dictation-blocked accessibility=false")
            return
        }
        let dKey: CGKeyCode = 2  // kVK_ANSI_D
        guard let down = CGEvent(keyboardEventSource: nil, virtualKey: dKey, keyDown: true),
              let up = CGEvent(keyboardEventSource: nil, virtualKey: dKey, keyDown: false) else {
            Diagnostics.log("dictation-key-create-failed")
            return
        }
        down.flags = .maskSecondaryFn
        up.flags = .maskSecondaryFn
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
        Diagnostics.log("dictation-shortcut-posted Fn-D")
    }

    private func sendKey(_ keyCode: CGKeyCode, name: String) {
        guard AXIsProcessTrusted() else {
            Diagnostics.log("key-blocked \(name) accessibility=false")
            return
        }
        guard let down = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true),
              let up = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false) else {
            Diagnostics.log("key-event-create-failed \(name)")
            return
        }
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
        Diagnostics.log("key-posted \(name)")
    }
}

/// Test corner mapping without moving the cursor or generating input events.
private func runSelfTest() {
    let frame = CGRect(x: 0, y: 0, width: 1000, height: 800)
    precondition(Corner.at(CGPoint(x: 1, y: 1), in: frame, threshold: 8) == .bottomLeft)
    precondition(Corner.at(CGPoint(x: 999, y: 799), in: frame, threshold: 8) == .topRight)
    precondition(Corner.at(CGPoint(x: 999, y: 1), in: frame, threshold: 8) == .bottomRight)
    precondition(Corner.at(CGPoint(x: 1, y: 799), in: frame, threshold: 8) == nil)
    precondition(Corner.at(CGPoint(x: 500, y: 400), in: frame, threshold: 8) == nil)
    print("HOT_CORNERS_SELF_TEST_OK")
}

if CommandLine.arguments.contains("--self-test") {
    runSelfTest()
} else {
    // Keep a strong reference alive for the entire user session.
    MainActor.assumeIsolated {
        let agent = HotCorners()
        agent.run()
    }
}
