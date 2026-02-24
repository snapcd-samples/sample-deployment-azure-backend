module "sample" {
  source = "./module"
  stack_name = var.stack_name
  namespace_name = var.namespace_name
  azure_backend_tenant_id = var.azure_backend_tenant_id
  azure_backend_subscription_id = var.azure_backend_subscription_id
  azure_backend_resource_group_name = var.azure_backend_resource_group_name
  azure_backend_storage_account_name = var.azure_backend_storage_account_name
  azure_backend_storage_container_name = var.azure_backend_storage_container_name
  azure_backend_storage_path_prefix = var.azure_backend_storage_path_prefix
}