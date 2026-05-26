# declaration of variables for the project

# AWS region and availability zones
variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "ap-southeast-1" #singapore
}

variable "aws_az1" {
  type        = string
  description = "AWS availability zone 1"
  default     = "ap-southeast-1a" #singapore
}

variable "aws_az2" {
  type        = string
  description = "AWS availability zone 2"
  default     = "ap-southeast-1b" #singapore
}

# project name and environment
variable "project_name" {
  type        = string
  description = "Project name"
  default     = "project2"
}

variable "environment" {
  type        = string
  description = "Environment dev"
  default     = "dev"
}

# Github owner details
variable "github_owner" {
  type        = string
  description = "github owner"
}

# Github repository details
variable "github_repo" {
  type        = string
  description = "github repository"
}

# Github branch details
variable "github_branch" {
  type        = string
  description = "github branch"
  default     = "main"
}

# vpc and subnet cidr blocks
variable "aws_vpc_cidr" {
  type        = string
  description = "aws vpc cidr"
  default     = "10.0.0.0/16"
}
variable "aws_public_subnet_cidr" {
  type        = list(string)
  description = "aws subnet cidr public"
  default     = ["10.0.0.0/20", "10.0.16.0/20"]
}
variable "aws_private_subnet_cidr" {
  type        = list(string)
  description = "aws subnet cidr private"
  default     = ["10.0.128.0/20", "10.0.144.0/20"]
}

# ALB and ECS ports
variable "database_port" {
  type        = number
  description = "database container port"
  default     = 3306
}
variable "frontend_port" {
  type        = number
  description = "frontend container port"
  default     = 8000
}
variable "backend_port" {
  type        = number
  description = "backend container port"
  default     = 3000
}

# database credentials
variable "database_name" {
  type        = string
  description = "Database name"
  default     = "mydb"
}
variable "db_username" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

# codestar connection ARN for github actions
variable "codestar_connection_arn" {
  type        = string
  description = "codestar connection ARN"
}