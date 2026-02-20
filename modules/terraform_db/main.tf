# ============================================================================
# Terraform Database Module
# ============================================================================
# This module creates a Snowflake database and schema for Terraform to 
# store tags.
# ============================================================================

resource "snowflake_database" "terraform_db" {
  name = upper(var.database_name)
}

resource "snowflake_schema" "terraform_schema" {
  name     = "TAGS"
  database = snowflake_database.terraform_db.name
}

resource "snowflake_tag" "tags" {
  for_each = var.tags

  name           = upper(each.key)
  database       = snowflake_database.terraform_db.name
  schema         = snowflake_schema.terraform_schema.name
  allowed_values = length(each.value) > 0 ? each.value : null
}

resource "snowflake_account_role" "terraform_db_admin" {
  provider = snowflake.securityadmin

  name    = upper("${var.database_name}_ADMIN")
  comment = "Role for managing the ${var.database_name} database"
}
