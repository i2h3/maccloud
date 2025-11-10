# MacCloud

[Nextcloud server](https://nextcloud.com) as a native macOS app for automated tests.
This packages Apache, PHP-FPM and Nextcloud server with SQLite into a macOS app bundle.
The intended use case are deployments on ephemeral enviroments like CI runners.

## Features

- **Self-contained**: Bundles Apache HTTP Server and PHP-FPM compiled from source.
- **Ephemeral**: Each Nextcloud server deployment is temporary and its data removed when stopped.
- **Multiple versions**: Select from several Nextcloud server versions.
- **Configurable**: Choose which port to run Nextcloud server on.
- **Provisioning**: Nextcloud is auto-configured with "admin/admin" credentials by default.
- **No dependencies**: SQLite database requires no separate database server.

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
