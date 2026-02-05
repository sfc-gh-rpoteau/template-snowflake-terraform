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
  profile = "tf_admin"
  private_key = file(var.tf_admin_private_key)
  params = {
    query_tag = "managed_by=terraform"
  }
}
