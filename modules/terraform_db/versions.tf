terraform {
  required_version = "~> 1.10"

  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "~> 2.12"
      configuration_aliases = [snowflake.securityadmin]
    }
  }
}