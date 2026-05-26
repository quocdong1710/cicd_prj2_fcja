# print information about the created resources

# ALB DNS name
output "alb_url" {
  value       = "http://${aws_alb.main.dns_name}"
  description = "Application Load Balancer DNS"
}

# ECR cluster name
output "ecs_cluster_name" {
  value       = aws_ecs_cluster.main.name
  description = "ECS Cluster Name"
}

# ECR cluster service name
output "ecs_service_name" {
  value       = aws_ecs_service.backend_service.name
  description = "ECS Service Name"
}

# RDS endpoint
output "rds_endpoint" {
  value       = aws_db_instance.db_instance.address
  description = "RDS Endpoint"
}

# secret ARN
output "secret_arn" {
  value       = aws_secretsmanager_secret.db_secret.arn
  description = "ARN of the secret in Secrets Manager"
}

# pipeline name 
output "pipeline_name" {
  value       = aws_codepipeline.codepipeline.name
  description = "CodePipeline Name"
}