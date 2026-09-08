resource "azurerm_resource_group" "app" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_service_plan" "app" {
  name                     = var.plan_name
  resource_group_name      = azurerm_resource_group.app.name
  location                 = azurerm_resource_group.app.location
  os_type                  = "Linux"
  sku_name                 = var.sku_name
  worker_count             = 1
  per_site_scaling_enabled = false
  zone_balancing_enabled   = false
  tags                     = var.resource_tags
}

resource "azurerm_linux_web_app" "app" {
  name                                           = var.web_app_name
  resource_group_name                            = azurerm_resource_group.app.name
  location                                       = azurerm_service_plan.app.location
  service_plan_id                                = azurerm_service_plan.app.id
  enabled                                        = true
  https_only                                     = true
  public_network_access_enabled                  = var.public_network_access_enabled
  client_affinity_enabled                        = true
  client_certificate_enabled                     = false
  client_certificate_mode                        = "Required"
  ftp_publish_basic_authentication_enabled       = false
  webdeploy_publish_basic_authentication_enabled = false
  tags                                           = var.resource_tags

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on                   = var.sku_name != "F1"
    app_command_line            = "node index.js"
    ftps_state                  = "Disabled"
    http2_enabled               = true
    minimum_tls_version         = "1.2"
    scm_minimum_tls_version     = "1.2"
    use_32_bit_worker           = true
    websockets_enabled          = false
    scm_use_main_ip_restriction = false

    application_stack {
      node_version = "24-lts"
    }
  }

  app_settings = {
    SCM_DO_BUILD_DURING_DEPLOYMENT = "true"
    WEBSITE_NODE_DEFAULT_VERSION   = "~24"
  }
}