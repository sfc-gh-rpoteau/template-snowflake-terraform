variable "tf_admin_private_key" {
  description = "Snowflake security admin user"
  type        = string
  sensitive   = true # Marks the variable as sensitive
}
