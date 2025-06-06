## Configuration

Create a `.env` file with all required variables (see [.env.example](./.env.example))

Update `services/caddy/config/Caddyfile` to match these as well. (TODO: centralize all
configuration in `.env`.)

### HTTPS

TLS certificates should be configured in `Caddyfile` if needed. The default
configuration uses self-signed certificates.

Caddy has strong support for automatically renewing certificates. See the
[docs](https://caddyserver.com/docs/) for all options. It is also possible to fetch
certificates externally (eg using `certbot` on the host) and then mount the certificates
within the proxy container. This will require modifying `services/caddy/compose.yaml`.

## Launching the service

```sh
docker compose up -d --force-rebuild
```

## Testing

The version endpoint can be used as a health check:

```sh
curl -i http://localhost:8001/version
```
