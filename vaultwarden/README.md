# Vaultwarden (service)

This folder contains the deployment artifacts for Vaultwarden (Bitwarden-compatible). Secrets are stored as SealedSecrets and encrypted using the repository `pub-cert.pem`.[web:82]

## Quickstart (service-local)

1) Edit values (local, do not commit)

```bash
cd vaultwarden
# Edit the plaintext values template
vim values.unsealed.yaml
```

Set at least:

- `ingress.hosts[0].host` — your domain (e.g., `vault.example.com`).
- `env.ADMIN_TOKEN` — generate a strong token (e.g., `openssl rand -base64 48`).
- `env.DOMAIN` — full HTTPS URL (e.g., `https://vault.example.com`).
- `ingress.tls[0].secretName` — TLS secret name present in the cluster.

2) Produce a sealed (encrypted) values file and commit it

```bash
make seal   # produces values-sealed.yaml using ../pub-cert.pem
# only commit the sealed file
git add values-sealed.yaml
git commit -m "feat(vaultwarden): add sealed values"
git push
```

3) Apply the SealedSecret to the cluster

```bash
# this creates/updates the SealedSecret; the Sealed Secrets controller will convert it into a normal Secret
make apply    # runs: kubectl apply -k .
```

4) Ensure the namespace exists

```bash
kubectl create namespace vaultwarden --dry-run=client -o yaml | kubectl apply -f -
```

5) Extract `values.yaml` from the Secret and deploy with Helm

Option A — portable (temporary file):

```bash
kubectl get secret vaultwarden-values -n vaultwarden \
  -o jsonpath='{.data.values\.yaml}' | base64 -d > /tmp/vaultwarden-values.yaml

helm repo add vaultwarden https://guerzon.github.io/vaultwarden/
helm repo update

helm upgrade --install vaultwarden vaultwarden/vaultwarden \
  -n vaultwarden --create-namespace -f /tmp/vaultwarden-values.yaml
```

Option B — process substitution (bash):

```bash
helm upgrade --install vaultwarden vaultwarden/vaultwarden \
  -n vaultwarden --create-namespace -f <(kubectl get secret vaultwarden-values -n vaultwarden -o jsonpath='{.data.values\.yaml}' | base64 -d)
```

Notes:
- The SealedSecret → Secret conversion is performed by the Sealed Secrets controller; the Secret will be present in the `vaultwarden` namespace as `vaultwarden-values`.
- Option A (temporary file) is the most portable; Option B requires Bash process substitution support.

## Makefile (service-local)

The service Makefile (`vaultwarden/Makefile`) provides convenient targets:

- `make unsealed` — fetch the Sealed Secrets public cert into `../pub-cert.pem`.
- `make seal` — encrypt `values.unsealed.yaml` → `values-sealed.yaml` using `../pub-cert.pem`.
- `make apply` — apply this kustomization (`kubectl apply -k .`) to create/update the SealedSecret.
- `make clean` — delete resources created by the kustomization.

Notes:
- `CERT_FILE` defaults to `../pub-cert.pem` so multiple services can share the repo-level certificate file.
- **Never commit `values.unsealed.yaml`** — only commit the sealed `values-sealed.yaml` file.

## Verify & test

```bash
kubectl get all -n vaultwarden
kubectl get sealedsecret -n vaultwarden
kubectl get secret vaultwarden-values -n vaultwarden

kubectl logs -n vaultwarden deployment/vaultwarden

kubectl port-forward -n vaultwarden svc/vaultwarden 8080:80
# Access: http://localhost:8080
```

## Troubleshooting

- Check Sealed Secrets controller logs:

```bash
kubectl logs -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-controller=true
```

- Describe the SealedSecret if errors occur:

```bash
kubectl describe sealedsecret vaultwarden-values -n vaultwarden
```

- Inspect the Secret and its decoded `values.yaml`:

```bash
kubectl get secret vaultwarden-values -n vaultwarden -o yaml
kubectl get secret vaultwarden-values -n vaultwarden -o jsonpath='{.data.values\.yaml}' | base64 -d
```

---

Last updated: 2026-01-01
