################ REFACTOR THESE

# output "dns_vm" {
# 	sensitive = true

# 	value = {
# 		alb_ip = contains(local.decom_v1_vms, local.my_env_short) ? "" : module.dns_vm.alb_ip
# 		internal_domain_name_suffix = contains(local.decom_v1_vms, local.my_env_short) ? "" : module.dns_vm.internal_domain_name_suffix
# 		vms = contains(local.decom_v1_vms, local.my_env_short) ? [] : module.dns_vm.vms
# 		vm_ssh_private_key = contains(local.decom_v1_vms, local.my_env_short) ? "" : module.dns_vm.vm_ssh_private_key
# 	}
# }

output "dns_vm_v2" {
	sensitive = true

	value = {
		alb_ip = module.dns_vm_v2.alb_ip
		internal_domain_name_suffix = module.dns_vm_v2.internal_domain_name_suffix
		vms = module.dns_vm_v2.vms
		vm_ssh_private_key = module.dns_vm_v2.vm_ssh_private_key
	}
}

# Created new output to address the sensitive value in for_each error
output "dns_vm_v2_ref" {
	value = module.dns_vm_v2.vms_ref
}

#######################

output "aks" {
	sensitive = true
	
	value = { for k, v in local.aks_instances :
		k => {
			host = azurerm_kubernetes_cluster.env[k].kube_admin_config[0].host
			client_certificate = base64decode(azurerm_kubernetes_cluster.env[k].kube_admin_config[0].client_certificate)
			client_key = base64decode(azurerm_kubernetes_cluster.env[k].kube_admin_config[0].client_key)
			cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.env[k].kube_admin_config[0].cluster_ca_certificate)
			nginx_ingress_alb_ip = kubernetes_service.nginx_ingress_lb[k].status[0].load_balancer[0].ingress[0].ip
			node_resource_group = azurerm_kubernetes_cluster.env[k].node_resource_group
			oidc_issuer_url = azurerm_kubernetes_cluster.env[k].oidc_issuer_url
		}
	}
}

output "app_config" {
	sensitive = true
	
	value = { for k, v in local.app_config_instances :
		k => {
			id = azurerm_app_configuration.env[k].id
			endpoint = azurerm_app_configuration.env[k].endpoint
			name = azurerm_app_configuration.env[k].name
			# Object should be removed when services and shared terraform get put back into base
			object = azurerm_app_configuration.env[k]
			primary_connection_string = lookup(v, "local_auth_enabled", false) ? azurerm_app_configuration.env[k].primary_write_key[0].connection_string : null
		}
	}
}

output "ase" {
	value = { for k, v in local.ase_instances_to_install :
		k => {
			asp = {
				id = azurerm_service_plan.env[k].id
			}
			cname_record = azurerm_private_dns_a_record.ase[k].fqdn
			dns = {
				zone_name = azurerm_private_dns_zone.ase[k].name
				zone_rg_name = azurerm_private_dns_zone.ase[k].resource_group_name
				suffix = azurerm_app_service_environment_v3.env[k].dns_suffix
			}
			location = azurerm_app_service_environment_v3.env[k].location
			primary_internal_ip_address = azurerm_app_service_environment_v3.env[k].internal_inbound_ip_addresses[0]
			rg_name = azurerm_app_service_environment_v3.env[k].resource_group_name
		}
	}
}

output "az_sql" {
	sensitive = true
	
	value = { for k, v in local.az_sql_instances :
		k => {
			identity = azurerm_user_assigned_identity.az_sql[k]
		}
	}
}

# This should not be needed once the refactor is done
output "certs" {
	sensitive = true

	value = {
		internal_pki = {
			env_ca_cert = tls_self_signed_cert.env_ca_cert
			env_issuer_cert = tls_locally_signed_cert.env_issuer_cert
			env_issuer_key = tls_private_key.env_issuer_key
		}
		nginx_ingress = { for k, v in local.aks_instances :
			k => {
				cert = tls_self_signed_cert.nginx_ingress_default_cert[k].cert_pem
				key = tls_private_key.nginx_ingress_default_key[k].private_key_pem
			}
		}
	}
}

output "disk_encryption_set" {
	value = {
		id = azurerm_disk_encryption_set.env.id
	}
}

output "dns" {
	value = {
		private_zone = {
			name = azurerm_private_dns_zone.env.name
			rg_name = azurerm_private_dns_zone.env.resource_group_name
		}
		public_zone = {
			name = azurerm_dns_zone.env.name
			rg_name = azurerm_dns_zone.env.resource_group_name
		}
	}
}

output "exos_services" {
	sensitive = true
	
	value = {
		identities = azurerm_user_assigned_identity.exos_services
	}
}

output "fabric_capacity" {
	value = { for k, v in local.fabric_capacity_instances_to_install :
		k => {
			principal_id = azurerm_user_assigned_identity.fabric[k].principal_id
		}
	}
}

output "key_vaults" {
	value = {
		common = { for k, v in local.key_vaults_common_to_deploy_iterator :
			k => {
				id = azurerm_key_vault.common[k].id
				name = azurerm_key_vault.common[k].name
				uri = azurerm_key_vault.common[k].vault_uri
			}
		}
		env = { for k, v in local.key_vaults_env :
			k => {
				id = azurerm_key_vault.env[k].id
				name = azurerm_key_vault.env[k].name
				uri = azurerm_key_vault.env[k].vault_uri
			}
		}
	}
}

output "network" {
	value = {
		firewalls = { for k, v in local.network_firewalls :
			k => {
				name = azurerm_firewall.env[k].name
				private_ip = azurerm_firewall.env[k].ip_configuration[0].private_ip_address
				public_ip = azurerm_public_ip.env[v["pip"]].ip_address
			}
		}
		local_address_spaces = local.network_info.local_address_spaces
		nsgs = { for k, v in local.network_nsgs :
			k => {
				id = azurerm_network_security_group.env[k].id
				name = azurerm_network_security_group.env[k].name
			}
		}
		public_ips = { for k, v in local.network_public_ips :
			k => {
				id = azurerm_public_ip.env[k].id
			}
		}
		service_address_spaces = local.network_info.service_address_spaces
		subnets = { for k, v in (flatten(
			[ for vnet_name, vnet_value in local.network_vnets :
				[ for subnet_name, subnet_value in vnet_value.subnets :
					{
						vnet_name = vnet_name
						subnet_name = subnet_name
					}
				]
			]
			)) : "${v.vnet_name}_${v.subnet_name}" => {
				address_space = azurerm_subnet.env["${v.vnet_name}_${v.subnet_name}"].address_prefixes[0] 
				id = azurerm_subnet.env["${v.vnet_name}_${v.subnet_name}"].id
				name = azurerm_subnet.env["${v.vnet_name}_${v.subnet_name}"].name
			}
		}
		vnets = { for k, v in local.network_vnets :
			k => {
				address_space = azurerm_virtual_network.env[k].address_space[0]
				name = azurerm_virtual_network.env[k].name
				rg = azurerm_virtual_network.env[k].resource_group_name
			}
		}
		# The following should not be needed once the full refactor is done
		aks_subnet_ids = local.network_info.aks_subnet_ids
		watcher = {
			name = azurerm_network_watcher.env.name
			rg_name = azurerm_network_watcher.env.resource_group_name
		}
	}
}

output "resource_groups" {
	value = { for k, v in azurerm_resource_group.env :
		k => {
			id = v.id
			name = v.name
			location = v.location
		}
	}
}

# !!!!! Alot of these outputs can be eliminated when services and shared are moved into base
# 06/28/2021 - tools is still needed to be outputted until the resources that use it in 01 are moved down
# 07/27/2021 - for service bus, only name and rg_name need to remain to feed values into the eng step for topics
output "service_bus" {
	sensitive = true

	value = { for k, v in local.service_bus_instances :
		k => {
			id = azurerm_servicebus_namespace.env[k].id
			name = azurerm_servicebus_namespace.env[k].name
			location = azurerm_servicebus_namespace.env[k].location
			rg_name = azurerm_servicebus_namespace.env[k].resource_group_name
			auth_rules = { for auth_rule_key, auth_rule_value in v.auth_rules :
				auth_rule_key => {
					primary_connection_string = azurerm_servicebus_namespace_authorization_rule.env["${k}_${auth_rule_key}"].primary_connection_string
					secondary_connection_string = azurerm_servicebus_namespace_authorization_rule.env["${k}_${auth_rule_key}"].secondary_connection_string
					primary_kv_name = auth_rule_value.injections["primary_connection_string"].kv_name
					secondary_kv_name = auth_rule_value.injections["secondary_connection_string"].kv_name
					primary_app_config_name = auth_rule_value.injections["primary_connection_string"].app_config_name
					secondary_app_config_name = auth_rule_value.injections["secondary_connection_string"].app_config_name
				}
			}
		}
	}
}

output "storage_accounts" {
	sensitive = true

	value = { for k, v in local.storage_accounts :
		k => {
			id = azurerm_storage_account.env[k].id
			name = azurerm_storage_account.env[k].name
			location = azurerm_storage_account.env[k].location
			rg_name = azurerm_storage_account.env[k].resource_group_name
			object = azurerm_storage_account.env[k]
			primary_blob_endpoint = azurerm_storage_account.env[k].primary_blob_endpoint
			primary_blob_host = azurerm_storage_account.env[k].primary_blob_host
			primary_connection_string = azurerm_storage_account.env[k].primary_connection_string
			secondary_connection_string = azurerm_storage_account.env[k].secondary_connection_string
		}
	}
}

output "storage_account_containers" {
	sensitive = true
	
	value = azurerm_storage_container.env
}

output "windows" {
	sensitive = true

	value = {
		identities = azurerm_user_assigned_identity.windows
		instances = local.windows_instances_to_install
		vms = azurerm_windows_virtual_machine.env
		albs = azurerm_lb.windows
		vips = azurerm_private_dns_a_record.windows_vips
	}
}
output "search_service" {
	sensitive = true
	value = {
		service_name = local.search_service_name
		service = azurerm_search_service.env
		service_uai = azurerm_user_assigned_identity.search_service_uai
	}
}
output "azure_maps" {
	value = { for k, v in azurerm_maps_account.env : k => v.id
		}
	}

output "cognitive" {
	sensitive = true
	
	value = azurerm_cognitive_account.env
}