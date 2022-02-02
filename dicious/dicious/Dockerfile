ARG GOIMAGE=golang:rc-bullseye

FROM $GOIMAGE AS builder

WORKDIR $GOPATH/src/dicious

COPY . .

RUN  make build install

FROM debian:11

COPY --from=builder /usr/local/bin/dicious /dicious

ENTRYPOINT ["/dicious"]
