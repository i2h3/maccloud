import SwiftUI

enum ServerState {
    case stopped
    case starting
    case running
    case stopping
}

struct ContentView: View {
    @StateObject private var apacheManager = ApacheManager()
    @State private var serverState: ServerState
    @State private var errorMessage: String?

    init(serverState: ServerState = .stopped) {
        self._serverState = State(initialValue: serverState)
    }

    var body: some View {
        VStack(spacing: 20) {
            switch serverState {
                case .stopped:
                    Text("Apache server is stopped.")
                    
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        start()
                    } label: {
                        Text("Start")
                    }
                    
                case .running:
                    Text("Apache server is running on [http://localhost:8080](http://localhost:8080).")

                    Button {
                        stop()
                    } label: {
                        Text("Stop")
                    }

                default:
                    ProgressView()
            }
        }
        .padding()
    }

    func start() {
        serverState = .starting
        errorMessage = nil
        
        Task {
            do {
                try await apacheManager.start()
                await MainActor.run {
                    serverState = .running
                }
            } catch {
                await MainActor.run {
                    serverState = .stopped
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    func stop() {
        serverState = .stopping
        
        Task {
            await MainActor.run {
                apacheManager.stop()
                serverState = .stopped
            }
        }
    }
}

#Preview("Stopped") {
    ContentView(serverState: .stopped)
}

#Preview("Starting") {
    ContentView(serverState: .starting)
}

#Preview("Running") {
    ContentView(serverState: .running)
}

#Preview("Stopping") {
    ContentView(serverState: .stopping)
}
