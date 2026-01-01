# Homelab GitOps for RKE2

A small repository for deploying services on an RKE2 cluster using Bitnami Sealed Secrets for encrypted configuration. The example service included here is Vaultwarden (Bitwarden-compatible).

---

## Table of contents

- [Prerequisites](#prerequisites)
- [Sealed Secrets — Install & Use](#sealed-secrets--install--use)
- [Services](#services)
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

**Note:** Makefiles are service-specific and are located inside each service folder (for example, see `vaultwarden/Makefile`). See the service's README (e.g., `vaultwarden/README.md`) for service-local commands and example workflow.


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

## Services

This repository contains service packages under their respective directories. For Vaultwarden deployment and service-local Makefile usage, see `vaultwarden/README.md`.
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

- Tested with RKE2.
- Example manifests include a `HelmRelease` format but you can adapt the resources to your deployment workflow.
- Sealed Secrets controller version in examples: v0.34.0 — make sure CLI and controller versions are compatible.

---

Last updated: 2026-01-01
Compatible: RKE2 v1.30+, Sealed Secrets v0.34.0
