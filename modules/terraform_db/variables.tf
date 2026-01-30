variable "database_name" {
  description = "Name of the database"
  type        = string
  default     = "TERRAFORM_DB"
}

variable "tags" {
  description = "Map of tag names to allowed values. Empty list means no allowed_values constraint."
  type        = map(list(string))
  default     = {}
}
