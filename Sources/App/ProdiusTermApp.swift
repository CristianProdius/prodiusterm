import SwiftUI

@main
struct ProdiusTermApp: App {
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

        Settings {
            SettingsView()
                .environment(appState)
        }
    }
}
