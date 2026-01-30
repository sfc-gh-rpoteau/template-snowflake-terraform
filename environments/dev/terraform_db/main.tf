module "terraform_db" {
  source        = "../../../modules/terraform_db"
  database_name = "TERRAFORM_DB"

  tags = {
    environment = ["DEV", "TST", "PRD"]
    owner       = ["ENGINEERING", "FINANCE", "MARKETING"]
  }
}