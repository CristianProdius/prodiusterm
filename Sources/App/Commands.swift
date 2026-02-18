import SwiftUI

struct ProdiusTermCommands: Commands {
    let appState: AppState

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("New Session") {
                Task { @MainActor in
                    _ = await appState.createSession(
                        name: "New Session",
                        projectId: appState.selectedProject?.id
                    )
                }
            }
            .keyboardShortcut("t", modifiers: .command)

            Divider()

            Button("New Project...") {
                // TODO: Show new project sheet
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])
        }

        CommandGroup(replacing: .sidebar) {
            Button("Toggle Sidebar") {
                withAnimation {
                    // Toggle via NSApp
                    NSApp.keyWindow?.contentViewController?.tryToPerform(
                        #selector(NSSplitViewController.toggleSidebar(_:)),
                        with: nil
                    )
                }
            }
            .keyboardShortcut("s", modifiers: [.command, .control])
        }

        CommandMenu("Terminal") {
            Button("Clear Terminal") {
                NotificationCenter.default.post(name: .clearTerminal, object: nil)
            }
            .keyboardShortcut("k", modifiers: .command)

            Button("Search Terminal") {
                NotificationCenter.default.post(name: .searchTerminal, object: nil)
            }
            .keyboardShortcut("f", modifiers: .command)

            Divider()

            Button("Split Pane Horizontally") {
                NotificationCenter.default.post(name: .splitHorizontal, object: nil)
            }
            .keyboardShortcut("d", modifiers: .command)

            Button("Split Pane Vertically") {
                NotificationCenter.default.post(name: .splitVertical, object: nil)
            }
            .keyboardShortcut("d", modifiers: [.command, .shift])
        }
    }
}

extension Notification.Name {
    static let clearTerminal = Notification.Name("clearTerminal")
    static let searchTerminal = Notification.Name("searchTerminal")
    static let splitHorizontal = Notification.Name("splitHorizontal")
    static let splitVertical = Notification.Name("splitVertical")
}
