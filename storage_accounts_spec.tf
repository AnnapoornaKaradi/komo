locals {

storage_accounts = {
	app = {
		name = "app"
		numeric = "01"
		rg_name = "data"
		network_rules = {
			bypass = [ "AzureServices" ]
			ips = local.resource_firewall_with_services.ips
			subnet_ids = concat(
				local.resource_firewall_with_services.subnet_ids,
			)
			subnet_id_refs = local.resource_firewall_with_services.subnet_id_refs
		}
		injections = {
			primary_connection_string = {
				attr = "primary_connection_string"
				kv_name = "ExosMacro--EXOS--StorageAccount--ReadWriteConnectionString"
				kv_ref = "app"
				app_config_name = "ExosMacro:StorageAccount:ReadWriteConnectionString"
				app_config_ref = "app"
			}
			secondary_connection_string = {
				attr = "secondary_connection_string"
				kv_name = "ExosMacro--EXOS--StorageAccount--ReadWriteConnectionStringSecondary"
				kv_ref = "app"
				app_config_name = "ExosMacro:StorageAccount:ReadWriteConnectionStringSecondary"
				app_config_ref = "app"
			}
		}
		containers = {
			agenticai = { name = "agenticai", deploy_step = "eng" }
			auction = { name = "auction", deploy_step = "eng" }
			auctions-adf = { name = "auctions-adf", deploy_step = "eng" }
			barcodedocuments = { name = "barcodedocuments", deploy_step = "eng" }
			client-vendor-exclusion = { name = "client-vendor-exclusion", deploy_step = "eng" }
			emailautomation = { name = "emailautomation", deploy_step = "eng" }
			etedata = { name = "etedata", deploy_step = "eng" }
			exosarchive = { name = "exosarchive", deploy_step = "eng" }
			exosautomation = { name = "exosautomation", deploy_step = "eng" }
			exosfileexports = { name = "exosfileexports", deploy_step = "eng" }
			expresspass = { name = "expresspass", deploy_step = "eng" }
			extractiondocuments = { name = "extractiondocuments", deploy_step = "eng" }
			fieldservices = { name = "fieldservices", deploy_step = "eng" }
			homevision = { name = "homevision", deploy_step = "eng" }
			i-miss-spark = { name = "i-miss-spark", deploy_step = "eng" }
			instantdecision-reports = { name = "instantdecision-reports", deploy_step = "eng" }
			instantdecision-trackingdata = { name = "instantdecision-trackingdata", deploy_step = "eng" }
			integrationdatastorage = { name = "integrationdatastorage", deploy_step = "eng" }
			onelake = { name = "onelake", deploy_step = "eng" }
			one-marketplace = { name = "one-marketplace", deploy_step = "eng" }
			one-marketplace-adf = { name = "one-marketplace-adf", deploy_step = "eng" }
			private = { name = "private", deploy_step = "eng" }
			private-backup = { name = "private-backup", deploy_step = "eng" }
			private-boa = { name = "private-boa", deploy_step = "eng" }
			pythonbridge = { name = "pythonbridge", deploy_step = "eng" }
			rfc = { name = "rfc", deploy_step = "eng" }
			scanneddocuments = { name = "scanneddocuments", deploy_step = "eng" }
			title = { name = "title", deploy_step = "eng" }
			titleintegrationgateway = { name = "titleintegrationgateway", deploy_step = "eng" }
			transientworkflowdata = { name = "transientworkflowdata", deploy_step = "eng" }
			root = { name = "root", deploy_step = "eng" }
			valuationreporting = { name = "valuationreporting", deploy_step = "eng" }
			vendorfollowup-adf = { name = "vendorfollowup-adf", deploy_step = "eng" }
			vendorpriority-adf = { name = "vendorpriority-adf", deploy_step = "eng" }
			vendorscoring-adf = { name = "vendorscoring-adf", deploy_step = "eng" }
			virtualclose = { name = "virtualclose", deploy_step = "eng" }
			elsarchive = { name = "elsarchive", deploy_step = "eng" }
		}
	}
	audit = {
		name = "audit"
		numeric = "01"
		rg_name = "data"
		network_rules = {
			bypass = [ "AzureServices" ]
			ips = local.resource_firewall_standard.ips
			subnet_ids = local.resource_firewall_standard.subnet_ids
			subnet_id_refs = local.resource_firewall_standard.subnet_id_refs
		}
	}	
	cdn = {
		name = "cdn"
		numeric = "01"
		rg_name = "data"
		allow_public_blob_access = true
		network_rules = {
			bypass = [ "None" ]
			ips = local.resource_firewall_with_services.ips
			subnet_ids = local.resource_firewall_with_services.subnet_ids,
			subnet_id_refs = distinct(concat(
				local.resource_firewall_with_services.subnet_id_refs,
				# Add the subnet that Nginx lives on
				[
					"backhaul_dmz",
				],
			))
		}
		injections = {
			primary_connection_string = {
				attr = "primary_connection_string"
				kv_name = "ExosMacro--EXOS--StorageAccount--CDNWriteConnectionString"
				kv_ref = "app"
				app_config_name = "ExosMacro:StorageAccount:CDNWriteConnectionString"
				app_config_ref = "app"
			}
			secondary_connection_string = {
				attr = "secondary_connection_string"
				kv_name = "ExosMacro--EXOS--StorageAccount--CDNReadWriteConnectionStringSecondary"
				kv_ref = "app"
				app_config_name = "ExosMacro:StorageAccount:CDNReadWriteConnectionStringSecondary"
				app_config_ref = "app"
			}
		}
		containers = {
			staticassets = { name = "staticassets", access_type = "blob", deploy_step = "eng" }
		}
	}

	cortex_xsiam = {
		name = "cortex"
		numeric = "01"
		rg_name = "data"
		network_rules = {
			bypass = [ "AzureServices" ]
			ips = local.resource_firewall_cortex_xsiam.ips
			subnet_ids = concat(
				local.resource_firewall_with_services.subnet_ids,
			)
			subnet_id_refs = local.resource_firewall_with_services.subnet_id_refs
		}
	}
	
	event_hub = {
		name = "evh"
		numeric = "01"
		rg_name = "data"
		network_rules = {
			bypass = [ "None" ]
			ips = local.resource_firewall_with_services.ips
			subnet_ids = local.resource_firewall_with_services.subnet_ids
			subnet_id_refs = local.resource_firewall_with_services.subnet_id_refs
		}
		injections = {
			primary_connection_string = {
				attr = "primary_connection_string"
				kv_name = "ExosMacro--EXOS--StorageAccount--EventHubReadWriteConnectionString"
				kv_ref = "app"
				app_config_name = "ExosMacro:StorageAccount:EventHubReadWriteConnectionString"
				app_config_ref = "app"
			}
			secondary_connection_string = {
				attr = "secondary_connection_string"
				kv_name = "ExosMacro--EXOS--StorageAccount--EventHubReadWriteConnectionStringSecondary"
				kv_ref = "app"
				app_config_name = "ExosMacro:StorageAccount:EventHubReadWriteConnectionStringSecondary"
				app_config_ref = "app"
			}
		}
		containers = {
			eventhubscheckpoint = { name = "eventhubscheckpoint", deploy_step = "eng" }
			transactiondatacheckpoint = { name = "transactiondatacheckpoint", deploy_step = "eng" }
		}
	}
	media_services = {
		name = "media"
		numeric = "01"
		rg_name = "data"
		network_rules = {
			bypass = [ "AzureServices" ]
			ips = local.resource_firewall_with_services.ips
			subnet_ids = local.resource_firewall_with_services.subnet_ids
			subnet_id_refs = local.resource_firewall_with_services.subnet_id_refs
		}
		injections = {
			primary_connection_string = {
				attr = "primary_connection_string"
				kv_name = "ExosMacro--EXOS--StorageAccount--MediaServicesReadWriteConnectionString"
				kv_ref = "app"
				app_config_name = "ExosMacro:StorageAccount:MediaServicesReadWriteConnectionString"
				app_config_ref = "app"
			}
			secondary_connection_string = {
				attr = "secondary_connection_string"
				kv_name = "ExosMacro--EXOS--StorageAccount--MediaServicesReadWriteConnectionStringSecondary"
				kv_ref = "app"
				app_config_name = "ExosMacro:StorageAccount:MediaServicesReadWriteConnectionStringSecondary"
				app_config_ref = "app"
			}
		}
		containers = {
			mediaprocessing = { name = "mediaprocessing", deploy_step = "eng" }
		}
		tables = {
			videochunk = { name = "videochunk", deploy_step = "eng" }
		}
		queues = {
			inspectmediaprocessingrequestqueue = { name = "inspectmediaprocessingrequestqueue", deploy_step = "eng" }
			inspectmediaprocessingrequestqueue-poison = { name = "inspectmediaprocessingrequestqueue-poison", deploy_step = "eng" }
			inspectmediaprocessingresponsequeue = { name = "inspectmediaprocessingresponsequeue", deploy_step = "eng" }
			inspectmediaprocessingresponsequeue-poison = { name = "inspectmediaprocessingresponsequeue-poison", deploy_step = "eng" }
			inspectmediaanalyticsrequestqueue = { name = "inspectmediaanalyticsrequestqueue", deploy_step = "eng" }
			inspectmediaanalyticsrequestqueue-poison = { name = "inspectmediaanalyticsrequestqueue-poison", deploy_step = "eng" }
			inspectmediaanalyticsresponsequeue = { name = "inspectmediaanalyticsresponsequeue", deploy_step = "eng" }
			inspectmediaanalyticsresponsequeue-poison = { name = "inspectmediaanalyticsresponsequeue-poison", deploy_step = "eng" }
			inspectmediaprocessingtrackingrequestqueue = { name = "inspectmediaprocessingtrackingrequestqueue", deploy_step = "eng" }
			inspectmediaprocessingtrackingrequestqueue-poison = { name = "inspectmediaprocessingtrackingrequestqueue-poison", deploy_step = "eng" }
			inspectmediaencodingresponsequeue = { name = "inspectmediaencodingresponsequeue", deploy_step = "eng" }
			inspectmediaencodingresponsequeue-poison = { name = "inspectmediaencodingresponsequeue-poison", deploy_step = "eng" }
		}	
	}
	network = {
		name = "network"
		numeric = "01"
		rg_name = "net"
		network_rules = {
			bypass = [ "AzureServices" ]
			ips = local.resource_firewall_build_only.ips
			subnet_ids = local.resource_firewall_build_only.subnet_ids
			subnet_id_refs = local.resource_firewall_build_only.subnet_id_refs
		}
	}
	print = {
		name = "print"
		numeric = "01"
		rg_name = "data"
		network_rules = {
			bypass = [ "None" ]
			ips = local.resource_firewall_standard.ips
			subnet_ids = local.resource_firewall_standard.subnet_ids
			subnet_id_refs = concat(
				local.resource_firewall_standard.subnet_id_refs,
				[
					"win_print",
				],
			)
		}
		injections = {
			primary_connection_string = {
				attr = "primary_connection_string"
				kv_name = "ExosMacro--EXOS--StorageAccount--PrintReadWriteConnectionString"
				kv_ref = "print"
				app_config_name = "ExosMacro:StorageAccount:PrintReadWriteConnectionString"
				app_config_ref = "app"
			}
			secondary_connection_string = {
				attr = "secondary_connection_string"
				kv_name = "ExosMacro--EXOS--StorageAccount--PrintReadWriteConnectionStringSecondary"
				kv_ref = "print"
				app_config_name = "ExosMacro:StorageAccount:PrintReadWriteConnectionStringSecondary"
				app_config_ref = "app"
			}
		}
	}
	ssrs = {
		name = "ssrs"                                                                                    
		numeric = "01"
		rg_name = "data"
		network_rules = {
			bypass = [ "None" ]
			ips = local.resource_firewall_with_services.ips
			subnet_ids = concat(
				local.resource_firewall_with_services.subnet_ids,
			)
			subnet_id_refs = local.resource_firewall_with_services.subnet_id_refs
		}
		file_shares = {
			ssrs = { name = "ssrs", deploy_step = "00" }
		}
	}
	wvd = {
		name = "wvd"                                                                                    
		numeric = "02"
		rg_name = "wvd"
		network_rules = {
			bypass = [ "AzureServices" ]
			ips = local.resource_firewall_with_services.ips
			subnet_ids = concat(
				local.resource_firewall_with_services.subnet_ids,
			)
			subnet_id_refs = local.resource_firewall_with_services.subnet_id_refs
		}
		file_shares = {
			packages = { name = "packages", deploy_step = "00" }
		}

		containers = {
			wvd_scripts = { name = "wvd-scripts", deploy_step = "00" }
		}
	}
	tools = {
		name = "tools"                                                                                    
		numeric = "01"
		rg_name = "infra"
		network_rules = {
			bypass = [ "None" ]
			ips = local.resource_firewall_standard.ips
			subnet_ids = concat(
				local.resource_firewall_standard.subnet_ids,
			)
			subnet_id_refs = concat(
				local.resource_firewall_with_services.subnet_id_refs,
				[
					"aks_lan",
					"backhaul_lan",
					"backhaul_dmz",
					"win_print",
					"win_ssrs",
				],
			)
		}
		conn_string_inject = null
		containers = {
			cse_scripts = { name = "cse-scripts", deploy_step = "00" }
		}
	}
	tmimages = {
		name = "tmimages"
		numeric = "01"
		rg_name = "data"
		network_rules = {
			bypass = [ "AzureServices" ]
			ips = local.resource_firewall_with_services.ips
			subnet_ids =local.resource_firewall_with_services.subnet_ids
			subnet_id_refs = local.resource_firewall_with_services.subnet_id_refs
		}
		containers = {
			images = { name = "images", deploy_step = "eng" }
			typed = { name = "typed", deploy_step = "eng" }
		}
		injections = {
			primary_connection_string = {
				attr = "primary_connection_string"
				kv_name = "ExosMacro--EXOS--StorageAccount--TmImagesReadWriteConnectionString"
				kv_ref = "app"
				app_config_name = "ExosMacro:StorageAccount:TmImagesReadWriteConnectionString"
				app_config_ref = "app"
			}
			secondary_connection_string = {
				attr = "secondary_connection_string"
				kv_name = "ExosMacro--EXOS--StorageAccount--TmImagesReadWriteConnectionStringSecondary"
				kv_ref = "app"
				app_config_name = "ExosMacro:StorageAccount:TmImagesReadWriteConnectionStringSecondary"
				app_config_ref = "app"
			}
		}
	}
	webjob = {
		name = "webjob"
		numeric = "01"
		rg_name = "data"
		network_rules = {
			bypass = [ "None" ]
			ips = local.resource_firewall_with_services.ips
			subnet_ids = local.resource_firewall_with_services.subnet_ids
			subnet_id_refs = local.resource_firewall_with_services.subnet_id_refs
		}
		injections = {
			primary_connection_string = {
				attr = "primary_connection_string"
				kv_name = "ExosMacro--EXOS--StorageAccount--WebJobsReadWriteConnectionString"
				kv_ref = "app"
				app_config_name = "ExosMacro:StorageAccount:WebJobsReadWriteConnectionString"
				app_config_ref = "app"
			}
			secondary_connection_string = {
				attr = "secondary_connection_string"
				kv_name = "ExosMacro--EXOS--StorageAccount--WebJobsReadWriteConnectionStringSecondary"
				kv_ref = "app"
				app_config_name = "ExosMacro:StorageAccount:WebJobsReadWriteConnectionStringSecondary"
				app_config_ref = "app"
			}
		}
		containers = {
			generalleases = { name = "generalleases", deploy_step = "eng" }
			title-data-leases = { name = "title-data-leases", deploy_step = "eng" }
		}
		tables = {
			etlfile = { name = "etlfile", deploy_step = "eng" }
			etlrecord = { name = "etlrecord", deploy_step = "eng" }
			shortlegal = { name = "shortlegal", deploy_step = "eng" }
			titledatahealthcheck = { name = "titledatahealthcheck", deploy_step = "eng" }
		}
		queues = {
			database-encryption-blob = { name = "database-encryption-blob", deploy_step = "eng" }
			database-encryption-cosmos = { name = "database-encryption-cosmos", deploy_step = "eng" }
			database-encryption-loaddata = { name = "database-encryption-loaddata", deploy_step = "eng" }
			database-encryption-loadtmdata = { name = "database-encryption-loadtmdata", deploy_step = "eng" }
			database-encryption-loadworkoderdata = { name = "database-encryption-loadworkoderdata", deploy_step = "eng" }
			database-hashing-loaddata = { name = "database-hashing-loaddata", deploy_step = "eng" }
			powerbi-encryption-loaddata = { name = "powerbi-encryption-loaddata", deploy_step = "eng" }
			title-data-import = { name = "title-data-import", deploy_step = "eng" }
			title-data-import-poison = { name = "title-data-import-poison", deploy_step = "eng" }
			title-data-persistence = { name = "title-data-persistence", deploy_step = "eng" }
			title-data-persistence-poison = { name = "title-data-persistence-poison", deploy_step = "eng" }
			title-data-validation = { name = "title-data-validation", deploy_step = "eng" }
			title-data-validation-poison = { name = "title-data-validation-poison", deploy_step = "eng" }
		}
	}
	search_service = {
		name = "search"
		numeric = "01"
		rg_name = "data"
		network_rules = {
			bypass = [ "AzureServices" ]
			ips = local.resource_firewall_with_services.ips
			subnet_ids = local.resource_firewall_with_services.subnet_ids
			subnet_id_refs = local.resource_firewall_with_services.subnet_id_refs
		}
		containers = {
			searchstorage = { name = "searchstorage", deploy_step = "00" }
		}
	}
}
}