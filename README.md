# OpenEm Ingestor Service Deployment

## Quick start

This section explains how to set up a typical ingestor configuration using the globus
proxy (ExtGlobus).

Before starting you will need to set up
- A domain name
- A TLS certificate (optional; for https support if you use the proxy)
- Globus Connect Server
- Register with PSI (scicat-help@lists.psi.ch). They will provide:
    - KEYCLOAK_CLIENT_ID for OIDC authentication
    - GLOBUS_SOURCE_FACILITY for use with the psi globus proxy

Create a `.env` file. Start with all variables from [.env.example](./.env.example):

```sh
cp .env.example .env
nano .env
```

Update all variables for your facility. This is normally the only file that needs to be
changed, but see the Configuration section below for advanced usage.

Now start the service. A wrapper is provided called `compose.sh`, which includes the
correct environment files for the PSI SciCat deployments. The `qa` deployment is
recommended to start, or omit the deployment name to launch `dev`, `qa`, and `prod`
environments.

```sh
# Equivalent to `docker compose up -d` with configuration options
compose.sh qa up -d
```

Test it:

```
curl -o - http://localhost:8081/version
```

You should now be able to connect to it from SciCat.


## Deployments

PSI provides three SciCat deployments: `dev`, `qa`, and `production`. Pre-defined env
files are included to make connecting to these straightforward.

| Environment | Scicat frontend URL                  | Port | Proxy Path |
| ----------- | ------------------------------------ | ---- | ---------- |
| dev         | https://discovery.development.psi.ch | 8080 | /dev       |
| qa          | https://discovery-qa.psi.ch          | 8081 | /qa        |
| production  | https://discovery.psi.ch             | 8082 | /          |


## Configuration

Configuration is split among several files for convenience. The script `compose.sh` merges
these in the following order (later files overwrite earlier files):

1. `services/ingestor/config/$DEPLOYMENT/env.$DEPLOYMENT` - SciCat settings for the chosen environment
2. `.env` - Facility settings shared among environments
3. `.env.$DEPLOYMENT` - Override specific variables for one deployment

Usually only `.env` needs to be changed. See `.env.example` for expected starting
values.

Some variables are used to create the configuration file, while others are passed to the
ingestor at runtime. Detailed documentation about runtime variables can be found at
<https://www.openem.ch/documentation/admin/installation/ingestor>


## Launching the service

To restart all ingestor services:

```sh
./compose.sh down
./compose.sh up -d
```

To send commands to only some deployments, list them before the compose command:

```sh
./compose.sh dev logs -f
./compose.sh production dev qa down
# 'all' is an alias for 'production qa dev'
./compose.sh all up -d --force-recreate
```

If you also want to use the proxy (see below), add `proxy` to the deployment list:

```sh
./compose.sh proxy all up -d
```

## Testing

The version endpoint can be used as a health check:

```sh
# dev
curl -i http://localhost:8080/version
# qa
curl -i http://localhost:8081/version
# production
curl -i http://localhost:8082/version
```

There is also a Swagger documentation page available at <http://localhost:8081/docs/index.html>.


### Reverse Proxy and HTTPS

A reverse proxy is needed to expose the docker containers to the network and handle HTTPS.

Two options are supported:

1. Install a proxy in the host and direct traffic to the correct port
2. Use the `proxy` docker service

Since Globus Connect Server is served with Apache, the same Apache instance can also be configured to serve the ingestor. The [OpenEM Globus Installatioin](https://www.openem.ch/documentation/admin/installation/globus) documentation includes instructions for redirecting traffic to docker.

The proxy service is based on [traefik](https://traefik.io/). It assumes a signed TLS certificate is available on the host (eg updated by `certbot`).

Configuration:

1. Set the `TLS_CERT_FILE` and `TLS_KEY_FILE` variables in `.env`.
2. Set `INGESTOR_PATH_PREFIX` in `.env.${DEPLOYMENT}`. Recommended prefixes are `/qa`, `/dev`, and no prefix for production.

The `compose.sh` file is also used for starting the proxy:

```sh
./compose.sh proxy up -d
```

The proxy can be restarted independently from the ingestor service(s). You can also add it to the list of deployments to launch all deployments together:

```sh
./compose.sh proxy all up -d
```

Test that the proxy reaches all deployments with https through the proxy:

```sh
curl https://emf-ingestor.psi.ch/qa/version
{"version":"ghcr.io/swissopenem/ingestor:1.1.0"}
curl https://emf-ingestor.psi.ch/dev/version
{"version":"ghcr.io/swissopenem/ingestor:1.1.0"}
curl https://emf-ingestor.psi.ch/version
{"version":"ghcr.io/swissopenem/ingestor:1.1.0"}
```
