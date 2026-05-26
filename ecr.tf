# create docker image registry

# create ECR repository for application
resource "aws_ecr_repository" "app" {
  name                 = "${local.name_prefix}-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

# lifecycle policy to keep only last 2 images
resource "aws_ecr_lifecycle_policy" "lifecycle_policy" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [{

      rulePriority = 1
      description  = "Keep only last 2 images"

      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 2
      }

      action = {
        type = "expire"
      }
    }]
  })
}