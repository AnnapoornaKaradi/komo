locals {
	  aks_clusternames = { for k, v in local.aks_instances :
		    k => (v.name == "" ?
			      lower("aks-${local.basic["local"].env_short}-${local.basic["local"].region_short}-${v.numeric}")
			      :
			      lower("aks-${v.name}-${local.basic["local"].env_short}-${local.basic["local"].region_short}-${v.numeric}")
		    )
    }

    komodor_secret_name  = "komodor-api-key"
    kv_region_key = local.basic["local"].region_short
    kv_name = "kv-infra-${local.app_short}${local.my_env_short}-eus2${local-app_kv_numeric}"
    komodor_cluster_name = local.aks_clusternames[var.env_ref]
}


data "azurerm_key_vault_secret" "komodor_api_key" {
  name         = local.komodor_secret_name
  key_vault_id = local.kv_name
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
