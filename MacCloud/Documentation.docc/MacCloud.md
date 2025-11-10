# ``MacCloud``

Deploy ephemeral Nextcloud servers locally for testing.

## Overview

MacCloud deploys Nextcloud servers with Apache HTTP Server, PHP-FPM, and SQLite to temporary directories.
This enables quick deployment of ephemeral Nextcloud servers for automated testing on CI runners and local development environments.
Data is maintained only for the lifetime of the deployment and removed when stopped.

## Requirements

Before using MacCloud, install the required dependencies using [Homebrew](https://brew.sh):

```bash
brew install httpd php
```

## How To Build

1. Check out this project
2. Open the Xcode project
3. Build and run the app

That's it! MacCloud uses the Apache and PHP-FPM installed by Homebrew on your system.

Nextcloud server is not included in the app bundle but loaded on demand because users can select a specific version, and shipping every possible one would bloat up the app significantly.

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
