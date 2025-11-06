
# Komodor Agent Install with Terraform (Minimal)

This bundle installs the Komodor agent into your AKS (or any Kubernetes) cluster using Terraform + the Helm provider — with a **simple env → API key** map and **no tfvars/CLI secrets**.

## Files
- `providers.tf` — Helm + Kubernetes provider configuration (reads your local kubeconfig by default).
- `variables.tf` — inputs for environment, cluster name, and kubeconfig path/context.
- `komodor.tf` — minimal Helm release for Komodor with env-based API keys.
- `values-komodor.yaml` — non-secret values for the chart (clusterName templated).

---

## Prerequisites
- Terraform >= 1.4
- Access to your cluster via kubeconfig (e.g., `~/.kube/config`), or set the path/context via variables.
- Outbound network egress from the cluster to Komodor.

## Quick Start

1. **Edit env API keys** in `komodor.tf`:
   ```hcl
   locals {
     komodor_api_keys = {
       dev  = "dev-APIKEY-123"
       uat  = "uat-APIKEY-456"
       prod = "prod-APIKEY-789"
     }
   }
   ```

2. **Set your cluster name** (for display in Komodor) when applying:
   ```bash
   terraform init
   terraform apply -var="env_ref=dev" -var="cluster_name=<your-aks-name>"
   ```

   Optionally, point Terraform to a custom kubeconfig path/context:
   ```bash
   terraform apply      -var="env_ref=dev"      -var="cluster_name=<your-aks-name>"      -var="kubeconfig_path=/path/to/kubeconfig"      -var="kube_context=my-aks-context"
   ```

## What it does
- Creates/ensures the `komodor` namespace.
- Installs the `komodor-agent` Helm chart from `https://helm-charts.komodor.io`.
- Passes `clusterName` from `values-komodor.yaml`, and `apiKey` from an env-specific map.

## Verify
```bash
kubectl -n komodor get pods
kubectl -n komodor logs deploy/komodor-agent
```

## Notes
- Keys are treated as **non-sensitive** and will appear in plan/state. If you later want to hide/move them, replace the `local.komodor_api_keys[...]` expression with:
  - An Azure Key Vault lookup, or
  - A Kubernetes Secret (`existingSecret`/`existingSecretKey` chart options), or
  - Workspace sensitive variables.
