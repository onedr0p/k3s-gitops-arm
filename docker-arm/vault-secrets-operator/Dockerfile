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

# #
# # Deploy
# #

# # hadolint ignore=DL3006
# FROM ${ALPINE_IMAGE}
# ENV HELM_HOME=/var/fluxd/helm

# WORKDIR /home/flux

# # hadolint ignore=DL3018
# RUN apk add --no-cache openssh-client ca-certificates tini 'git>=2.12.0' socat \
#     && apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing git-secret

# COPY ./known_hosts.sh /home/flux/known_hosts.sh
# RUN sh /home/flux/known_hosts.sh /etc/ssh/ssh_known_hosts && \
#     rm /home/flux/known_hosts.sh

# COPY ./ssh_config /etc/ssh/ssh_config

# RUN mkdir -p /var/fluxd/helm/repository/cache/
# COPY ./helm-repositories.yaml /var/fluxd/helm/repository/repositories.yaml

# # hadolint ignore=DL3022
# COPY --from=0 /go/src/github.com/fluxcd/helm-operator/helm-operator /usr/local/bin/helm-operator
# RUN chmod +x /usr/local/bin/helm-operator
# # hadolint ignore=DL3022
# COPY --from=0 /usr/local/bin/helm /usr/local/bin/helm
# RUN chmod +x /usr/local/bin/helm
# # hadolint ignore=DL3022
# COPY --from=0 /usr/local/bin/kubectl /usr/local/bin/kubectl
# RUN chmod +x /usr/local/bin/kubectl

# ENTRYPOINT ["/sbin/tini", "--", "helm-operator"]
