# Copilot Instructions for MacCloud

## Project Overview

MacCloud is a macOS application that packages Nextcloud server with Apache, PHP-FPM, and SQLite into a macOS app bundle. The intended use case is for deployments on ephemeral environments like CI runners.

## Project Structure

```
MacCloud/
├── MacCloud/              # Main application source code
│   ├── MacCloudApp.swift  # App entry point
│   ├── ContentView.swift  # Main UI view with server controls
│   └── Assets.xcassets/   # App assets and icons
├── MacCloud.xcodeproj/    # Xcode project configuration
├── README.md              # Project documentation
└── LICENSE                # Project license
```

## Technology Stack

- **Language**: Swift
- **Framework**: SwiftUI
- **Platform**: macOS
- **Build System**: Xcode
- **Server Components**: Apache, PHP-FPM, Nextcloud, SQLite

## Code Conventions

### Swift Style
- Use Swift 5+ features and modern SwiftUI patterns
- Follow Apple's Swift API Design Guidelines
- Use meaningful, descriptive names for variables, functions, and types
- Prefer `let` over `var` when possible for immutability
- Use enum cases for state management (see `ServerState` enum)

### SwiftUI Patterns
- Use `@State` for local view state
- Implement `#Preview` macros for UI component previews
- Keep views focused and composable
- Extract complex logic into separate functions or view models

### Code Organization
- One primary type per file
- Group related functionality together
- Use extensions to organize code by functionality

## Development Guidelines

### Building the Project
This is an Xcode project. To build:
1. Open `MacCloud.xcodeproj` in Xcode
2. Select the appropriate scheme and target
3. Build using Cmd+B or Product > Build

### Running the Application
- Run the app in Xcode using Cmd+R or Product > Run
- The app provides a simple UI to start/stop the Nextcloud server
- Server runs on `http://localhost:8080` when active

### Testing
- Use SwiftUI previews (`#Preview`) for rapid UI iteration
- Test all server states: stopped, starting, running, stopping
- Verify UI responsiveness and state transitions

## Important Notes

### Server State Management
The app uses an enum-based state machine for server lifecycle:
- `.stopped` - Server is not running
- `.starting` - Server is in the process of starting
- `.running` - Server is active and accessible
- `.stopping` - Server is shutting down

When implementing server control logic, ensure proper state transitions and error handling.

### macOS App Bundle Considerations
- This app packages server components within the macOS app bundle
- Consider file paths relative to the app bundle
- Ensure proper permissions for running server processes
- Handle cleanup when the app terminates

### CI/CD Context
Since this app is designed for CI runners:
- Keep the app lightweight and fast to start
- Ensure it can be run in headless or automated environments
- Provide clear logging for debugging in CI contexts
- Consider ephemeral nature of CI environments in design decisions

## Making Changes

### Adding New Features
1. Consider the target use case (automated testing on CI runners)
2. Keep the UI simple and functional
3. Ensure features work in automated environments
4. Update SwiftUI previews when modifying UI

### Modifying Server Integration
- Changes to server lifecycle should update `ServerState` appropriately
- Implement proper error handling and recovery
- Consider timeouts and resource cleanup
- Test with actual Nextcloud server operations

### Dependencies
- Minimize external dependencies to keep the app lightweight
- Use standard Apple frameworks when possible
- Document any new dependencies and their purpose

## Common Tasks

### Adding a New View
1. Create a new Swift file in the `MacCloud/` directory
2. Implement the view using SwiftUI
3. Add `#Preview` macros for different states
4. Import and use in `ContentView` or other parent views

### Modifying Server Behavior
1. Update state management in `ContentView` if needed
2. Implement logic in `start()` and `stop()` functions
3. Consider adding error states if necessary
4. Test state transitions thoroughly

### UI Improvements
1. Follow existing SwiftUI patterns in `ContentView`
2. Maintain consistency with macOS design guidelines
3. Test with SwiftUI previews
4. Ensure accessibility support

## Questions or Issues?
Refer to the [README.md](../README.md) for project overview and the official [Nextcloud documentation](https://nextcloud.com) for server-specific details.
