import Foundation

///
/// Represents a specific Nextcloud server release.
///
struct NextcloudServerVersion: Hashable, Identifiable {
    ///
    /// Version identifier of the Nextcloud server release.
    ///
    let id: String

    ///
    /// Generate the download URL based on the version identifier.
    ///
    var source: URL {
        URL(string: "https://download.nextcloud.com/server/releases/nextcloud-\(id).zip")!
    }

    ///
    /// - Parameters:
    ///     - id: Version identifier of the Nextcloud server release.
    ///
    init(_ id: String) {
        self.id = id
    }
}
