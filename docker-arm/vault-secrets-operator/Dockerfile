#
# Compile
#

# arm32v7/golang:1.12-alpine
ARG ALPINE_BUILD_IMAGE
# arm32v7/alpine:3.10
ARG ALPINE_IMAGE

# hadolint ignore=DL3006
FROM ${ALPINE_BUILD_IMAGE}

ARG ARCH
ARG ARCH_VERSION
ARG VAULT_SECRETS_OPERATOR_VERSION

ENV GO111MODULE=on \
    CGO_ENABLED=0 \
    GOARCH="${ARCH}" \
    GOARM="${ARCH_VERSION}" \
    GOOS=linux

WORKDIR /go/src/github.com/ricoberger/vault-secrets-operator

# hadolint ignore=DL3018
RUN apk add --no-cache openssh-client 'git>=2.12.0' 'gnutls>=3.6.7' gnupg gawk socat build-base gcc wget bash curl ca-certificates

RUN git clone https://github.com/ricoberger/vault-secrets-operator .
RUN git checkout ${VAULT_SECRETS_OPERATOR_VERSION}
RUN go build -o vault-secrets-operator ./cmd/manager

#
# Deploy
#

# hadolint ignore=DL3006
FROM ${ALPINE_IMAGE}

# hadolint ignore=DL3018
RUN apk add --no-cache ca-certificates tini

# hadolint ignore=DL3022
COPY --from=0 /go/src/github.com/ricoberger/vault-secrets-operator/vault-secrets-operator /usr/local/bin/vault-secrets-operator
RUN chmod +x /usr/local/bin/vault-secrets-operator

ENTRYPOINT ["/sbin/tini", "--", "vault-secrets-operator"]
