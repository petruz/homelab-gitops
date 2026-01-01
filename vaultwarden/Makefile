### `Makefile`
.PHONY: seal apply unsealed clean

NAMESPACE ?= vaultwarden
# Default certificate file is at repository root (so all services can share it)
CERT_FILE ?= ../pub-cert.pem

# Genera cert dal cluster (una tantum)
unsealed:
	kubeseal --fetch-cert \
	  --controller-name=sealed-secrets \
	  --controller-namespace=kube-system \
	  > $(CERT_FILE)

# Encrypt the unsealed values into a sealed secret
seal:
	kubeseal < values.unsealed.yaml \
	  > values-sealed.yaml \
	  --cert $(CERT_FILE) \
	  -n $(NAMESPACE)

# Deploy tutto
apply:
	kubectl apply -k .

# Cleanup
clean:
	kubectl delete -k . --ignore-not-found

