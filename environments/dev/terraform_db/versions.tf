terraform {
  required_version = "= 1.14.3"

  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "= 2.12.0"
    }
  }
  backend "local" {}
}

provider "snowflake" {
  organization_name = var.organization_name
  account_name = var.account_name
  user = var.tf_admin_user
  authenticator = "SNOWFLAKE_JWT"
  private_key = file(var.tf_admin_private_key)
  private_key_passphrase = var.tf_admin_private_key_passphrase
  params = {
    query_tag = "managed_by=terraform"
  }

}

# provider "snowflake" {
#   alias = "securityadmin"
#   organization_name = var.organization_name
#   account_name = var.account_name
#   user = var.securityadmin_user
#   authenticator = "SNOWFLAKE_JWT"
#   private_key = file(var.securityadmin_private_key)
#   private_key_passphrase = var.securityadmin_private_key_passphrase
#   params = {
#     query_tag = jsonencode({"managed_by":"terraform", "environment":"prd", "project":"terraform_db", "session_id":"${timestamp()}"})
#   }
# }

