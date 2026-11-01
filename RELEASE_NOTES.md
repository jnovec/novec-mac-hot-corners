# NOVEC Mac Hot Corners 0.2.0 — Added GUI

Second public release: a native graphical configuration panel for all four macOS hot corners.

## New in v0.2
- SwiftUI window inspired by the four-corner arrangement, with a visual map and four independent configuration cards.
- Change each corner to Mission Control, show application windows/desktop, Screenshot, system Dictation (Fn+D), Enter, any valid key combination, a Terminal command, launch an app, or disable the corner.
- For custom keyboard shortcuts, enter a form such as cmd+shift+5, ctrl+up or fn+d.
- Select applications using a macOS Open dialog.
- Configurations are saved locally, take effect immediately and remain after reboot.
- Menu bar icon opens settings; login launch runs in the background.
- Adjustable hover dwell with existing 2-second cooldown and one activation per entry.

## Installation
Download **NOVEC-Hot-Corners-v0.2.0-macOS-universal.zip**, unzip it and open **install.command**. The installer saves a backup of any previous version and does not require n8n. Grant Accessibility permission to NOVEC Hot Corners in macOS Privacy & Security. Terminal commands run in Terminal under your user account and can require macOS Automation approval.

## Signing and verification
Universal Intel + Apple Silicon app, compiled and tested by GitHub Actions. The app is ad-hoc signed, not Apple Developer ID signed or notarized; macOS may ask for Open Anyway, and replacing an older executable can require new Accessibility approval. CI validates compiled code, self-test, universal architecture and bundle signature. Real GUI behavior must also be tested interactively on macOS.

The original default actions remain unchanged: Mission Control top-left, Dictation top-right, Screenshot bottom-left, Enter bottom-right. Physical F5 behavior is unchanged.
