#!/bin/bash

K3S_WORKERS="pik3s01 pik3s02 pik3s03"

for worker in $K3S_WORKERS; do
    kubectl label node ${worker} node-role.kubernetes.io/worker=worker
done