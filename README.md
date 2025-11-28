# OpenEm Ingestor Service Deployment

## Configuration

Create a `.env` file with all required variables (see [.env.example](./.env.example))

Detailed documentation about the variables can be found at <https://www.openem.ch/documentation/admin/installation/ingestor>

## Launching the service

```sh
docker compose up -d
```

## Testing

The version endpoint can be used as a health check:

```sh
curl -i http://localhost:8001/version
```

There is also a Swagger documentation page available at <http://localhost:8001/docs/index.html>.

### Reverse Proxy and HTTPS

> If Globus Connect server is installed as described in <https://www.openem.ch/documentation/admin/installation/globus>, the Caddy reverse proxy does not need to be installed.

Update `services/caddy/config/Caddyfile` to match the values in `.env` file. (TODO: centralize all
configuration in `.env`.)

TLS certificates should be configured in `Caddyfile` if needed. The default
configuration uses self-signed certificates.

Caddy has strong support for automatically renewing certificates. See the
[docs](https://caddyserver.com/docs/) for all options. It is also possible to fetch
certificates externally (eg using `certbot` on the host) and then mount the certificates
within the proxy container. This will require modifying `services/caddy/compose.yaml`.

Start the services with the profile `with_proxy` specified:

```sh
docker compose --profile with_proxy up -d 
```
