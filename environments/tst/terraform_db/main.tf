resource "snowflake_database" "terraform_db" {
  name = "TERRAFORM_DB"
}

resource "snowflake_schema" "secrets_schema" {
  name     = "SECRETS"
  database = snowflake_database.terraform_db.name
}

resource "snowflake_schema" "terraform_schema" {
  name     = "TAGS"
  database = snowflake_database.terraform_db.name
}
