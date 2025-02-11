FROM ethpandaops/ethereum-genesis-generator:3.0.0 AS ethgen

# Build genesis config
ADD genesis /opt/genesis
WORKDIR /opt/genesis
RUN make genesis-el
RUN jq ".config" build/el/geth.json > build/el/chain.json

FROM golang:1.21-alpine as builder

COPY --from=ethgen /opt/genesis /opt/genesis

# Snag the genesis block info.
RUN CGO_ENABLED=0 go install github.com/cerc-io/eth-dump-genblock@v0.2.0
RUN eth-dump-genblock /opt/genesis/build/el/geth.json > /opt/genesis/build/el/genesis_block.json

FROM alpine:latest

COPY --from=builder /opt/genesis /opt/genesis
