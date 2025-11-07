# MacCloud

[Nextcloud server](https://nextcloud.com) as a macOS app for automated tests.
This packages Apache, PHP-FPM and Nextcloud server with SQLite into a macOS app bundle.
The intended use case are deployments on ephemeral enviroments like CI runners.

## How does it work?

You can specify a Nextcloud server version to deploy and at which port it should be made available.
When starting it then, the Nextcloud server release will automatically downloaded from the Nextcloud download server and cached locally for possible reuse later.
A new temporary directory for the ephemeral deployment is created and Nextcloud server is extracted to there.
