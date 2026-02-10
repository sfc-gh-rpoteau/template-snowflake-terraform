variable "organization_name" {
  description = "Snowflake organization"
  type        = string
  sensitive   = true # Marks the variable as sensitive
}

variable "account_name" {
  description = "Snowflake account"
  type        = string
  sensitive   = true # Marks the variable as sensitive
}

variable "tf_admin_role" {
  description = "Snowflake admin role"
  type        = string
  sensitive   = true # Marks the variable as sensitive
}

variable "tf_admin_user" {
  description = "Snowflake admin user"
  type        = string
  sensitive   = true # Marks the variable as sensitive
}
