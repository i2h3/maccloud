# MacCloud

[Nextcloud server](https://nextcloud.com) as a macOS app for automated tests.
This packages Apache, PHP-FPM and Nextcloud server with SQLite into a macOS app bundle.
The intended use case are deployments on ephemeral enviroments like CI runners.

## Features

- **Self-contained**: Bundles Apache HTTP Server and PHP-FPM compiled from source
- **Ephemeral**: Each deployment is temporary and completely removed when stopped
- **Multiple versions**: Select from several Nextcloud server versions
- **Configurable**: Choose which port to run on
- **Automatic setup**: Nextcloud is auto-configured with admin/admin credentials
- **No dependencies**: SQLite database requires no separate database server

## How does it work?

You can specify a Nextcloud server version to deploy and at which port it should be made available.
When starting it then, the Nextcloud server release will automatically downloaded from the Nextcloud download server and cached locally for possible reuse later.
A new temporary directory for the ephemeral deployment is created and Nextcloud server is extracted to there.

### Server Components

MacCloud builds and bundles:

1. **Apache HTTP Server 2.4** - Web server with FastCGI support
2. **PHP-FPM 8.4** - PHP with all extensions required by Nextcloud
3. **Nextcloud Server** - Downloaded and cached on-demand

### Deployment Process

When you start a server:

1. Creates a unique temporary directory using a UUID
2. Extracts the Nextcloud archive
3. Generates Apache and PHP-FPM configurations with your specified port
4. Automatically configures Nextcloud with SQLite database
5. Starts PHP-FPM and Apache processes
6. Makes Nextcloud accessible at `http://localhost:<port>/`

When you stop the server:

1. Terminates Apache and PHP-FPM processes
2. Removes the entire temporary directory
3. No persistent state remains

### Default Credentials

All deployments use the same credentials for testing:

- **Username**: `admin`
- **Password**: `admin`

## Building

This project requires Xcode on macOS.

### Build Targets

The project includes three Xcode targets:

1. **Apache**: Compiles Apache HTTP Server from source
2. **PHP**: Compiles PHP-FPM from source
3. **MacCloud**: Main application (depends on Apache and PHP)

### First Build

The first build will:
- Download Apache and PHP sources (~100MB)
- Cache them in `Cache/` for future builds
- Compile Apache and PHP (~10-20 minutes)
- Build the MacCloud application

Subsequent builds are much faster as they use the cached sources.

### Build Cache

Downloaded sources are cached to speed up rebuilds:

```
Cache/
├── httpd-2.4.65.tar.bz2
├── apr-1.7.6.tar.bz2
├── apr-util-1.6.3.tar.bz2
├── pcre2-10.47.tar.bz2
└── php-8.4.3.tar.gz
```

To perform a clean build, remove the `Cache/` directory.

## Usage

1. Launch MacCloud.app
2. Select a Nextcloud version from the dropdown
3. Choose a port number (default: 8080)
4. Click "Start"
5. Access Nextcloud at `http://localhost:<port>/`
6. Log in with admin/admin
7. Click "Stop" when finished

## Documentation

Comprehensive documentation is available in the Xcode documentation catalog:

- **Deployment Architecture**: How MacCloud works under the hood
- **Apache Integration**: Building and configuring Apache
- **PHP Integration**: Building and configuring PHP-FPM
- **Nextcloud Deployment**: The deployment process
- **Server Configuration**: Configuration options and customization

To view documentation in Xcode:
1. Open MacCloud.xcodeproj
2. Select Product → Build Documentation
3. Browse documentation in the Developer Documentation window

## Development

### Project Structure

```
MacCloud/
├── MacCloud/                    # Swift source code
│   ├── ContentView.swift       # Main UI
│   ├── ServerManager.swift     # Server lifecycle management
│   ├── NextcloudServerRepository.swift
│   └── Documentation.docc/     # Documentation catalog
├── Scripts/                     # Build scripts
│   ├── build-apache.sh         # Apache build script
│   └── build-php.sh            # PHP build script
├── MacCloud.xcodeproj/         # Xcode project
└── README.md                    # This file
```

### Requirements

- macOS 14.0 or later
- Xcode 15.0 or later
- ~1GB free disk space for build

### Testing on CI

MacCloud is designed for CI environments:

```yaml
# Example GitHub Actions workflow
- name: Run Tests with MacCloud
  run: |
    # Start MacCloud server
    open -a MacCloud
    # Wait for server to start
    sleep 10
    # Run your tests against localhost:8080
    npm test
```

## License

See [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues.

## See Also

- [Nextcloud](https://nextcloud.com) - The Nextcloud project
- [Apache HTTP Server](https://httpd.apache.org) - Apache web server
- [PHP](https://php.net) - PHP programming language
