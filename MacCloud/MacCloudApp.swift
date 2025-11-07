import SwiftUI

@main
struct MacCloudApp: App {
    var body: some Scene {
        Window("MacCloud", id: "main") {
            ContentView()
        }
        .windowResizability(.contentMinSize)
    }
}
