import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @State private var terminalManager = TerminalSessionManager()

    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 200, ideal: 260, max: 400)
        } detail: {
            if let session = appState.selectedSession {
                TerminalContainerView(
                    session: session,
                    terminalManager: terminalManager
                )
            } else {
                WelcomeView()
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}

struct WelcomeView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "terminal")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("ProdiusTerm")
                .font(.largeTitle)
                .fontWeight(.semibold)

            Text("Create a new session to get started")
                .foregroundStyle(.secondary)

            Button("New Session") {
                Task {
                    _ = await appState.createSession(
                        name: "New Session",
                        projectId: appState.selectedProject?.id
                    )
                }
            }
            .keyboardShortcut("t", modifiers: .command)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}
