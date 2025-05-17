FROM caddy:builder AS builder

RUN xcaddy build \
    --with github.com/caddy-dns/rfc2136 \
    --replace github.com/libdns/rfc2136=github.com/gucci-on-fleek/libdns-rfc2136@libdns-1.0

FROM caddy:latest

COPY --from=builder /usr/bin/caddy /usr/bin/caddy
