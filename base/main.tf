terraform {
  required_providers {
  azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.27.0"
    }
  azuread = {
      source  = "hashicorp/azuread"
      version = "2.29.0"
  }
 }
}

provider "azurerm" {
  features {}
}

provider "azuread" {
  tenant_id = "bd36ce39-b4a8-41a4-8daa-ac53021dd01d"
}

resource "azurerm_resource_group" "rearcresourcegroup" {
  name     = "rg-${var.env}-${var.application}"
  location = var.location
}

resource "azurerm_storage_account" "rearcstorageaccount" {
  name                     = "sa${var.env}${var.application}${var.unique_id}"
  resource_group_name      = "rg-${var.env}-${var.application}"
  location                 = "${var.location}"
  account_tier             = "Standard"
  account_replication_type = "GRS"
}

data "azuread_client_config" "current" {
}

resource "azuread_application" "rearcadapplication" {
  display_name = "sp-${var.env}-${var.application}"
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "rearcserviceprincipal" {
  application_id               = azuread_application.rearcadapplication.application_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]
}

resource "azurerm_storage_container" "rearcstoragecontainer" {
  name                  = "sc-${var.env}-${var.application}"
  storage_account_name  = "sa${var.env}${var.application}${var.unique_id}"
  container_access_type = "private"
}

resource "azurerm_user_assigned_identity" "rearcassignid" {
  resource_group_name = "rg-${var.env}-${var.application}"
  location            = var.location

  name = "ai-${var.env}-${var.application}"

}