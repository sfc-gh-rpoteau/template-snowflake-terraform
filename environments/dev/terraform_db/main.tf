module "terraform_db" {
  source        = "../../../modules/terraform_db"
  database_name = "TERRAFORM_DB"

  tags = {
    environment = ["DEV", "TST", "PRD"]
    cost_center = ["ENGINEERING", "FINANCE", "MARKETING"]
  }
}

resource "snowflake_role" "terraform_db_admin" {
  provider = snowflake.securityadmin
  
  name = "TERRAFORM_DB_ADMIN"
  comment = "Role for managing the Terraform database"
}