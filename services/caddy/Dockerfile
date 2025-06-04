FROM caddy:2.10-builder AS builder

RUN xcaddy build \
    --with github.com/caddy-dns/rfc2136

FROM caddy:2.10

COPY --from=builder /usr/bin/caddy /usr/bin/caddy
