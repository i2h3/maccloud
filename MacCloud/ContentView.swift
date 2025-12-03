import os
import SwiftUI

struct ContentView: View {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "ContentView")
    private let nextcloudServerRepository = NextcloudServerRepository()
    private let serverManager = ServerManager()

    @State private var deploymentDirectory: URL?
    @State private var error: String?
    @State private var nextcloudVersion: NextcloudServerVersion = availableNextcloudServerVersions.last ?? NextcloudServerVersion("")
    @State private var port: UInt = 8080
    @State private var serverState: ServerState

    init(deploymentDirectory: URL? = nil, error: String? = nil, serverState: ServerState = .stopped) {
        self.deploymentDirectory = deploymentDirectory
        self.error = error
        self.serverState = serverState
    }

    var body: some View {
        VStack(alignment: .leading) {
            Picker("Nextcloud version:", selection: $nextcloudVersion) {
                ForEach(availableNextcloudServerVersions) { version in
                    Text(version.id).tag(version)
                }
            }

            LabeledContent {
                TextField("Port Number", value: $port, format: .number.grouping(.never))
                    .frame(width: 50)
            } label: {
                Text("Port:")
            }

            HStack {
                Text("Status:")

                switch serverState {
                    case .stopped:
                        Text("Nextcloud server is stopped.")
                    case .starting:
                        Text("Nextcloud server is starting…")
                    case .running:
                        Text("Nextcloud server is running on [http://localhost:\(port)](http://localhost:\(port)).")
                    case .stopping:
                        Text("Nextcloud server is stopping…")
                }
            }

            if let error {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")

                    Text(verbatim: error)
                }
                .foregroundStyle(.red)
            }
        }
        .disabled(serverState != .stopped)
        .padding()
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    if serverState == .stopped {
                        start()
                    }

                    if serverState == .running {
                        stop()
                    }

                } label: {
                    switch serverState {
                        case .stopped, .starting:
                            Label("Start", systemImage: "play.fill")
                        case .running, .stopping:
                            Label("Stop", systemImage: "stop.fill")
                    }

                }
                .disabled(serverState == .starting || serverState == .stopping)
            }

            if let deploymentDirectory, serverState == .running {
                ToolbarItemGroup(placement: .secondaryAction) {
                    Button {
                        NSWorkspace.shared.open(deploymentDirectory)
                    } label: {
                        Label("Open deployment folder", systemImage: "folder")
                    }
                }
            }
        }
    }

    func start() {
        logger.info("Starting...")
        serverState = .starting

        Task {
            do {
                let nextcloudServerArchive = try await nextcloudServerRepository.fetch(nextcloudVersion)
                
                // Start the server with the downloaded archive
                try await serverManager.start(nextcloudArchive: nextcloudServerArchive, port: port)
                deploymentDirectory = await serverManager.deploymentDirectory
                serverState = .running
            } catch {
                self.error = error.localizedDescription
                serverState = .stopped
                deploymentDirectory = nil
            }
        }
    }

    func stop() {
        logger.info("Stopping...")
        serverState = .stopping
        
        Task {
            // Stop the server
            await serverManager.stop()
            serverState = .stopped
            deploymentDirectory = nil
        }
    }
}

#Preview("Stopped") {
    ContentView(serverState: .stopped)
        .frame(minWidth: 300, minHeight: 100)
}

#Preview("Starting") {
    ContentView(serverState: .starting)
        .frame(minWidth: 300, minHeight: 100)
}

#Preview("Running") {
    ContentView(deploymentDirectory: FileManager.default.temporaryDirectory, serverState: .running)
        .frame(minWidth: 300, minHeight: 100)
}

#Preview("Stopping") {
    ContentView(serverState: .stopping)
        .frame(minWidth: 300, minHeight: 100)
}

#Preview("Error") {
    ContentView(error: "Something went wrong!", serverState: .stopping)
        .frame(minWidth: 300, minHeight: 100)
}
