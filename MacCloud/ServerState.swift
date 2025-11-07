///
/// State of the local Nextcloud server managed by this app.
///
enum ServerState {
    ///
    /// Nothing is running.
    ///
    case stopped

    ///
    /// Launch of the Nextcloud server is in progress.
    ///
    case starting

    ///
    /// The local Nextcloud server is running.
    ///
    case running

    ///
    /// The Nextcloud server is about to be shut down.
    ///
    case stopping
}
