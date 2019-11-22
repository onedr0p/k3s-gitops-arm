#
# Compile
#

# arm32v7/golang:1.12-alpine
ARG ALPINE_BUILD_IMAGE
# arm32v7/alpine:3.10
ARG ALPINE_IMAGE

# hadolint ignore=DL3006
FROM ${ALPINE_BUILD_IMAGE} as build

ARG ARCH
ARG ARCH_VERSION
ARG KUBECTL_VERSION
ARG HELM_OPERATOR_VERSION

ENV GO111MODULE=on \
    CGO_ENABLED=0 \
    GOARCH="${ARCH}" \
    GOARM="${ARCH_VERSION}" \
    GOOS=linux

WORKDIR /go/src/github.com/fluxcd/helm-operator

# hadolint ignore=DL3018
RUN apk add --no-cache openssh-client 'git>=2.12.0' 'gnutls>=3.6.7' gnupg gawk socat build-base gcc wget bash curl ca-certificates \
    && apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing git-secret

RUN curl -k -sSfL -o /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl

RUN curl -k -sSfL -o /tmp/helm-v2.14.3-linux-${ARCH}.tar.gz https://get.helm.sh/helm-v2.14.3-linux-${ARCH}.tar.gz \
    && tar -xvf /tmp/helm-v2.14.3-linux-${ARCH}.tar.gz -C /tmp \
    && mv /tmp/linux-${ARCH}/helm /usr/local/bin/helm \
    && chmod +x /usr/local/bin/helm \
    && rm -rf /tmp/*

RUN git clone https://github.com/fluxcd/helm-operator .
RUN git checkout ${HELM_OPERATOR_VERSION}
RUN go build -o helm-operator ./cmd/helm-operator

#
# Deploy
#

# hadolint ignore=DL3006
FROM ${ALPINE_IMAGE}
ENV HELM_HOME=/var/fluxd/helm

WORKDIR /home/flux

# hadolint ignore=DL3018
RUN apk add --no-cache openssh-client ca-certificates tini 'git>=2.12.0' socat \
    && apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing git-secret

COPY ./known_hosts.sh /home/flux/known_hosts.sh
RUN sh /home/flux/known_hosts.sh /etc/ssh/ssh_known_hosts && \
    rm /home/flux/known_hosts.sh

COPY ./ssh_config /etc/ssh/ssh_config

RUN mkdir -p /var/fluxd/helm/repository/cache/
COPY ./helm-repositories.yaml /var/fluxd/helm/repository/repositories.yaml

# hadolint ignore=DL3022
COPY --from=build /go/src/github.com/fluxcd/helm-operator/helm-operator /usr/local/bin/helm-operator
RUN chmod +x /usr/local/bin/helm-operator
# hadolint ignore=DL3022
COPY --from=build /usr/local/bin/helm /usr/local/bin/helm
RUN chmod +x /usr/local/bin/helm
# hadolint ignore=DL3022
COPY --from=build /usr/local/bin/kubectl /usr/local/bin/kubectl
RUN chmod +x /usr/local/bin/kubectl

ENTRYPOINT ["/sbin/tini", "--", "helm-operator"]
