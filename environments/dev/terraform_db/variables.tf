variable "account_name" {
  description = "Snowflake account"
  type        = string
  sensitive   = true # Marks the variable as sensitive
}

variable "organization_name" {
  description = "Snowflake organization"
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

variable "tf_admin_private_key" {
  description = "Private key for the Terraform admin user"
  type        = string
  sensitive   = true # Marks the variable as sensitive
}

variable "tf_admin_private_key_passphrase" {
  description = "Passphrase for the encrypted private key"
  type        = string
  sensitive   = true # Marks the variable as sensitive
}

variable "securityadmin_user" {
  description = "Snowflake security admin user"
  type        = string
  sensitive   = true # Marks the variable as sensitive
}

variable "securityadmin_private_key" {
  description = "Snowflake security admin user"
  type        = string
  sensitive   = true # Marks the variable as sensitive
}

variable "securityadmin_private_key_passphrase" {
  description = "Passphrase for the encrypted private key"
  type        = string
  sensitive   = true # Marks the variable as sensitive
}