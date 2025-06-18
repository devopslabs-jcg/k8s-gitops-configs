kubectl create secret docker-registry ghcr-pull-secret \
  --docker-server=https://ghcr.io \
  --docker-username="jangk34" \
  --docker-password="${GHCR_TOKEN}" \
  --namespace=metric-app-dev \
  --dry-run=client -o yaml | \
kubeseal --cert pub-cert.pem --format yaml > /home/jcg/devops_project/k8s-gitops-configs/secrets/ghcr-sealedsecret.yaml

