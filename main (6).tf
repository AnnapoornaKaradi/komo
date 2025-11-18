locals {
	regions = {
		primary = {
			name = "East US 2"
			name_short = "eus2"
			name_friendly = "east"
		}
		secondary = {
			name = "West US 2"
			name_short = "wus2"
			name_friendly = "west"
		}
	}

	regions_ai = {
		openai = {
			name = "North Central US"
			name_short = "ncus"
			name_friendly = "northcentral"
		}
	}
	regions_all = merge(local.regions, local.regions_ai)


	tags = merge(
		{
			environment = local.basic["local"].env
		},
		local.my_mg.tags,
	)
	
	common_tags = merge(
		{
			environment = "Common"
		},
		local.management_groups["prod"].tags,
	)
	
	geo_tags = (local.i_am_geo ?
		merge(
			{
				environment = local.basic["geo"].env
			},
			local.my_mg.tags,
		)
		:
		null
	)

	site_type = (
		local.regions["primary"].name_short == var.region_ref ? "primary" :
			local.regions["secondary"].name_short == var.region_ref ? "secondary" : null
	)

	partner_site_type = (
		local.regions["primary"].name_short == var.region_ref ? "secondary" :
			local.regions["secondary"].name_short == var.region_ref ? "primary" : null
	)
	
	i_am_geo = local.environments[local.environments[var.env_ref].name_short].geo_env_member
	i_am_active_geo = (local.environments[local.environments[var.env_ref].name_short].geo_env_member && local.environments[local.environments[var.env_ref].name_short].geo_env_active ? true : false)
	
	# Services are always active in a non geo environment.
	# For geo environments, it's active depending on site_type and dr_mode
	services_active = (
		(local.i_am_active_geo == false && local.site_type == "primary")
		|| (local.i_am_active_geo && (local.site_type == "primary" && local.my_env.keepers.dr_mode == false) || (local.site_type == "secondary" && local.my_env.keepers.dr_mode == true))
		? true : false
	)
	
	all_environments = {
		servicelink = local.servicelink_environments
		softpro = local.softpro_environments
	}
	
	all_management_groups = {
		servicelink = local.servicelink_management_groups
		softpro = local.softpro_management_groups
	}
	
	environments = local.all_environments[var.app_ref]
	management_groups = local.all_management_groups[var.app_ref]
	
	app_short = (
		var.app_ref == "servicelink" ? "" :
		var.app_ref == "softpro" ? "sp" :
		"unknown"
	)
	# This is being added because the numeric is pushing key vault names over the limit when trying to add app_short to the name
	app_kv_numeric = var.app_ref == "servicelink" ? "-01" : ""
	
	my_env = local.environments[var.env_ref]
	my_mg = local.management_groups[local.environments[var.env_ref].management_group]
	my_mg_ref = local.environments[var.env_ref].management_group
	my_env_short = local.basic["local"].env_short
	my_env_region_ref = "${local.basic["local"].env_short}_${local.basic["local"].region_short}"
	my_region_short = local.basic["local"].region_short
	partner_env_region_ref = (local.i_am_geo ? "${local.basic["partner"].env_short}_${local.basic["partner"].region_short}" : null)
	
	region_shorts = { for k, v in local.regions : v.name_short => v.name_short }
	region_shorts_ai = { for k, v in local.regions_ai : v.name_short => v.name_short }
	region_shorts_all = merge(local.region_shorts, local.region_shorts_ai)
	
	envs_to_regions = { for k, v in (flatten(
		[ for env_ref, env_value in local.environments : 
			[ for region_ref, region_value in (env_value.geo_env_member ? local.regions : { "primary" = local.regions["primary"] }) :
				{
					env = env_value.name
					env_short = env_value.name_short
					region = region_value.name
					region_short = region_value.name_short
					geo_env_member = env_value.geo_env_member
					build_pool_image_version = env_value.build_pool_image_version
					build_pool2_image_version = lookup( env_value, "build_pool2_image_version", null)
				}
			]
		])) : "${v.env_short}_${v.region_short}" => v
	}
	
	basic = {
		local = {
			region = local.regions[local.site_type].name
			region_short = local.regions[local.site_type].name_short
			env = local.environments[var.env_ref].name
			env_short = local.environments[var.env_ref].name_short
			env_region = "${local.environments[var.env_ref].name} ${local.regions[local.site_type].name}"
			env_region_short = "${local.environments[var.env_ref].name_short}_${local.regions[local.site_type].name_short}"
			dns_subdomain = local.i_am_geo ? "${local.environments[var.env_ref].name_short}${local.regions[local.site_type].name_friendly}" : local.environments[var.env_ref].name_short
		}
		partner = (local.i_am_geo ?
			{
				region = local.regions[local.partner_site_type].name
				region_short = local.regions[local.partner_site_type].name_short
				env = local.environments[var.env_ref].name
				env_short = local.environments[var.env_ref].name_short
				env_region = "${local.environments[var.env_ref].name} ${local.regions[local.partner_site_type].name}"
				env_region_short = "${local.environments[var.env_ref].name_short}_${local.regions[local.partner_site_type].name_short}"
				dns_subdomain = local.i_am_geo ? "${local.environments[var.env_ref].name_short}${local.regions[local.partner_site_type].name_friendly}" : local.environments[var.env_ref].name_short			
			}
			:
			null
		)
		geo = (local.i_am_geo ?
			{
				region = "Geo"
				region_short = "geo"
				env = local.environments[var.env_ref].name
				env_short = local.environments[var.env_ref].name_short
				env_region = "${local.environments[var.env_ref].name} Geo"
				env_region_short = "${local.environments[var.env_ref].name_short}_geo"
				dns_subdomain = local.environments[var.env_ref].name_short
			}
			:
			null
		)
	}
	
	kv_access_policies = {
		devops = {
			devops_spn = {
				object_id = local.my_mg.rbac.devops_spn_oid
				key_permissions = local.key_vault_access_policy_permission_sets.keys.all
				secret_permissions = local.key_vault_access_policy_permission_sets.secrets.all
				certificate_permissions = local.key_vault_access_policy_permission_sets.certificates.all
			}
		}
		common_devops = {
			devops_spn = {
				object_id = var.devops_infra_spn_oid[var.app_ref]
				key_permissions = [ "Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import", "List", "Purge", "Recover", "Restore", "Sign", "UnwrapKey", "Update", "Verify", "WrapKey", "GetRotationPolicy" ],
				secret_permissions = [ "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set" ],
				certificate_permissions = [ "Backup", "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers", "Import", "List", "ListIssuers", "ManageContacts", "ManageIssuers", "Purge", "Recover", "Restore", "SetIssuers", "Update" ]
			}
		}
		common = {
			devops_spn = {
				object_id = local.my_mg.rbac.devops_spn_oid
				key_permissions = [ "Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import", "List", "Purge", "Recover", "Restore", "Sign", "UnwrapKey", "Update", "Verify", "WrapKey", "GetRotationPolicy" ],
				secret_permissions = [ "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set" ],
				certificate_permissions = [ "Backup", "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers", "Import", "List", "ListIssuers", "ManageContacts", "ManageIssuers", "Purge", "Recover", "Restore", "SetIssuers", "Update" ]
			}
			mg_material_users_group = {
				object_id = local.my_mg.rbac.kv_material_user_group_oid
				key_permissions = [ "Get", "List", "Sign", "Verify" ]
				secret_permissions = [ "Get", "List" ]
				certificate_permissions = []
			}
			mg_material_owners_group = {
				object_id = local.my_mg.rbac.kv_material_owner_group_oid
				key_permissions = [ "Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import", "List", "Purge", "Recover", "Restore", "Sign", "UnwrapKey", "Update", "Verify", "WrapKey" ],
				secret_permissions = [ "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set" ],
				certificate_permissions = [ "Backup", "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers", "Import", "List", "ListIssuers", "ManageContacts", "ManageIssuers", "Purge", "Recover", "Restore", "SetIssuers", "Update" ]
			}
		}
		infra = {
			devops_spn = {
				object_id = local.my_mg.rbac.devops_spn_oid
				key_permissions = [ "Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import", "List", "Purge", "Recover", "Restore", "Sign", "UnwrapKey", "Update", "Verify", "WrapKey", "GetRotationPolicy" ],
				secret_permissions = [ "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set" ],
				certificate_permissions = [ "Backup", "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers", "Import", "List", "ListIssuers", "ManageContacts", "ManageIssuers", "Purge", "Recover", "Restore", "SetIssuers", "Update" ]
			}
			mg_infra_material_users_group = {
				object_id = local.my_mg.rbac.kv_infra_material_user_group_oid
				key_permissions = [ "Get", "List", "Sign", "Verify" ]
				secret_permissions = [ "Get", "List" ]
				certificate_permissions = []
			}
			mg_material_owners_group = {
				object_id = local.my_mg.rbac.kv_material_owner_group_oid
				key_permissions = [ "Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import", "List", "Purge", "Recover", "Restore", "Sign", "UnwrapKey", "Update", "Verify", "WrapKey" ],
				secret_permissions = [ "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set" ],
				certificate_permissions = [ "Backup", "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers", "Import", "List", "ListIssuers", "ManageContacts", "ManageIssuers", "Purge", "Recover", "Restore", "SetIssuers", "Update" ]
			}
		}
		dba = {
			devops_spn = {
				object_id = local.my_mg.rbac.devops_spn_oid
				key_permissions = [ "Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import", "List", "Purge", "Recover", "Restore", "Sign", "UnwrapKey", "Update", "Verify", "WrapKey", "GetRotationPolicy" ],
				secret_permissions = [ "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set" ],
				certificate_permissions = [ "Backup", "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers", "Import", "List", "ListIssuers", "ManageContacts", "ManageIssuers", "Purge", "Recover", "Restore", "SetIssuers", "Update" ]
			}
			mg_dba_material_users_group = {
				object_id = local.my_mg.rbac.kv_dba_material_user_group_oid
				key_permissions = [ "Get", "List", "UnwrapKey", "WrapKey", "Sign", "Verify" ]
				secret_permissions = [ "Get", "List" ]
				certificate_permissions = []
			}
			mg_material_owners_group = {
				object_id = local.my_mg.rbac.kv_material_owner_group_oid
				key_permissions = [ "Backup", "Create", "Decrypt", "Delete", "Encrypt", "Get", "Import", "List", "Purge", "Recover", "Restore", "Sign", "UnwrapKey", "Update", "Verify", "WrapKey" ],
				secret_permissions = [ "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set" ],
				certificate_permissions = [ "Backup", "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers", "Import", "List", "ListIssuers", "ManageContacts", "ManageIssuers", "Purge", "Recover", "Restore", "SetIssuers", "Update" ]
			}
		}
	}
	evh_diag_logging_capacity_spec = {
		default = 4
		env_region_override = {
			sandbox_eus2 = 2
			sand9_eus2 = 2
			sandbox_wus2 = 2
			sand9_wus2 = 2
		}
	}

	evh_diag_logging_maximum_throughput_units_spec =  {
		default = 4
		env_region_override = {
			sandbox_eus2 = 2
			sand9_eus2 = 2
			sandbox_wus2 = 2
			sand9_wus2 = 2
			prod_eus2 = 8
		}
	}
	evh_diag_logging_auto_inflate_enabled_spec = {
		default = true
		env_region_override = {
		}
	}
	evh_diag_logging_sku_spec = {
		default = "Standard"
	}
	evh_diag_logging_zone_redundant_spec = {
		default = false
		env_region_override = {
			prod_eus2 = true
		}
	}
}

data "azurerm_subscription" "current" {}
