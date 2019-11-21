# ARM Docker Images

## Flux

```bash
cd flux
docker build -f Dockerfile -t onedr0p/flux:latest-arm32
docker push onedr0p/flux:latest-arm32
```

## Helm Operator

```bash
cd helm-operator

# arm
docker build --no-cache -f Dockerfile \
    --build-arg ALPINE_BUILD_IMAGE="arm32v7/golang:1.12-alpine" \
    --build-arg ALPINE_IMAGE="arm32v7/alpine:3.10" \
    --build-arg ARCH="arm" \
    --build-arg ARCH_VERSION="7" \
    --build-arg KUBECTL_VERSION="v1.14.7" \
    --build-arg HELM_OPERATOR_VERSION="v1.0.0-rc3" \
    -t onedr0p/helm-operator:latest-arm32 .

docker push onedr0p/helm-operator:latest-arm32

# arm64
docker build --no-cache -f Dockerfile \
    --build-arg ALPINE_BUILD_IMAGE="arm64v8/golang:1.12-alpine" \
    --build-arg ALPINE_IMAGE="arm64v8/alpine:3.10" \
    --build-arg ARCH="arm64" \
    --build-arg ARCH_VERSION="" \
    --build-arg KUBECTL_VERSION="v1.14.7" \
    --build-arg HELM_OPERATOR_VERSION="v1.0.0-rc3" \
    -t onedr0p/helm-operator:latest-arm64 .

docker push onedr0p/helm-operator:latest-arm64
```

## Velero

```bash
cd velero

# arm
docker build --no-cache -f Dockerfile \
    --build-arg ALPINE_IMAGE="arm32v7/alpine:3.10" \
    --build-arg ARCH="arm" \
    --build-arg RESTIC_VERSION="0.9.5" \
    --build-arg VELERO_VERSION="v1.2.0" \
    -t onedr0p/velero:latest-arm32 .

docker push onedr0p/velero:latest-arm32

# arm64
docker build --no-cache -f Dockerfile \
    --build-arg ALPINE_IMAGE="arm64v8/alpine:3.10" \
    --build-arg ARCH="arm64" \
    --build-arg RESTIC_VERSION="0.9.5" \
    --build-arg VELERO_VERSION="v1.2.0" \
    -t onedr0p/velero:latest-arm64 .

docker push onedr0p/velero:latest-arm64
```
