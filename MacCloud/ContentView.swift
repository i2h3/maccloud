import SwiftUI

enum ServerState {
    case stopped
    case starting
    case running
    case stopping
}

struct ContentView: View {
    @State private var serverState: ServerState

    init(serverState: ServerState = .stopped) {
        self.serverState = serverState
    }

    var body: some View {
        VStack {
            switch serverState {
                case .stopped:
                    Text("Nextcloud server is stopped.")

                    Button {
                        start()
                    } label: {
                        Text("Start")
                    }
                    
                case .running:
                    Text("Nextcloud server is running on [http://localhost:8080](http://localhost:8080).")

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

    func start() {}

    func stop() {}
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
