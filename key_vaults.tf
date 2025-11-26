#----- Create the vault for storing Common PaaS resource encryption keys
resource "azurerm_key_vault" "common_enc" {
	for_each = local.region_shorts

	provider = azurerm.common

	name = "kv-enc-${local.app_short}common-${each.value}${local.app_kv_numeric}"
	resource_group_name = azurerm_resource_group.common["infra_${each.value}"].name
	location = azurerm_resource_group.common["infra_${each.value}"].location
	tenant_id = var.tenant_id
	
	purge_protection_enabled = true
	enabled_for_disk_encryption = false
	
	sku_name = "premium"
	
	dynamic "access_policy" {
		for_each =  merge(
			local.kv_access_policies.common_devops,
			# Add the common network storage account identity
			{ store_common_network = {
				object_id = azurerm_storage_account.common_network[each.value].identity[0].principal_id
				key_permissions = [ "Get", "UnwrapKey", "WrapKey" ]
				secret_permissions = []
				certificate_permissions = []
			}},
			{ common_acr = {
				object_id = azurerm_user_assigned_identity.common2_uai.principal_id
				key_permissions = [ "Get", "UnwrapKey", "WrapKey" ]
				secret_permissions = []
				certificate_permissions = []
			}},
		)

		content {
			tenant_id = var.tenant_id
			object_id = access_policy.value["object_id"]
			key_permissions = access_policy.value["key_permissions"]
			secret_permissions = access_policy.value["secret_permissions"]
			certificate_permissions = access_policy.value["certificate_permissions"]
		}
	}
	
	network_acls {
		default_action = "Deny"
		bypass = "AzureServices"
			
		ip_rules = []
		virtual_network_subnet_ids = [
			azurerm_subnet.build_pool_lan["common_eus2"].id,		# Common build only exists in eus2 currently
			azurerm_subnet.build_pool_lan["core_eus2"].id,
		]
	}
	
	tags = merge(
		local.common_tags,
		local.resource_tags["key_vault"],
	)
	
	lifecycle {
		ignore_changes = [ tags ]
	}
}

# Add diagnostic logging
data "azurerm_monitor_diagnostic_categories" "common_enc_key_vault" {
	resource_id = azurerm_key_vault.common_enc[keys(azurerm_key_vault.common_enc)[0]].id
}

resource "azurerm_monitor_diagnostic_setting" "common_enc_key_vault" {
	for_each = local.region_shorts

	name = "log_all"
	target_resource_id = azurerm_key_vault.common_enc[each.key].id
	
	log_analytics_workspace_id = azurerm_log_analytics_workspace.common.id
	
	dynamic "enabled_log" {
		for_each = data.azurerm_monitor_diagnostic_categories.common_enc_key_vault.logs
		
		content {
			category = enabled_log.value
		}
	}
	
	dynamic "metric" {
		for_each = data.azurerm_monitor_diagnostic_categories.common_enc_key_vault.metrics
		
		content {
			category = metric.value
			enabled = true
		}
	}
}

#----- Create the vaults for the Infrastructure team
resource "azurerm_key_vault" "infra_common" {
	for_each = local.region_shorts

	provider = azurerm.common
	
	name = "kv-infra-${local.app_short}common-${each.value}${local.app_kv_numeric}"
	resource_group_name = azurerm_resource_group.common["infra_${each.value}"].name
	location = azurerm_resource_group.common["infra_${each.value}"].location
	tenant_id = var.tenant_id
	
	purge_protection_enabled = true
	enabled_for_disk_encryption = false
	
	sku_name = "premium"

	dynamic "access_policy" {
		for_each = merge(
			{
				azure_app_infra_exos = {
					object_id = local.my_mg.rbac.infra_group_oid
					tenant_id = var.tenant_id
					key_permissions = [ "Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import", "List", "Purge", "Recover", "Restore", "Sign", "UnwrapKey", "Update", "Verify", "WrapKey" ]
					secret_permissions = [ "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set" ]
					certificate_permissions = [ "Backup", "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers", "Import", "List", "ListIssuers", "ManageContacts", "ManageIssuers", "Purge", "Recover", "Restore", "SetIssuers", "Update" ]
				}
				infra_devops_spn = {
					object_id = var.devops_infra_spn_oid[var.app_ref]
					tenant_id = var.tenant_id
					key_permissions = [ "Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import", "List", "Purge", "Recover", "Restore", "Sign", "UnwrapKey", "Update", "Verify", "WrapKey", "GetRotationPolicy" ]
					secret_permissions = [ "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set" ]
					certificate_permissions = [ "Backup", "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers", "Import", "List", "ListIssuers", "ManageContacts", "ManageIssuers", "Purge", "Recover", "Restore", "SetIssuers", "Update" ]
				}
			},
			{ for k, v in local.management_groups : "${k}_devops_spn" => {
					object_id = v.rbac.devops_spn_oid
					tenant_id = var.tenant_id
					key_permissions = [ "Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import", "List", "Purge", "Recover", "Restore", "Sign", "UnwrapKey", "Update", "Verify", "WrapKey" ]
					secret_permissions = [ "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set" ]
					certificate_permissions = [ "Backup", "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers", "Import", "List", "ListIssuers", "ManageContacts", "ManageIssuers", "Purge", "Recover", "Restore", "SetIssuers", "Update" ]
				}
			}
		)
		
		content {
			tenant_id = var.tenant_id
			object_id = access_policy.value["object_id"]
			key_permissions = access_policy.value["key_permissions"]
			secret_permissions = access_policy.value["secret_permissions"]
			certificate_permissions = access_policy.value["certificate_permissions"]
		}
	}
	
	network_acls {
		# During the transitional phase, allow everything through the firewall
		default_action = "Deny"
		bypass = "AzureServices"
			
		ip_rules = concat(
			local.firewall_enterprise_trusted_list.ips,
			[
			],
		)
		virtual_network_subnet_ids = concat(
			# Allow all build servers access to this vault
			[ for k, v in azurerm_subnet.build_pool_lan : v.id ],
		)
	}
	
	tags = merge(
		local.common_tags,
		local.resource_tags["key_vault"],
	)
	
	lifecycle {
		ignore_changes = [ tags ]
	}
}

# Add diagnostic logging
data "azurerm_monitor_diagnostic_categories" "infra_common_key_vault" {
	resource_id = azurerm_key_vault.infra_common[keys(azurerm_key_vault.infra_common)[0]].id
}

resource "azurerm_monitor_diagnostic_setting" "infra_common_key_vault" {
	for_each = local.region_shorts
	
	name = "log_all"
	target_resource_id = azurerm_key_vault.infra_common[each.value].id
	
	log_analytics_workspace_id = azurerm_log_analytics_workspace.common.id
	
	dynamic "enabled_log" {
		for_each = data.azurerm_monitor_diagnostic_categories.infra_common_key_vault.logs
		
		content {
			category = enabled_log.value
		}
	}
	
	dynamic "metric" {
		for_each = data.azurerm_monitor_diagnostic_categories.infra_common_key_vault.metrics
		
		content {
			category = metric.value
			enabled = true
		}
	}
}
	
resource "azurerm_key_vault" "infra" {
	for_each = local.management_groups
		
	provider = azurerm.common
	
	name = "kv-infra-${local.app_short}${each.key}-eus2${local.app_kv_numeric}"
	resource_group_name = azurerm_resource_group.common["infra_eus2"].name
	location = azurerm_resource_group.common["infra_eus2"].location
	tenant_id = var.tenant_id
	
	purge_protection_enabled = true
	enabled_for_disk_encryption = false
	
	sku_name = "premium"
	
	dynamic "access_policy" {
		for_each = merge(
			{
				devops_spn = {
					object_id = each.value.rbac.devops_spn_oid
					key_permissions = [ "Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import", "List", "Purge", "Recover", "Restore", "Sign", "UnwrapKey", "Update", "Verify", "WrapKey", "GetRotationPolicy" ],
					secret_permissions = [ "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set" ],
					certificate_permissions = [ "Backup", "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers", "Import", "List", "ListIssuers", "ManageContacts", "ManageIssuers", "Purge", "Recover", "Restore", "SetIssuers", "Update" ]
				}
				mg_material_owners_group = {
					object_id = each.value.rbac.kv_material_owner_group_oid
					key_permissions = [ "Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import", "List", "Purge", "Recover", "Restore", "Sign", "UnwrapKey", "Update", "Verify", "WrapKey" ],
					secret_permissions = [ "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set" ],
					certificate_permissions = [ "Backup", "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers", "Import", "List", "ListIssuers", "ManageContacts", "ManageIssuers", "Purge", "Recover", "Restore", "SetIssuers", "Update" ]
				}
				mg_scm_material_users_group = {
					object_id = each.value.rbac.kv_scm_material_user_group_oid
					key_permissions = [ "Get", "List", "Verify", "Sign" ]
					secret_permissions = [ "Get", "List" ]
					certificate_permissions = []
				}
				mg_infra_material_users_group = {
					object_id = each.value.rbac.kv_infra_material_user_group_oid
					key_permissions = [ "Get", "List", "Verify", "Sign" ]
					secret_permissions = [ "Get", "List" ]
					certificate_permissions = []
				}
			},
		)

		content {
			tenant_id = var.tenant_id
			object_id = access_policy.value["object_id"]
			key_permissions = access_policy.value["key_permissions"]
			secret_permissions = access_policy.value["secret_permissions"]
			certificate_permissions = access_policy.value["certificate_permissions"]
		}
	}
		
	network_acls {
		# During the transitional phase, allow everything through the firewall
		default_action = "Deny"
		bypass = "AzureServices"
			
		ip_rules = concat(
			local.firewall_enterprise_trusted_list.ips,
			[
			],
		)
		virtual_network_subnet_ids = concat(
			# Only allow the build servers in the same management group to access this vault
			[ for k, v in azurerm_subnet.build_pool_lan : v.id if local.environments[split("_", k)[0]].management_group == each.key ],
		)
	}
	
	tags = merge(
		{
			environment = each.value["name"]
		},
		local.management_groups[each.key].tags,
		local.resource_tags["key_vault"],
	)
	
	lifecycle {
		ignore_changes = [ tags ]
	}
}

# Add diagnostic logging
data "azurerm_monitor_diagnostic_categories" "infra_key_vault" {
	resource_id = azurerm_key_vault.infra[keys(azurerm_key_vault.infra)[0]].id
}

resource "azurerm_monitor_diagnostic_setting" "infra_key_vault" {
	for_each = local.management_groups

	name = "log_all"
	target_resource_id = azurerm_key_vault.infra[each.key].id
	
	log_analytics_workspace_id = azurerm_log_analytics_workspace.common.id
	
	dynamic "enabled_log" {
		for_each = data.azurerm_monitor_diagnostic_categories.infra_key_vault.logs
		
		content {
			category = enabled_log.value
		}
	}
	
	dynamic "metric" {
		for_each = data.azurerm_monitor_diagnostic_categories.infra_key_vault.metrics
		
		content {
			category = metric.value
			enabled = true
		}
	}
}

#----- Create the vaults for the Release team
resource "azurerm_key_vault" "scm" {
	for_each = local.management_groups
		
	provider = azurerm.common
	
	name = "kv-scm-${local.app_short}${each.key}-eus2${local.app_kv_numeric}"
	resource_group_name = azurerm_resource_group.common["infra_eus2"].name
	location = azurerm_resource_group.common["infra_eus2"].location
	tenant_id = var.tenant_id
	
	purge_protection_enabled = true
	enabled_for_disk_encryption = false
	
	sku_name = "premium"
	
	dynamic "access_policy" {
		for_each = merge(
			{
				devops_spn = {
					object_id = each.value.rbac.devops_spn_oid
					key_permissions = [ "Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import", "List", "Purge", "Recover", "Restore", "Sign", "UnwrapKey", "Update", "Verify", "WrapKey", "GetRotationPolicy" ],
					secret_permissions = [ "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set" ],
					certificate_permissions = [ "Backup", "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers", "Import", "List", "ListIssuers", "ManageContacts", "ManageIssuers", "Purge", "Recover", "Restore", "SetIssuers", "Update" ]
				}
				infra_devops_spn = {
					object_id = var.devops_infra_spn_oid[var.app_ref]
					tenant_id = var.tenant_id
					key_permissions = [ "Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import", "List", "Purge", "Recover", "Restore", "Sign", "UnwrapKey", "Update", "Verify", "WrapKey", "GetRotationPolicy" ]
					secret_permissions = [ "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set" ]
					certificate_permissions = [ "Backup", "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers", "Import", "List", "ListIssuers", "ManageContacts", "ManageIssuers", "Purge", "Recover", "Restore", "SetIssuers", "Update" ]
				}
				mg_material_owners_group = {
					object_id = each.value.rbac.kv_material_owner_group_oid
					key_permissions = [ "Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import", "List", "Purge", "Recover", "Restore", "Sign", "UnwrapKey", "Update", "Verify", "WrapKey" ],
					secret_permissions = [ "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set" ],
					certificate_permissions = [ "Backup", "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers", "Import", "List", "ListIssuers", "ManageContacts", "ManageIssuers", "Purge", "Recover", "Restore", "SetIssuers", "Update" ]
				}
				mg_scm_material_users_group = {
					object_id = each.value.rbac.kv_scm_material_user_group_oid
					key_permissions = [ "Get", "List", "Verify", "Sign" ]
					secret_permissions = [ "Get", "List" ]
					certificate_permissions = []
				}
				mg_infra_material_users_group = {
					object_id = each.value.rbac.kv_infra_material_user_group_oid
					key_permissions = [ "Get", "List", "Verify", "Sign" ]
					secret_permissions = [ "Get", "List" ]
					certificate_permissions = []
				}
			},
		)

		content {
			tenant_id = var.tenant_id
			object_id = access_policy.value["object_id"]
			key_permissions = access_policy.value["key_permissions"]
			secret_permissions = access_policy.value["secret_permissions"]
			certificate_permissions = access_policy.value["certificate_permissions"]
		}
	}
		
	network_acls {
		default_action = "Deny"
		bypass = "AzureServices"
			
		ip_rules = concat(
			local.firewall_enterprise_trusted_list.ips,
			[
				"20.36.240.115/32",	# SL-EXOS-All   AZE2-C-EXO-plbOutboundInternet01
				"13.83.22.71/32",		# SL-EXOS-All   AZw-C-EXO-plbOutboundInternet01
			],
		)
		virtual_network_subnet_ids = concat(
			[ for k, v in azurerm_subnet.build_pool_lan : v.id if local.environments[split("_", k)[0]].management_group == each.key ],
		)
	}
	
	tags = merge(
		{
			environment = each.value["name"]
		},
		local.management_groups[each.key].tags,
		local.resource_tags["key_vault"],
	)
	
	lifecycle {
		ignore_changes = [ tags ]
	}
}

# Add diagnostic logging
data "azurerm_monitor_diagnostic_categories" "scm_key_vault" {
	resource_id = azurerm_key_vault.scm[keys(azurerm_key_vault.scm)[0]].id
}

resource "azurerm_monitor_diagnostic_setting" "scm_key_vault" {
	for_each = local.management_groups

	name = "log_all"
	target_resource_id = azurerm_key_vault.scm[each.key].id
	
	log_analytics_workspace_id = azurerm_log_analytics_workspace.common.id
	
	dynamic "enabled_log" {
		for_each = data.azurerm_monitor_diagnostic_categories.scm_key_vault.logs
		
		content {
			category = enabled_log.value
		}
	}
	
	dynamic "metric" {
		for_each = data.azurerm_monitor_diagnostic_categories.scm_key_vault.metrics
		
		content {
			category = metric.value
			enabled = true
		}
	}
}

#----- Create the vaults for the disk encryption
locals {
	sse_key_vault_access_policies = {
		eus2 = {
			infra_devops_spn = {
				object_id = var.devops_infra_spn_oid[var.app_ref]
				key_permissions = [ "Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import", "List", "Purge", "Recover", "Restore", "Sign", "UnwrapKey", "Update", "Verify", "WrapKey", "GetRotationPolicy" ]
				secret_permissions = [ "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set" ]
				certificate_permissions = [ "Backup", "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers", "Import", "List", "ListIssuers", "ManageContacts", "ManageIssuers", "Purge", "Recover", "Restore", "SetIssuers", "Update" ]
			}
			mg_material_owners_group = {
				object_id = local.management_groups["prod"].rbac.kv_material_owner_group_oid
				key_permissions = [ "Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import", "List", "Purge", "Recover", "Restore", "Sign", "UnwrapKey", "Update", "Verify", "WrapKey" ],
				secret_permissions = [ "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set" ],
				certificate_permissions = [ "Backup", "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers", "Import", "List", "ListIssuers", "ManageContacts", "ManageIssuers", "Purge", "Recover", "Restore", "SetIssuers", "Update" ]
			}
			des = {
				object_id = azurerm_disk_encryption_set.common["eus2"].identity.0.principal_id
				key_permissions = [	"Get", "Decrypt", "Encrypt", "Sign", "UnwrapKey", "Verify", "WrapKey" ]
				secret_permissions = []
				certificate_permissions = []
			}
		}
		wus2 = {
			infra_devops_spn = {
				object_id = var.devops_infra_spn_oid[var.app_ref]
				key_permissions = [ "Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import", "List", "Purge", "Recover", "Restore", "Sign", "UnwrapKey", "Update", "Verify", "WrapKey", "GetRotationPolicy" ]
				secret_permissions = [ "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set" ]
				certificate_permissions = [ "Backup", "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers", "Import", "List", "ListIssuers", "ManageContacts", "ManageIssuers", "Purge", "Recover", "Restore", "SetIssuers", "Update" ]
			}
			mg_material_owners_group = {
				object_id = local.management_groups["prod"].rbac.kv_material_owner_group_oid
				key_permissions = [ "Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import", "List", "Purge", "Recover", "Restore", "Sign", "UnwrapKey", "Update", "Verify", "WrapKey" ],
				secret_permissions = [ "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set" ],
				certificate_permissions = [ "Backup", "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers", "Import", "List", "ListIssuers", "ManageContacts", "ManageIssuers", "Purge", "Recover", "Restore", "SetIssuers", "Update" ]
			}
			des = {
				object_id = azurerm_disk_encryption_set.common["wus2"].identity.0.principal_id
				key_permissions = [	"Get", "Decrypt", "Encrypt", "Sign", "UnwrapKey", "Verify", "WrapKey" ]
				secret_permissions = []
				certificate_permissions = []
			}
		}
	}
}

resource "azurerm_key_vault" "sse" {
	for_each = local.region_shorts
		
	provider = azurerm.common
	
	name = "kv-sse-${local.app_short}common-${each.key}${local.app_kv_numeric}"
	resource_group_name = azurerm_resource_group.common["infra_${each.key}"].name
	location = azurerm_resource_group.common["infra_${each.key}"].location
	tenant_id = var.tenant_id
	
	purge_protection_enabled = true
	enabled_for_disk_encryption = true
	
	sku_name = "premium"
	
	network_acls {
		default_action = "Deny"
		bypass = "AzureServices"
		ip_rules = []
		virtual_network_subnet_ids = [
			azurerm_subnet.build_pool_lan["common_eus2"].id,
			azurerm_subnet.build_pool_lan["core_eus2"].id,
		]
	}
	
	tags = merge(
		local.common_tags,
		local.resource_tags["key_vault"],
	)
	
	lifecycle {
		ignore_changes = [ tags ]
	}
}

#----- Define access policies for the SSE vault which have to be separate due to cyclical redundancies with the identity creation
resource "azurerm_key_vault_access_policy" "sse" {
	for_each = { for k, v in flatten(
		[ for region_key, region_value in local.region_shorts :
			[ for policy_key, policy_value in local.sse_key_vault_access_policies[region_key] :
				{
					region_short = region_key
					policy_key = policy_key
					policy_value = policy_value
				}
			]
		]
	) : "${v.policy_key}_${v.region_short}" => v }

	key_vault_id = azurerm_key_vault.sse[each.value.region_short].id
	tenant_id = var.tenant_id
	object_id = each.value.policy_value.object_id
	
	key_permissions = each.value.policy_value.key_permissions
	secret_permissions = each.value.policy_value.secret_permissions
	certificate_permissions = each.value.policy_value.certificate_permissions
}

# Add diagnostic logging
data "azurerm_monitor_diagnostic_categories" "sse_key_vault" {
	resource_id = azurerm_key_vault.sse[keys(azurerm_key_vault.sse)[0]].id
}

resource "azurerm_monitor_diagnostic_setting" "sse_key_vault" {
	for_each = local.region_shorts

	name = "log_all"
	target_resource_id = azurerm_key_vault.sse[each.key].id
	
	log_analytics_workspace_id = azurerm_log_analytics_workspace.common.id
	
	dynamic "enabled_log" {
		for_each = data.azurerm_monitor_diagnostic_categories.sse_key_vault.logs
		
		content {
			category = enabled_log.value
		}
	}
	
	dynamic "metric" {
		for_each = data.azurerm_monitor_diagnostic_categories.sse_key_vault.metrics
		
		content {
			category = metric.value
			enabled = true
		}
	}
}