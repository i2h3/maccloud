# ``MacCloud``

Deploy temporary Nextcloud servers locally for testing.

## Overview

MacCloud packages Apache HTTP Server, PHP-FPM, and Nextcloud server with SQLite into a macOS application bundle. This enables quick deployment of ephemeral Nextcloud servers for automated testing on CI runners and local development environments.

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
