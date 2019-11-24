# Sealed Secrets

## Install kubeseal locally

```bash
wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.9.5/kubeseal-linux-amd64 -O kubeseal
sudo install -m 755 kubeseal /usr/local/bin/kubeseal
rm -rf kubeseal
```

## Create sealed-secrets public certificate

```bash
kubeseal --controller-name sealed-secrets --fetch-cert > ./setup/secrets/pub-cert.pem
```

Start adding secrets and deploying your apps
