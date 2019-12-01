# Minio and Velero

## MinIO

> Note: Review repository for any @CHANGEME comments

Review [deployments/default/minio/minio.yaml](../deployments/default/minio/minio.yaml)

### Minio secrets

> Note: Install pwgen to generate MINIO_ACCESS_KEY and MINIO_SECRET_KEY, also make sure you have DOMAIN populated

Provide and generate `MINIO_ACCESS_KEY` and `MINIO_SECRET_KEY` in [setup/.env](../setup)

Review [setup/bootstrap-secrets.sh](../setup/bootstrap-cluster.sh)

```bash
cd setup
./bootstrap-secrets.sh
```

## Velero

> Note: Review repository for any @CHANGEME comments

### Install the Velero CLI

> All these commands are run from your computer, not the RPi.

```bash
# macOS
brew install velero

# Linux
curl -L -o /tmp/velero-v1.2.0-linux-amd64.tar.gz https://github.com/vmware-tanzu/velero/releases/download/v1.2.0/velero-v1.2.0-linux-amd64.tar.gz
tar -xvf /tmp/velero-v1.2.0-linux-amd64.tar.gz -C /tmp
sudo mv /tmp/velero-v1.2.0-linux-amd64/velero /usr/local/bin/velero
sudo chmod +x /usr/local/bin/velero
```

### Create the Velero Namespace

> All these commands are run from your computer, not the RPi.

```bash
kubectl apply -f deployments/velero/namespace.yaml
```

### Deploy Velero

> Note: Flux should deploy this automatically

### Install the AWS Plugin

> All these commands are run from your computer, not the RPi.

```bash
velero plugin add onedr0p/velero-plugin-for-aws:1.0.0-arm
```
