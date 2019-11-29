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
ARG FLUX_VERSION
ARG KUBECTL_VERSION
ARG KUSTOMIZE_VERSION

ENV GO111MODULE=on \
    CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH="${ARCH}" \
    GOARM="${ARCH_VERSION}" \
    FLUX_VERSION=${FLUX_VERSION} \
    KUBECTL_VERSION=${KUBECTL_VERSION} \
    KUSTOMIZE_VERSION=${KUSTOMIZE_VERSION}

WORKDIR /go/src/github.com/fluxcd/flux

# hadolint ignore=DL3018
RUN apk add --no-cache openssh-client 'git>=2.12.0' 'gnutls>=3.6.7' gnupg gawk socat build-base gcc wget bash curl \
    && apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing git-secret

RUN curl -L -o /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl
RUN curl -L -o /usr/local/bin/fluxctl https://github.com/fluxcd/flux/releases/download/${FLUX_VERSION}/fluxctl_linux_${ARCH}

RUN git clone https://github.com/fluxcd/flux.git .
RUN git checkout ${FLUX_VERSION}
RUN go build -o fluxd ./cmd/fluxd

# build kustomize
WORKDIR /go/src/github.com/kubernetes-sigs/kustomize
RUN git clone https://github.com/kubernetes-sigs/kustomize.git .
RUN git checkout ${KUSTOMIZE_VERSION}
RUN go build -o kustomize ./cmd/kustomize

#
# Deploy
#

# hadolint ignore=DL3006
FROM ${ALPINE_IMAGE}

WORKDIR /home/flux

# hadolint ignore=DL3018
RUN apk add --no-cache openssh-client ca-certificates tini 'git>=2.12.0' 'gnutls>=3.6.7' gnupg gawk socat \
    && apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing git-secret

RUN [ ! -e /etc/nsswitch.conf ] && echo 'hosts: files dns' > /etc/nsswitch.conf
COPY ./kubeconfig /root/.kube/config

COPY ./known_hosts.sh /home/flux/known_hosts.sh
RUN sh /home/flux/known_hosts.sh /etc/ssh/ssh_known_hosts \
    && rm /home/flux/known_hosts.sh

# Add default SSH config, which points at the private key we'll mount
COPY ./ssh_config /etc/ssh/ssh_config

# hadolint ignore=DL3022
COPY --from=build /go/src/github.com/fluxcd/flux/fluxd /usr/local/bin/fluxd
RUN chmod +x /usr/local/bin/fluxd
# hadolint ignore=DL3022
COPY --from=build /usr/local/bin/fluxctl /usr/local/bin/fluxctl
RUN chmod +x /usr/local/bin/fluxctl
# hadolint ignore=DL3022
COPY --from=build /go/src/github.com/kubernetes-sigs/kustomize /usr/local/bin/kustomize
RUN chmod +x /usr/local/bin/kustomize
# hadolint ignore=DL3022
COPY --from=build /usr/local/bin/kubectl /usr/local/bin/kubectl
RUN chmod +x /usr/local/bin/kubectl

# hadolint ignore=DL3022
COPY --from=quay.io/squaremo/kubeyaml:0.7.0 /usr/lib/kubeyaml /usr/lib/kubeyaml/
ENV PATH=/bin:/usr/bin:/usr/local/bin:/usr/lib/kubeyaml

ENTRYPOINT ["/sbin/tini", "--", "fluxd"]
