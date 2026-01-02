.PHONY: seal apply unsealed clean

NAMESPACE ?= vaultwarden
CERT_FILE ?= ../pub-cert.pem

# 1) Encrypt values.unsealed.yaml into a SealedSecret
seal:
	@echo "Generating Secret from values.unsealed.yaml and sealing it..."
	@{ \
	  echo "apiVersion: v1"; \
	  echo "kind: Secret"; \
	  echo "metadata:"; \
	  echo "  name: vaultwarden-values"; \
	  echo "  namespace: $(NAMESPACE)"; \
	  echo "type: Opaque"; \
	  echo "stringData:"; \
	  echo "  values.yaml: |"; \
	  sed 's/^/    /' values.unsealed.yaml; \
	} | kubeseal \
	  --cert $(CERT_FILE) \
	  -n $(NAMESPACE) \
	  > values-sealed.yaml

# 2) Apply kustomization in this folder
apply:
	kubectl apply -k .

# 3) Cleanup
clean:
	kubectl delete -k . --ignore-not-found
