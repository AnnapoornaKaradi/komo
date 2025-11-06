
#############################################
# Minimal Komodor install via Helm provider #
#############################################

# 1) Environment → API key map (non-sensitive by your policy)
locals {
  komodor_api_keys = {
    dev  = "dev-APIKEY-123"   # <-- replace with real keys
    uat  = "uat-APIKEY-456"
    prod = "prod-APIKEY-789"
  }
}

# 2) Namespace for Komodor
resource "kubernetes_namespace" "komodor" {
  metadata { name = "komodor" }
}

# 3) Komodor agent Helm release
resource "helm_release" "komodor" {
  name       = "komodor-agent"
  repository = "https://helm-charts.komodor.io"
  chart      = "komodor-agent"
  # Optionally pin a specific version, e.g.:
  # version    = "x.y.z"
  namespace  = kubernetes_namespace.komodor.metadata[0].name

  # Non-secret chart values
  values = [
    templatefile("${path.module}/values-komodor.yaml", {
      clusterName = var.cluster_name
    })
  ]

  # Pass API key directly using env
  set {
    name  = "apiKey"
    value = local.komodor_api_keys[var.env_ref]
  }
}
