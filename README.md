# MacCloud

[Nextcloud server](https://nextcloud.com) as a native macOS app for automated tests.
This deploys Nextcloud server with Apache HTTP Server, PHP-FPM and SQLite to temporary directories.
The intended use case are deployments on ephemeral environments like CI runners.

## Features

- **Simple setup**: Uses Homebrew-provided Apache and PHP-FPM (no compilation required).
- **Ephemeral**: Each Nextcloud server deployment is temporary and its data removed when stopped.
- **Multiple versions**: Select from several Nextcloud server versions.
- **Configurable**: Choose which port to run Nextcloud server on.
- **Provisioning**: Nextcloud is auto-configured with "admin/admin" credentials by default.
- **No database server**: SQLite database requires no separate database server.

## Requirements

- macOS with Xcode Command Line Tools
- [Homebrew](https://brew.sh) package manager
- Apache HTTP Server: `brew install httpd`
- PHP with FPM: `brew install php`

## Documentation

Please refer to [the documentation catalog deployed on GitHub pages for further information](https://i2h3.github.io/maccloud/). 

## License

See [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues.

## See Also

- [Nextcloud](https://nextcloud.com) - The Nextcloud project
- [Apache HTTP Server](https://httpd.apache.org) - Apache web server
- [PHP](https://php.net) - PHP programming language
