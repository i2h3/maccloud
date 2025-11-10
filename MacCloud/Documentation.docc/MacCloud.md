# ``MacCloud``

Deploy ephemeral Nextcloud servers locally for testing.

## Overview

MacCloud provides Apache HTTP Server, PHP-FPM, and Nextcloud server with SQLite in form of a macOS application bundle.
This enables quick deployment of ephemeral Nextcloud servers for automated testing on CI runners and local development environments.
Data is maintained only for the lifetime of the deployment and removed when stopped.

## How To Build

1. Check out this project.
2. Run `./Script/build-apache.sh`. This will download build Apache from source and place it in the project directory.
3. Run `./Script/build-php.sh`. This will download build PHP from source and place it in the project directory.
4. Open the Xcode project to build and run the app. The prebuilt dependencies will be copied into the app bundle. That's it!

Decoupling the build of Apache and PHP simplifies and speeds up the build process a lot.
Keeping things simple and separate from Xcode avoids unnecessary complexity and time wasted.
When working on the actual app, you usually don't want to rebuild those heavy dependencies all the time.

Nextcloud server is not included but loaded on demand because users are abled to select a specific version and shipping every possible one would bloat up the app bundle significantly.

## How It Works

When launching a Nextcloud server through this app, the following things happen:

1. Creates a unique temporary directory using a UUID
2. Extracts the Nextcloud archive
3. Generates Apache and PHP-FPM configurations with your specified port
4. Automatically configures Nextcloud with SQLite database
5. Starts PHP-FPM and Apache processes
6. Makes Nextcloud accessible at `http://localhost:<port>/` with the default credentials of user `admin` with password `admin`.


## Topics

### Getting Started

- <doc:DeploymentArchitecture>
- <doc:ServerConfiguration>

### Server Components

- <doc:ApacheIntegration>
- <doc:PHPIntegration>
- <doc:NextcloudDeployment>

### Application Structure

- ``ContentView``
- ``ServerManager``
- ``ServerState``
- ``NextcloudServerRepository``
- ``NextcloudServerVersion``
