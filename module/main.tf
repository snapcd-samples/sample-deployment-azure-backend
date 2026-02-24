
///////////////////////////////////////////////////////////////////////////////
//
// 1. Pre-existing resources.
//
// These resources are meant to be deployed after https://github.com/snapcd-samples/sample-deployment was already deployed. 
//
// To be clear, this deployment:
// - Is NOT a standalone sample, you must first deploy https://github.com/snapcd-samples/sample-deployment
// - Is NOT a wrapper for https://github.com/snapcd-samples/sample-deployment
// - Is a collection of additional Snap CD configuration resources that illustrate how you can configure your modules to use a remote Azure Backend
// - Uses the "MigrateState" flag (i.e. it will run "terraform init -migrate-state") so that any local state files that have already been in use in
//   https://github.com/snapcd-samples/sample-deployment will be migrated to the remote location
//
///////////////////////////////////////////////////////////////////////////////

data "snapcd_stack" "sample" {
  name = var.stack_name
}
data "snapcd_namespace" "sample" {
  name     = var.namespace_name
  stack_id = data.snapcd_stack.sample.id
}


resource "snapcd_namespace_input_from_definition" "azure_backend" {
  name            = "SNAPCD_MODULE_NAME"
  definition_name = "ModuleName"
  usage_mode      = "UseByDefault"
  namespace_id    = data.snapcd_namespace.sample.id
  input_kind      = "EnvVar"
}


resource "snapcd_namespace_terraform_flag" "flags" {
  for_each = toset(["MigrateState"])
  namespace_id = data.snapcd_namespace.sample.id
  task         = "Init"
  flag         = each.key
}

resource "snapcd_namespace_extra_file" "azure_backend" {
  file_name    = "extra_root.tf"
  contents     =  <<EOT
terraform {
  backend "azurerm" {}
}
  EOT
  namespace_id = data.snapcd_namespace.sample.id
  overwrite    = false
}

resource "snapcd_namespace_terraform_array_flag" "azure_backend" {
  for_each = {
    tenant_id            = var.azure_backend_tenant_id
    subscription_id      = var.azure_backend_subscription_id
    resource_group_name  = var.azure_backend_resource_group_name
    storage_account_name = var.azure_backend_storage_account_name
    container_name       = var.azure_backend_storage_container_name
    key                  = "${var.azure_backend_storage_path_prefix}/$${SNAPCD_MODULE_NAME}.tfstate"
  }

  namespace_id = data.snapcd_namespace.sample.id
  task         = "Init"
  flag         = "BackendConfig"  
  value        = "${each.key}=${each.value}"
}