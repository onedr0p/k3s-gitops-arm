wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.9.5/kubeseal-linux-amd64 -O kubeseal
sudo install -m 755 kubeseal /usr/local/bin/kubeseal


kubeseal --controller-name sealed-secrets --fetch-cert > ./sealed-secret-pub-cert.pem