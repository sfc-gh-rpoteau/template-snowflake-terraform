terraform {
  required_version = "= 1.14.4"

  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "= 2.12.0"
    }
  }
  backend "s3" {}
}

provider "snowflake" {
  organization_name = var.organization_name
  account_name      = var.account_name
  user              = var.tf_user
  role              = var.tf_admin_role

  params = {
    query_tag = "managed_by=terraform"
  }
}

provider "snowflake" {
  alias             = "securityadmin"
  organization_name = var.organization_name
  account_name      = var.account_name
  user              = var.tf_user
  role              = var.tf_securityadmin_role

  params = {
    query_tag = "managed_by=terraform"
  }
}
