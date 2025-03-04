FROM bpi/fixturenet-eth-genesis-postmerge:stack as fnetgen
FROM ethereum/client-go:v1.14.8 as geth

# Using the same golang image as used to build geth: https://github.com/cerc-io/go-ethereum/blob/HEAD/Dockerfile
FROM golang:1.21-alpine as delve
RUN go install github.com/go-delve/delve/cmd/dlv@latest

FROM alpine:3.17

RUN apk add --no-cache bash wget python3 bind-tools postgresql-client

COPY run-el.sh /opt/testnet/run.sh

COPY --from=delve /go/bin/dlv /usr/local/bin/
COPY --from=geth /usr/local/bin/geth /usr/local/bin/
COPY --from=fnetgen /opt/genesis /opt/testnet

# Initialize the geth db with our config
RUN geth --datadir ~/ethdata --state.scheme hash \
    init /opt/testnet/build/el/geth.json && \
    rm -f ~/ethdata/geth/nodekey

ENTRYPOINT ["/opt/testnet/run.sh"]
