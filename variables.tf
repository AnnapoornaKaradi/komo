
variable "env_ref" {
  description = "Environment short name (e.g., dev, uat, prod) that selects the API key."
  type        = string
}

variable "cluster_name" {
  description = "Cluster name label reported to Komodor (for display only)."
  type        = string
}

variable "kubeconfig_path" {
  description = "Path to kubeconfig used by Kubernetes/Helm providers."
  type        = string
  default     = "~/.kube/config"
}

variable "kube_context" {
  description = "Optional kubeconfig context to use. Leave empty to use current context."
  type        = string
  default     = ""
}
