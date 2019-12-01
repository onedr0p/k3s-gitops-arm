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
ARG VELERO_AWS_PLUGIN_VERSION

ENV GO111MODULE=on \
    CGO_ENABLED=0 \
    GOARCH="${ARCH}" \
    GOARM="${ARCH_VERSION}" \
    GOOS=linux

WORKDIR /go/src/github.com/vmware-tanzu/velero-plugin-for-aws

# hadolint ignore=DL3018
RUN apk add --no-cache curl ca-certificates git
RUN git clone https://github.com/vmware-tanzu/velero-plugin-for-aws.git .
RUN git checkout ${VELERO_AWS_PLUGIN_VERSION}
RUN go build -o velero-plugin-for-aws ./velero-plugin-for-aws

#
# Deploy
#

# hadolint ignore=DL3006
FROM ${ALPINE_IMAGE}

WORKDIR /plugins

# hadolint ignore=DL3018
RUN apk add --no-cache bash ca-certificates

# hadolint ignore=DL3022
COPY --from=build /go/src/github.com/vmware-tanzu/velero-plugin-for-aws/velero-plugin-for-aws /plugins/velero-plugin-for-aws
RUN chmod +x /plugins/velero-plugin-for-aws

ENTRYPOINT ["/bin/bash", "-c", "cp /plugins/* /target/."]
