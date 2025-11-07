import Foundation

struct NextcloudServerVersion: Hashable, Identifiable {
    let id: String

    var source: URL {
        URL(string: "https://download.nextcloud.com/server/releases/nextcloud-\(id).zip")!
    }

    init(_ id: String) {
        self.id = id
    }
}
