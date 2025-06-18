kubectl create secret docker-registry ghcr-pull-secret \
  --docker-server=https://ghcr.io \
  --docker-username="jangk34" \
  --docker-password="${GHCR_TOKEN}" \
  --namespace=metric-app-dev \
  --dry-run=client -o yaml | \
kubeseal --scope cluster-wide --format yaml \
  --controller-name sealed-secrets \
  --controller-namespace kube-system \
  > ./ghcr-sealedsecret.yaml
