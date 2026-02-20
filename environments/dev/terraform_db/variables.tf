variable "organization_name" {
  description = "Snowflake organization"
  type        = string
  sensitive   = true
}

variable "account_name" {
  description = "Snowflake account"
  type        = string
  sensitive   = true
}

variable "tf_user" {
  description = "Snowflake service user for Terraform (shared across provider aliases)"
  type        = string
  sensitive   = true
}

variable "tf_admin_role" {
  description = "Snowflake role for object management (databases, schemas, etc.)"
  type        = string
  sensitive   = true
}

variable "tf_securityadmin_role" {
  description = "Snowflake role for grant management (MANAGE GRANTS)"
  type        = string
  sensitive   = true
}
