import SwiftUI
import AppKit

struct NewProjectSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    let onCreate: ((Project) -> Void)?
    @State private var name = ""
    @State private var workingDirectory = ""

    init(onCreate: ((Project) -> Void)? = nil) {
        self.onCreate = onCreate
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("New Project")
                .font(.headline)

            Form {
                TextField("Name", text: $name)
                HStack {
                    TextField("Working Directory", text: $workingDirectory)
                    Button("Choose...") {
                        chooseDirectory()
                    }
                }
            }
            .formStyle(.grouped)

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Create") {
                    Task {
                        if let project = await appState.createProject(
                            name: name,
                            workingDirectory: workingDirectory
                        ) {
                            onCreate?(project)
                        }
                        dismiss()
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty || workingDirectory.isEmpty)
            }
        }
        .padding()
        .frame(width: 400)
    }

    private func chooseDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            workingDirectory = url.path
            if name.isEmpty {
                name = url.lastPathComponent
            }
        }
    }
}
