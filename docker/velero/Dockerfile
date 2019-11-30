ARG ALPINE_IMAGE

# hadolint ignore=DL3006
FROM ${ALPINE_IMAGE}

ARG ARCH
ARG RESTIC_VERSION
ARG VELERO_VERSION

WORKDIR /tmp

# hadolint ignore=DL3018
RUN apk add --no-cache ca-certificates \
    && apk add --no-cache --virtual build-dependencies bzip2 curl \
    && curl -k -sSfL -o ./restic_${RESTIC_VERSION}_linux_${ARCH}.bz2 https://github.com/restic/restic/releases/download/v${RESTIC_VERSION}/restic_0.9.5_linux_${ARCH}.bz2 \
    && bunzip2 restic_${RESTIC_VERSION}_linux_${ARCH}.bz2 \
    && mv restic_${RESTIC_VERSION}_linux_${ARCH} /usr/bin/restic \
    && chmod +x /usr/bin/restic \
    && curl -k -sSfL -o ./velero-${VELERO_VERSION}-linux-${ARCH}.tar.gz https://github.com/vmware-tanzu/velero/releases/download/${VELERO_VERSION}/velero-${VELERO_VERSION}-linux-${ARCH}.tar.gz \
    && tar -xvf ./velero-${VELERO_VERSION}-linux-${ARCH}.tar.gz \
    && mv velero-${VELERO_VERSION}-linux-${ARCH}/velero /velero \
    && chmod +x /velero \
    && rm -rf /tmp/* \
    && apk del build-dependencies
    
WORKDIR /

ENTRYPOINT ["/velero"]
