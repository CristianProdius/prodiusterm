import SwiftUI
import AppKit

@main
struct ProdiusTermApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .frame(minWidth: 900, minHeight: 600)
                .onAppear {
                    Task {
                        await appState.initialize()
                    }
                }
        }
        .defaultSize(width: 1400, height: 900)
        .commands {
            ProdiusTermCommands(appState: appState)
        }

        WindowGroup("Project", id: "project", for: String.self) { $projectId in
            if let projectId {
                ProjectWindowView(projectId: projectId)
                    .environment(appState)
                    .frame(minWidth: 900, minHeight: 600)
            } else {
                Text("No project selected")
                    .frame(minWidth: 400, minHeight: 300)
            }
        }
        .defaultSize(width: 1400, height: 900)

        Settings {
            SettingsView()
                .environment(appState)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldSaveApplicationState(_ application: NSApplication) -> Bool {
        false
    }

    func applicationShouldRestoreApplicationState(_ application: NSApplication) -> Bool {
        false
    }
}
