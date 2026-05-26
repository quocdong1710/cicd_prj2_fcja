# Data sources for the Terraform configuration

# Fetch the availability zones in the current region
data "aws_availability_zones" "availability" {
  state = "available"
}

# Fetch the current AWS account ID
data "aws_caller_identity" "current" {

}