// needed for init in root
variable "client_id" {}
variable "client_secret" { sensitive  = true }
variable "organization_id" {}

// passed into module
variable "stack_name" {}
variable "namespace_name" { default = "my-sample-namespace"}
variable "azure_backend_tenant_id" {}
variable "azure_backend_subscription_id" {}
variable "azure_backend_resource_group_name" {}
variable "azure_backend_storage_account_name" {}
variable "azure_backend_storage_container_name" {}
variable "azure_backend_storage_path_prefix" {}
variable "azure_backend_arm_client_id" { default = null }
variable "azure_backend_arm_client_secret_name" { default = null }
