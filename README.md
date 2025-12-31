# Homelab GitOps - RKE2

Repo GitOps per Vaultwarden + futuri servizi.

## Quickstart
```bash
make seal apply
```

Homelab GitOps - RKE2 + Sealed Secrets
GitOps repository for managing Vaultwarden (Bitwarden compatible) and future services on RKE2 cluster using Sealed Secrets for encrypted secrets.
​

Prerequisites
RKE2 cluster running

kubectl configured to access cluster

Git repository cloned locally

kubeseal CLI installed (v0.34.0)

Installation
1. Install Sealed Secrets Controller (v0.34.0)

bash
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.34.0/controller.yaml
Verify controller is running:

bash
kubectl get pods -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-controller=true
Expected: 1 pod in Running state.

2. Install kubeseal CLI (Linux)

bash
curl -OL "https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.34.0/kubeseal-0.34.0-linux-amd64.tar.gz"
tar -xvzf kubeseal-0.34.0-linux-amd64.tar.gz kubeseal
sudo install -m 755 kubeseal /usr/local/bin/kubeseal
rm kubeseal kubeseal-0.34.0-linux-amd64.tar.gz
Verify:

bash
kubeseal version  # Should show v0.34.0
3. Generate Public Certificate

bash
kubeseal --fetch-cert \
  --controller-name=sealed-secrets \
  --controller-namespace=kube-system \
  > pub-cert.pem
Keep pub-cert.pem safe (gitignored) - required for encrypting secrets.

Vaultwarden Deployment
Quickstart (one-time setup)

bash
# Encrypt secrets and deploy
make seal apply
Detailed Deployment Steps

Edit Vaultwarden configuration (unsealed template):

bash
vim vaultwarden/values.unsealed.yaml
Required changes:

ingress.hosts[0].host: Your domain (e.g., vault.example.com)

env.ADMIN_TOKEN: Generate strong token (openssl rand -base64 48)

env.DOMAIN: Full HTTPS URL

ingress.tls[0].secretName: Your TLS secret name

Encrypt secrets:

bash
make seal
Commit and deploy:

bash
git add .
git commit -m "feat: deploy vaultwarden"
git push origin main
make apply
Verify deployment:

bash
kubectl get all -n vaultwarden
kubectl get sealedsecret -n vaultwarden
Port-forward for testing:

bash
kubectl port-forward -n vaultwarden svc/vaultwarden 8080:80
Access: http://localhost:8080

Client Setup
Download official Bitwarden clients and configure custom server:

Platform	Client	Server URL
iOS	App Store: Bitwarden	https://vault.example.com
macOS	App Store / brew	https://vault.example.com
Linux	flatpak install flathub com.bitwarden.client	https://vault.example.com
Browser	Chrome/Firefox/Safari extensions	https://vault.example.com
Usage & Updates
Update Vaultwarden Configuration

bash
# 1. Edit unsealed values
vim vaultwarden/values.unsealed.yaml

# 2. Encrypt + deploy
make seal && git add . && git commit -m "chore: update vaultwarden" && git push && make apply
Add New Services

text
mkdir -p new-service
# Copy vaultwarden/ structure
# Edit values.unsealed.yaml
# make seal apply
Backup & Disaster Recovery

Everything is in GitHub - single source of truth:

bash
# Full restore from Git
git clone https://github.com/username/homelab-gitops
cd homelab-gitops
make apply
Makefile Commands
Command	Description
make unsealed	Generate fresh pub-cert.pem
make seal	Encrypt values.unsealed.yaml → values-sealed.yaml
make apply	Deploy everything (kubectl apply -k .)
make clean	Delete all resources
Troubleshooting
Controller Issues

bash
# Check controller logs
kubectl logs -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-controller=true

# Multiple controllers? Clean old deployments
kubectl delete deployment sealed-secrets-controller -n kube-system --ignore-not-found
SealedSecret Errors

bash
kubectl describe sealedsecret vaultwarden-values -n vaultwarden
Vaultwarden Not Starting

bash
kubectl logs -n vaultwarden deployment/vaultwarden
kubectl get pvc -n vaultwarden  # Check storage
Architecture Overview
text
GitHub (encrypted) ─── SealedSecret ───> RKE2 ───> Secret (decrypted)
                                                           ↓
                                                      Vaultwarden Pod
Security: Secrets encrypted asymmetrically - only cluster controller can decrypt.
​

Adding More Services
Copy vaultwarden/ → new-service/

Edit new-service/values.unsealed.yaml

Update new-service/helmrelease.yaml (chart, repo)

make seal apply

Template available for: Home Assistant, Authelia, Prometheus, etc.

Last updated: December 31, 2025
Compatible: RKE2 v1.30+, Sealed Secrets v0.34.0
