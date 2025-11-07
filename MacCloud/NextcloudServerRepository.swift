import Foundation
import os

///
/// A provider for the Nextcloud server archives to deploy.
///
/// Fetches Nextcloud server installation archives on demand from the Nextcloud download server and caches them locally for reuse.
///
struct NextcloudServerRepository {
    private let fileManager = FileManager.default
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "NextcloudServerRepository")
    private let session = URLSession.shared

    ///
    /// Render a Nextcloud server installation archive.
    ///
    /// - Parameters:
    ///     - version: The Nextcloud release to provide.
    ///
    /// - Returns: The local file location.
    ///
    func fetch(_ version: NextcloudServerVersion) async throws -> URL {
        logger.info("Requested Nextcloud version: \(version.id)")

        let cache = try fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let destination = cache.appending(component: version.source.lastPathComponent)

        if fileManager.fileExists(atPath: destination.path(percentEncoded: false)) {
            logger.info("Found requested Nextcloud server version \(version.id) in cache at: \(destination.path(percentEncoded: false))")
        } else {
            logger.info("Fetching Nextcloud server version \(version.id) from download server to: \(destination.path(percentEncoded: false))")
            let request = URLRequest(url: version.source)
            let (url, response) = try await session.download(for: request)
            try fileManager.moveItem(at: url, to: destination)
        }

        logger.info("Providing Nextcloud server version at: \(destination.path(percentEncoded: false))")
        return destination
    }
}
