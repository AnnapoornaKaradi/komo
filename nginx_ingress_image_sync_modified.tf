data "azurerm_key_vault_secret" "nginx_license_cert" {
	provider = azurerm.common
	
	name = "NginxIngressLicense--Cert"
	key_vault_id = data.terraform_remote_state.common.outputs.key_vaults.infra.common["eus2"].id
}

data "azurerm_key_vault_secret" "nginx_license_key" {
	provider = azurerm.common
	
	name = "NginxIngressLicense--Key"
	key_vault_id = data.terraform_remote_state.common.outputs.key_vaults.infra.common["eus2"].id
}

data "external" "nginx_ingress_image_sync" {
	for_each = {
  	  for k, v in data.terraform_remote_state.common.outputs.container_registries :
  	  k => v if v.public_network_access_enabled
	}

	program = [ "bash", "${path.module}/scripts/nginx_ingress_image_sync.sh", "data" ]
	
	query = {
		license_cert = data.azurerm_key_vault_secret.nginx_license_cert.value
		license_key = data.azurerm_key_vault_secret.nginx_license_key.value
		acr_name = data.terraform_remote_state.common.outputs.container_registries[each.key].name
		acr_fqdn = data.terraform_remote_state.common.outputs.container_registries[each.key].fqdn
		acr_sub_name = var.common_subscription_name[var.app_ref]
		dry_run = "true"
	}
}

resource "null_resource" "nginx_ingress_image_sync" {
	for_each = {
  	  for k, v in data.terraform_remote_state.common.outputs.container_registries :
  	  k => v if v.public_network_access_enabled
	}
	triggers = {
		changes = data.external.nginx_ingress_image_sync[each.key].result.changes
	}
	
	provisioner "local-exec" {
		command = "chmod +x ${path.module}/scripts/nginx_ingress_image_sync.sh; ${path.module}/scripts/nginx_ingress_image_sync.sh cli $LICENSE_CERT $LICENSE_KEY $ACR_NAME $ACR_FQDN $ACR_SUB_NAME $DRY_RUN"
		
		environment = {
			LICENSE_CERT = base64encode(data.azurerm_key_vault_secret.nginx_license_cert.value)
			LICENSE_KEY = base64encode(data.azurerm_key_vault_secret.nginx_license_key.value)
			ACR_NAME = data.terraform_remote_state.common.outputs.container_registries[each.key].name
			ACR_FQDN = data.terraform_remote_state.common.outputs.container_registries[each.key].fqdn
			ACR_SUB_NAME = var.common_subscription_name[var.app_ref]
			DRY_RUN = "false"
		}
	}
}
