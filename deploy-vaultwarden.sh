#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="vaultwarden"
SERVICE_DIR="vaultwarden"
CERT_FILE="pub-cert.pem"
TMP_VALUES="/tmp/vaultwarden-values.yaml"
HELM_RELEASE_NAME="vaultwarden"
HELM_REPO_NAME="vaultwarden"
HELM_REPO_URL="https://guerzon.github.io/vaultwarden/"

echo "=== Vaultwarden deploy script ==="

# 1. Ensure namespace exists
echo "[1/5] Ensuring namespace '${NAMESPACE}' exists..."
kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

# 2. Ensure SealedSecrets public cert exists
if [ ! -f "${CERT_FILE}" ]; then
  echo "[2/5] '${CERT_FILE}' not found, fetching SealedSecrets public cert from cluster..."
  kubeseal --fetch-cert \
    --controller-name=sealed-secrets-controller \
    --controller-namespace=kube-system \
    > "${CERT_FILE}"
else
  echo "[2/5] Using existing '${CERT_FILE}'..."
fi

# 3. Seal values.unsealed.yaml -> values-sealed.yaml
echo "[3/5] Sealing ${SERVICE_DIR}/values.unsealed.yaml into ${SERVICE_DIR}/values-sealed.yaml..."
(
  cd "${SERVICE_DIR}"
  make seal
  make apply
)

# 4. Extract values.yaml from Secret
echo "[4/5] Extracting values.yaml from Secret into ${TMP_VALUES}..."
kubectl get secret vaultwarden-values -n "${NAMESPACE}" \
  -o jsonpath='{.data.values\.yaml}' \
  | base64 -d > "${TMP_VALUES}"

# 5. Deploy/upgrade with Helm
echo "[5/5] Deploying Helm release '${HELM_RELEASE_NAME}' in namespace '${NAMESPACE}'..."
helm repo add "${HELM_REPO_NAME}" "${HELM_REPO_URL}" >/dev/null 2>&1 || true
helm repo update "${HELM_REPO_NAME}" >/dev/null 2>&1 || true

helm upgrade --install "${HELM_RELEASE_NAME}" "${HELM_REPO_NAME}/vaultwarden" \
  -n "${NAMESPACE}" \
  -f "${TMP_VALUES}"

echo "=== Done. Current status: ==="
kubectl get pods -n "${NAMESPACE}"
kubectl get svc -n "${NAMESPACE}"
echo "You can port-forward with:"
echo "  kubectl port-forward -n ${NAMESPACE} svc/vaultwarden 8080:80"
