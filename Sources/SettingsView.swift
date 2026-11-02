import AppKit
import SwiftUI
import UniformTypeIdentifiers

@MainActor
struct CornerSettingsCard: View {
    @ObservedObject var store: CornerStore
    let corner: CornerID

    private var rule: CornerRule { store.config.rule(corner) }

    private func change(_ update: (inout CornerRule) -> Void) {
        var copy = rule
        update(&copy)
        store.update(corner, copy)
    }

    private var action: Binding<CornerAction> {
        Binding(get: { rule.action }, set: { new in change { $0.action = new } })
    }

    private var enabled: Binding<Bool> {
        Binding(get: { rule.enabled }, set: { new in change { $0.enabled = new } })
    }

    private var shortcut: Binding<String> {
        Binding(get: { rule.shortcut }, set: { new in change { $0.shortcut = new } })
    }

    private var command: Binding<String> {
        Binding(get: { rule.command }, set: { new in change { $0.command = new } })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: rule.action.icon)
                    .foregroundStyle(rule.enabled ? Color.accentColor : .secondary)
                    .frame(width: 21)
                Text(corner.title)
                    .font(.headline)
                Spacer()
                Circle()
                    .fill(rule.enabled ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
            }

            Picker(L10n.text("ui.action"), selection: action) {
                ForEach(CornerAction.allCases) { choice in
                    Text(choice.label).tag(choice)
                }
            }
            .labelsHidden()
            .frame(maxWidth: .infinity)

            Toggle(L10n.text("ui.enabled"), isOn: enabled)
                .toggleStyle(.checkbox)

            if rule.action == .shortcut {
                TextField(L10n.text("ui.shortcutPlaceholder"), text: shortcut)
                    .textFieldStyle(.roundedBorder)
                if KeyboardShortcut.parse(rule.shortcut) == nil {
                    Label(L10n.text("ui.invalidShortcut"), systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else {
                    Text(L10n.text("ui.shortcutExamples"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else if rule.action == .terminalCommand {
                TextField(L10n.text("ui.commandPlaceholder"), text: command)
                    .textFieldStyle(.roundedBorder)
                Text(L10n.text("ui.commandWarning"))
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            } else if rule.action == .launchApplication {
                HStack(spacing: 6) {
                    Text(rule.applicationPath.isEmpty
                         ? L10n.text("ui.applicationNotSelected")
                         : URL(fileURLWithPath: rule.applicationPath).lastPathComponent)
                        .lineLimit(1)
                        .foregroundStyle(rule.applicationPath.isEmpty ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button(L10n.text("ui.choose")) {
                        let panel = NSOpenPanel()
                        panel.title = L10n.text("ui.chooseApp")
                        panel.allowedContentTypes = [.application]
                        panel.allowsOtherFileTypes = false
                        panel.canChooseDirectories = false
                        panel.canChooseFiles = true
                        if panel.runModal() == .OK, let url = panel.url {
                            change { $0.applicationPath = url.path }
                        }
                    }
                    .controlSize(.small)
                }
            } else if rule.action == .dictation {
                Text(L10n.text("ui.dictationInfo"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if rule.action.dockValue != nil {
                Text(L10n.text("ui.nativeActionInfo"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 174, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.primary.opacity(0.09))
        }
    }
}

@MainActor
struct ScreenIllustration: View {
    @ObservedObject var store: CornerStore

    private func icon(_ corner: CornerID) -> String {
        store.config.rule(corner).action.icon
    }

    private func tint(_ corner: CornerID) -> Color {
        store.config.rule(corner).enabled ? Color.accentColor : Color.gray
    }

    var body: some View {
        VStack(spacing: 14) {
            Text(L10n.text("ui.cornerMap"))
                .font(.caption.weight(.semibold))
                .tracking(2)
                .foregroundStyle(.secondary)

            GeometryReader { geo in
                ZStack {
                    RoundedRectangle(cornerRadius: 13)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(nsColor: .windowBackgroundColor),
                                    Color(nsColor: .controlBackgroundColor)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    RoundedRectangle(cornerRadius: 13)
                        .strokeBorder(Color.primary.opacity(0.18), lineWidth: 2)

                    VStack {
                        HStack {
                            badge(.topLeft)
                            Spacer()
                            badge(.topRight)
                        }
                        Spacer()
                        Image(systemName: "macbook")
                            .resizable()
                            .scaledToFit()
                            .frame(width: min(geo.size.width * 0.35, 92))
                            .foregroundStyle(.secondary.opacity(0.35))
                        Text("NOVEC")
                            .font(.caption2.weight(.semibold))
                            .tracking(3)
                            .foregroundStyle(.secondary)
                        Spacer()
                        HStack {
                            badge(.bottomLeft)
                            Spacer()
                            badge(.bottomRight)
                        }
                    }
                    .padding(11)
                }
            }
            .aspectRatio(1.18, contentMode: .fit)

            Text(L10n.text("ui.cornerHint"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private func badge(_ corner: CornerID) -> some View {
        Image(systemName: icon(corner))
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(tint(corner))
            .frame(width: 55, height: 55)
            .background(tint(corner).opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
    }
}

@MainActor
struct SettingsView: View {
    @ObservedObject var store: CornerStore

    private var delay: Binding<Double> {
        Binding(
            get: { store.config.hoverDelay },
            set: { store.config.hoverDelay = $0 }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: "square.dashed.inset.filled")
                    .font(.system(size: 32))
                    .foregroundStyle(.tint)
                    .frame(width: 52, height: 52)
                    .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 5) {
                    Text("NOVEC Hot Corners")
                        .font(.system(size: 26, weight: .bold))
                    Text(L10n.text("ui.subtitle"))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("v0.3")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.primary.opacity(0.06), in: Capsule())
            }

            HStack(alignment: .center, spacing: 20) {
                VStack(spacing: 16) {
                    CornerSettingsCard(store: store, corner: .topLeft)
                    CornerSettingsCard(store: store, corner: .bottomLeft)
                }
                .frame(maxWidth: .infinity)

                ScreenIllustration(store: store)
                    .frame(maxWidth: .infinity)

                VStack(spacing: 16) {
                    CornerSettingsCard(store: store, corner: .topRight)
                    CornerSettingsCard(store: store, corner: .bottomRight)
                }
                .frame(maxWidth: .infinity)
            }

            VStack(alignment: .leading, spacing: 12) {
                Divider()
                HStack {
                    Text(L10n.text("ui.activationDelay"))
                        .font(.subheadline.weight(.medium))
                    Slider(value: delay, in: 0.2...1.5, step: 0.05)
                        .frame(width: 180)
                    Text(String(format: "%.2f s", store.config.hoverDelay))
                        .font(.subheadline.monospacedDigit())
                    Spacer()
                    if store.accessibilityGranted() {
                        Label(L10n.text("ui.accessibilityGranted"), systemImage: "checkmark.shield")
                            .foregroundStyle(.green)
                            .font(.caption)
                    } else {
                        Button(L10n.text("ui.accessibilityRequest")) { store.requestAccessibility() }
                    }
                }
                HStack {
                    Label(store.status, systemImage: "info.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer()
                    Button(L10n.text("ui.reset")) {
                        store.resetDefaults()
                    }
                    Button(L10n.text("ui.save")) {
                        store.save()
                    }
                    .keyboardShortcut("s", modifiers: .command)
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(24)
        .frame(minWidth: 1060, minHeight: 655)
    }
}
