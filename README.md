# Homelab GitOps for RKE2

A small GitOps repository for deploying services on an RKE2 cluster using Flux and Bitnami Sealed Secrets for encrypted configuration. The example service included here is Vaultwarden (Bitwarden-compatible).

---

## Table of contents

- [Prerequisites](#prerequisites)
- [Sealed Secrets — Install & Use](#sealed-secrets--install--use)
  - [Install the controller](#install-the-controller)
  - [Install kubeseal CLI](#install-kubeseal-cli)
  - [Generate public cert for encryption](#generate-public-cert-for-encryption)
  - [Workflow with this repo (Makefile)](#workflow-with-this-repo-makefile)
  - [Troubleshooting Sealed Secrets](#troubleshooting-sealed-secrets)
- [Vaultwarden — Deployment](#vaultwarden--deployment)
  - [Quickstart](#quickstart)
  - [Configure values](#configure-values)
  - [Encrypt and deploy](#encrypt-and-deploy)
  - [Verify & test](#verify--test)
- [Add new services](#add-new-services)
- [Makefile commands](#makefile-commands)
- [Compatibility & Notes](#compatibility--notes)

---

## Prerequisites

- An RKE2 cluster (kubernetes) up and reachable via `kubectl`.
- `kubectl` configured to talk to the target cluster.
- Git repository cloned locally.
- `kubeseal` CLI installed (recommended v0.34.0 to match the controller used in examples).

## Sealed Secrets — Install & Use

This repository uses Bitnami Sealed Secrets so you can keep secrets encrypted in Git and let the Sealed Secrets controller decrypt them inside the cluster.

### Install the controller

Apply the controller manifest (example version shown):

```bash
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.34.0/controller.yaml
```

Verify the controller is running:

```bash
kubectl get pods -n kube-system | grep sealed-secrets
```

### Install kubeseal CLI

On Linux:

```bash
curl -OL "https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.34.0/kubeseal-0.34.0-linux-amd64.tar.gz"
tar -xvzf kubeseal-0.34.0-linux-amd64.tar.gz kubeseal
sudo install -m 755 kubeseal /usr/local/bin/kubeseal
rm kubeseal kubeseal-0.34.0-linux-amd64.tar.gz
```

Check version:

```bash
kubeseal --version
```

### Generate public cert for encryption

Fetch the Sealed Secrets public certificate and save it locally (this file is gitignored in this repo):

```bash
kubeseal --fetch-cert \
  --controller-name=sealed-secrets-controller \
  --controller-namespace=kube-system \
  > pub-cert.pem
```

Note: controller name may differ; run `kubectl -n kube-system get deploy` to check and adjust `--controller-name` if needed.

Keep `pub-cert.pem` safe locally — it is used to encrypt secrets before committing them to Git.

**Note:** Makefiles are service-specific and are located inside each service folder (for example, see `vaultwarden/Makefile`). See the **Vaultwarden — Deployment** section below for the service-local commands and example workflow.


### Troubleshooting Sealed Secrets

- Check controller logs:

```bash
kubectl logs -n kube-system -l sealedsecrets.bitnami.com/sealed-secrets-controller=true
```

- Describe a SealedSecret if an error occurs:

```bash
kubectl describe sealedsecret vaultwarden-values -n vaultwarden
```

---

## Vaultwarden — Deployment

This repository contains an example HelmRelease and values for Vaultwarden. The secrets are stored encrypted as a SealedSecret.

### Quickstart

```bash
# 1. Edit vaultwarden/values.unsealed.yaml and set your domain and admin token
# 2. Encrypt the values: make seal
# 3. Commit and push sealed values to Git
# 4. Deploy: make apply
```

### Configure values

Edit `vaultwarden/values.unsealed.yaml` and set at least the following:

- `ingress.hosts[0].host` — your domain (e.g., `vault.example.com`).
- `env.ADMIN_TOKEN` — generate a strong token (e.g., `openssl rand -base64 48`).
- `env.DOMAIN` — full HTTPS URL (e.g., `https://vault.example.com`).
- `ingress.tls[0].secretName` — the TLS secret name present in the cluster.

### Vaultwarden Makefile (service-local)

A service-local Makefile is available at `vaultwarden/Makefile`. When working on Vaultwarden, `cd vaultwarden` and use the Makefile for service-specific operations:

- `make unsealed` — fetch the public certificate (`pub-cert.pem`) into the service directory.
- `make seal` — encrypt `values.unsealed.yaml` → `values-sealed.yaml`.
- `make apply` — apply the `vaultwarden` kustomization (`kubectl apply -k .`).
- `make clean` — delete the resources created by the kustomization.

Typical flow (service-local):

1. `cd vaultwarden`
2. Edit `values.unsealed.yaml`.
3. Run `make seal` to produce `values-sealed.yaml`.
4. Commit and push the sealed file to Git.
5. Run `make apply` (inside `vaultwarden/`) to deploy, or push and let your GitOps operator apply the change.

### Encrypt and deploy

```bash
make seal
git add vaultwarden/values-sealed.yaml
git commit -m "feat: deploy vaultwarden"
git push origin main
make apply
```

### Verify & test

```bash
kubectl get all -n vaultwarden
kubectl get sealedsecret -n vaultwarden
kubectl logs -n vaultwarden deployment/vaultwarden
# Port-forward for local testing
kubectl port-forward -n vaultwarden svc/vaultwarden 8080:80
# Access: http://localhost:8080
```

---

## Add new services

To add another service, copy the `vaultwarden/` directory structure to a new folder, update `values.unsealed.yaml`, add a `helmrelease.yaml` and follow the same `make seal` → commit → `make apply` flow.

## Service Makefile commands

Each service may include its own Makefile with service-specific commands (see `vaultwarden/Makefile` for an example). Common commands found in service Makefiles include:

- `make unsealed` — fetch the SealedSecrets public certificate (`pub-cert.pem`).
- `make seal` — encrypt the service's `values.unsealed.yaml` into `values-sealed.yaml`.
- `make apply` — `kubectl apply -k .` (run inside the service folder to apply its Kustomize manifest).
- `make clean` — delete the applied resources for the service.

## Compatibility & notes

- Tested with RKE2 and Flux/HelmRelease patterns.
- Sealed Secrets controller version in examples: v0.34.0 — make sure CLI and controller versions are compatible.

---

Last updated: 2026-01-01
Compatible: RKE2 v1.30+, Sealed Secrets v0.34.0
