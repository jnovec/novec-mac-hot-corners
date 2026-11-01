import AppKit
import ApplicationServices
import Combine
import Foundation

enum CornerID: String, CaseIterable, Codable, Identifiable {
    case topLeft, topRight, bottomLeft, bottomRight

    var id: String { rawValue }

    var title: String {
        switch self {
        case .topLeft: return "Levý horní"
        case .topRight: return "Pravý horní"
        case .bottomLeft: return "Levý dolní"
        case .bottomRight: return "Pravý dolní"
        }
    }

    var dockKey: String {
        switch self {
        case .topLeft: return "tl"
        case .topRight: return "tr"
        case .bottomLeft: return "bl"
        case .bottomRight: return "br"
        }
    }

    static func at(_ point: CGPoint, frame: CGRect, threshold: CGFloat) -> CornerID? {
        let left = abs(point.x - frame.minX) <= threshold
        let right = abs(point.x - frame.maxX) <= threshold
        let bottom = abs(point.y - frame.minY) <= threshold
        let top = abs(point.y - frame.maxY) <= threshold
        if left && top { return .topLeft }
        if right && top { return .topRight }
        if left && bottom { return .bottomLeft }
        if right && bottom { return .bottomRight }
        return nil
    }
}

enum CornerAction: String, Codable, CaseIterable, Identifiable {
    case none, missionControl, appWindows, showDesktop, screenshot, dictation
    case enter, shortcut, terminalCommand, launchApplication

    var id: String { rawValue }
    var label: String {
        switch self {
        case .none: return "Žádná akce"
        case .missionControl: return "Mission Control"
        case .appWindows: return "Zobrazit okna aplikace"
        case .showDesktop: return "Zobrazit plochu"
        case .screenshot: return "Screenshot"
        case .dictation: return "Spustit diktování"
        case .enter: return "Stisknout Enter"
        case .shortcut: return "Klávesová zkratka"
        case .terminalCommand: return "Příkaz v Terminálu"
        case .launchApplication: return "Spustit aplikaci"
        }
    }

    var icon: String {
        switch self {
        case .none: return "minus.circle"
        case .missionControl: return "rectangle.3.group"
        case .appWindows: return "macwindow.on.rectangle"
        case .showDesktop: return "desktopcomputer"
        case .screenshot: return "camera.viewfinder"
        case .dictation: return "mic"
        case .enter: return "return"
        case .shortcut: return "keyboard"
        case .terminalCommand: return "terminal"
        case .launchApplication: return "app"
        }
    }

    var dockValue: Int? {
        switch self {
        case .missionControl: return 2
        case .appWindows: return 3
        case .showDesktop: return 4
        default: return nil
        }
    }
}

struct CornerRule: Codable, Equatable {
    var action: CornerAction = .none
    var enabled: Bool = true
    var shortcut: String = "cmd+shift+5"
    var command: String = ""
    var applicationPath: String = ""

    init(action: CornerAction = .none, enabled: Bool = true) {
        self.action = action
        self.enabled = enabled
    }
}

struct AppConfiguration: Codable {
    var rules: [String: CornerRule]
    var hoverDelay: Double = 0.35

    static var defaults: AppConfiguration {
        AppConfiguration(rules: [
            CornerID.topLeft.rawValue: CornerRule(action: .missionControl),
            CornerID.topRight.rawValue: CornerRule(action: .dictation),
            CornerID.bottomLeft.rawValue: CornerRule(action: .screenshot),
            CornerID.bottomRight.rawValue: CornerRule(action: .enter)
        ])
    }

    func rule(_ id: CornerID) -> CornerRule {
        rules[id.rawValue] ?? CornerRule()
    }
}

struct KeyboardShortcut {
    let key: CGKeyCode
    let flags: CGEventFlags

    static func parse(_ source: String) -> KeyboardShortcut? {
        let normalized = source.lowercased()
            .replacingOccurrences(of: "⌘", with: "cmd+")
            .replacingOccurrences(of: "⇧", with: "shift+")
            .replacingOccurrences(of: "⌥", with: "option+")
            .replacingOccurrences(of: "⌃", with: "control+")
        let parts = normalized.split(separator: "+")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard let last = parts.last else { return nil }
        var flags: CGEventFlags = []
        for part in parts.dropLast() {
            switch part {
            case "cmd", "command", "meta": flags.insert(.maskCommand)
            case "shift": flags.insert(.maskShift)
            case "alt", "opt", "option": flags.insert(.maskAlternate)
            case "ctrl", "control": flags.insert(.maskControl)
            case "fn": flags.insert(.maskSecondaryFn)
            default: return nil
            }
        }
        let keys: [String: CGKeyCode] = [
            "a":0, "b":11, "c":8, "d":2, "e":14, "f":3, "g":5,
            "h":4, "i":34, "j":38, "k":40, "l":37, "m":46,
            "n":45, "o":31, "p":35, "q":12, "r":15, "s":1,
            "t":17, "u":32, "v":9, "w":13, "x":7, "y":16, "z":6,
            "0":29, "1":18, "2":19, "3":20, "4":21, "5":23,
            "6":22, "7":26, "8":28, "9":25,
            "enter":36, "return":36, "esc":53, "escape":53, "space":49,
            "delete":51, "backspace":51, "tab":48,
            "left":123, "right":124, "down":125, "up":126,
            "f1":122, "f2":120, "f3":99, "f4":118, "f5":96,
            "f6":97, "f7":98, "f8":100, "f9":101, "f10":109,
            "f11":103, "f12":111
        ]
        guard let key = keys[last] else { return nil }
        return KeyboardShortcut(key: key, flags: flags)
    }
}

@MainActor
final class CornerStore: ObservableObject {
    private static let configKey = "online.novec.hotcorners.gui.v2"
    @Published var config: AppConfiguration {
        didSet {
            save()
            syncDock()
        }
    }
    @Published var status = "Připraveno"
    private var appliedDock: [CornerID: Int] = [:]

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.configKey),
           let decoded = try? JSONDecoder().decode(AppConfiguration.self, from: data) {
            config = decoded
        } else {
            config = .defaults
        }
    }

    func update(_ corner: CornerID, _ rule: CornerRule) {
        config.rules[corner.rawValue] = rule
    }

    func save() {
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: Self.configKey)
            status = "Nastavení uloženo"
        }
    }

    func resetDefaults() {
        config = .defaults
    }

    func syncDock() {
        var desired: [CornerID: Int] = [:]
        for corner in CornerID.allCases {
            let rule = config.rule(corner)
            desired[corner] = rule.enabled ? (rule.action.dockValue ?? 1) : 1
        }
        guard desired != appliedDock else { return }
        appliedDock = desired
        for corner in CornerID.allCases {
            guard let value = desired[corner] else { continue }
            Self.execute("/usr/bin/defaults", [
                "write", "com.apple.dock", "wvous-\(corner.dockKey)-corner", "-int", "\(value)"
            ])
            Self.execute("/usr/bin/defaults", [
                "write", "com.apple.dock", "wvous-\(corner.dockKey)-modifier", "-int", "0"
            ])
        }
        Self.execute("/usr/bin/killall", ["Dock"])
    }

    static func execute(_ path: String, _ arguments: [String]) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        do {
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus != 0 {
                NSLog("NOVEC: %@ exited with status %d", path, process.terminationStatus)
            }
        } catch {
            NSLog("NOVEC: %@ failed: %@", path, error.localizedDescription)
        }
    }

    func accessibilityGranted() -> Bool { AXIsProcessTrusted() }

    func requestAccessibility() {
        _ = AXIsProcessTrustedWithOptions([
            "AXTrustedCheckOptionPrompt": true
        ] as CFDictionary)
    }
}

func runSelfTest() {
    let frame = CGRect(x: 0, y: 0, width: 1000, height: 800)
    precondition(CornerID.at(CGPoint(x: 1,y:799),frame:frame,threshold:8) == .topLeft)
    precondition(CornerID.at(CGPoint(x:999,y:799),frame:frame,threshold:8) == .topRight)
    precondition(CornerID.at(CGPoint(x:1,y:1),frame:frame,threshold:8) == .bottomLeft)
    precondition(CornerID.at(CGPoint(x:999,y:1),frame:frame,threshold:8) == .bottomRight)
    precondition(CornerID.at(CGPoint(x:400,y:400),frame:frame,threshold:8) == nil)
    precondition(AppConfiguration.defaults.rule(.topRight).action == .dictation)
    precondition(AppConfiguration.defaults.rule(.bottomRight).action == .enter)
    precondition(KeyboardShortcut.parse("fn+d")?.key == 2)
    precondition(KeyboardShortcut.parse("cmd+shift+5")?.key == 23)
    precondition(KeyboardShortcut.parse("bad+key") == nil)
    print("HOT_CORNERS_V02_SELF_TEST_OK")
}
