# Vaultwarden (service)

This folder contains the deployment artifacts for Vaultwarden (Bitwarden-compatible). Secrets are stored as SealedSecrets and encrypted using the repository `pub-cert.pem`.

## Quickstart (service-local)

```bash
cd vaultwarden
# Edit values.unsealed.yaml and set domain and ADMIN_TOKEN
make seal        # produces values-sealed.yaml using ../pub-cert.pem
git add values-sealed.yaml
git commit -m "feat(vaultwarden): add sealed values"
git push
make apply        # applies the vaultwarden kustomization (kubectl apply -k .)
```

## Configure values

Edit `values.unsealed.yaml` and set at least:

- `ingress.hosts[0].host` — your domain (e.g., `vault.example.com`).
- `env.ADMIN_TOKEN` — generate strong token (e.g., `openssl rand -base64 48`).
- `env.DOMAIN` — full HTTPS URL (e.g., `https://vault.example.com`).
- `ingress.tls[0].secretName` — TLS secret name present in the cluster.

## Makefile (service-local)

The service Makefile (`vaultwarden/Makefile`) provides:

- `make unsealed` — fetch the SealedSecrets public cert (`../pub-cert.pem`).
- `make seal` — encrypt `values.unsealed.yaml` → `values-sealed.yaml` using `../pub-cert.pem`.
- `make apply` — apply this kustomization (`kubectl apply -k .`).
- `make clean` — delete resources created by the kustomization.

Notes:
- The default `CERT_FILE` points to `../pub-cert.pem` so multiple services can share the same certificate file at the repository root.

## Verify & test

```bash
kubectl get all -n vaultwarden
kubectl get sealedsecret -n vaultwarden
kubectl logs -n vaultwarden deployment/vaultwarden
# Port-forward for local testing
kubectl port-forward -n vaultwarden svc/vaultwarden 8080:80
# Access: http://localhost:8080
```

## Troubleshooting

- Check sealed-secrets controller logs:

```bash
kubectl logs -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-controller=true
```

- Describe the sealedsecret if errors occur:

```bash
kubectl describe sealedsecret vaultwarden-values -n vaultwarden
```
