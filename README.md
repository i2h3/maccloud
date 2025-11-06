# MacCloud

[Nextcloud server](https://nextcloud.com) as a macOS app for automated tests.
This packages Apache, PHP-FPM and Nextcloud server with SQLite into a macOS app bundle.
The intended use case are deployments on ephemeral environments like CI runners.

## Current Status

**Phase 1 Complete**: Apache HTTP Server 2.4 integration
- ✅ Apache HTTP Server bundled in app
- ✅ Start/Stop functionality via SwiftUI interface
- ✅ Serves static "Hello, World!" page
- ✅ Runs on http://localhost:8080

## Building

### Prerequisites

- macOS 14.0 or later
- Xcode 15.0 or later
- Apache HTTP Server (install via `brew install httpd` if not using system Apache)

### Build Steps

1. Clone the repository
2. Open `MacCloud.xcodeproj` in Xcode
3. Build the project (⌘B)
   - The build script will automatically copy Apache binaries to the app bundle
4. Run the application (⌘R)

## Usage

1. Launch MacCloud
2. Click "Start" to start the Apache server
3. Open http://localhost:8080 in your browser to see the "Hello, World!" page
4. Click "Stop" to stop the Apache server

## Architecture

See [APACHE_INTEGRATION.md](APACHE_INTEGRATION.md) for detailed documentation on how Apache is integrated into the app bundle.

## Roadmap

- [x] Phase 1: Apache HTTP Server integration
- [ ] Phase 2: PHP-FPM integration
- [ ] Phase 3: SQLite database integration
- [ ] Phase 4: Nextcloud server integration
