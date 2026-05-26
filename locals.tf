# Local values for the Terraform configuration

locals {
  name_prefix = "${var.project_name}-${var.environment}"

  container_name = "app-container"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}