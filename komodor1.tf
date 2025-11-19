# komodor.tf (final version integrated with aks_clusternames)

variable "komodor_namespace" {
  description = "Namespace where Komodor agent will be installed"
  type        = string
  default     = "komodor"
}

locals {
  # Cluster name derived from your existing AKS config locals
  komodor_cluster_name = local.aks_clusternames[var.env_ref]

  # Secret naming format per environment
  komodor_secret_name  = "komodor-api-env-${local.my_env_short}"

  # Region lookup to find correct KV entry
  kv_region_key = local.basic["local"].region_short

  # KeyVault ID (same lookup pattern you use in Linkerd + AKS)
  kv_id = data.terraform_remote_state.common.outputs.key_vaults.infra.common[local.kv_region_key].id
}

# Retrieve API key from Key Vault
data "azurerm_key_vault_secret" "komodor_api_key" {
  name         = local.komodor_secret_name
  key_vault_id = local.kv_id
}

# Create Kubernetes secret to inject into Komodor pod
resource "kubernetes_secret" "komodor" {
  metadata {
    name      = "komodor-secrets"
    namespace = var.komodor_namespace
  }

  # raw value — Kubernetes will encode automatically
  string_data = {
    apiKey = data.azurerm_key_vault_secret.komodor_api_key.value
  }

  type = "Opaque"
}

# Install Komodor via Helm
resource "helm_release" "komodor_agent" {
  name       = "komodor-agent"
  repository = "https://helm.komodor.io"
  chart      = "komodorio/komodor-agent"
  namespace  = var.komodor_namespace

  # This replaces: --set clusterName=<value>
  set {
    name  = "clusterName"
    value = local.komodor_cluster_name
  }

  # Values file ensures API key comes from secret instead of --set
  values = [
    file("${path.module}/komodor-values.yaml")
  ]

  depends_on = [
    kubernetes_secret.komodor
  ]
}
