locals {

  komodor_cluster_name = local.aks_clusternames[var.env_ref]
  komodor_secret_name = "komodor-api-key"
  kv_region_key = local.basic["local"].region_short
  
}

data "azurerm_key_vault_secret" "komodor_api_key" {
  name         = local.komodor_secret_name
  key_vault_id = azurerm_key_vault.infra[var.env_ref].id
}


resource "kubernetes_secrets" "komodor" {
  metadata {
    name      = "komodor-secrets"
    namespace = var.komodor_namespace
}
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

 
  set {
    name  = "clusterName"
    value = local.komodor_cluster_name
  }

  # Values file ensures API key comes from secret
  values = [
    file("${path.module}/komodor/values-komodor.yaml")
  ]

  depends_on = [
    kubernetes_secret.komodor
  ]
}
