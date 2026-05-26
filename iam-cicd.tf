# IAM roles for codebuild and codepipeline

# CodeBuild role
resource "aws_iam_role" "codebuild_role" {
  name = "${local.name_prefix}-codebuild-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "codebuild.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# CodePipeline role
resource "aws_iam_role" "codepipeline_role" {
  name = "${local.name_prefix}-codepipeline-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "codepipeline.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# policy for codebuild to access ecr and s3
resource "aws_iam_policy" "codebuild_policy" {
  name = "${local.name_prefix}-codebuild-policy"
  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "logs:*"
        ]

        Resource = "*"
      },

      {
        Effect = "Allow"

        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]

        Resource = "*"
      },

      {
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]

        Resource = "${aws_s3_bucket.artifacts.arn}/*"
      },

      {
        Effect = "Allow"

        Action = [
          "codeconnections:UseConnection",
          "codestar-connections:UseConnection"
        ]

        Resource = var.codestar_connection_arn
      }
    ]
  })
}

# attach the codebuild policy to the codebuild role
resource "aws_iam_role_policy_attachment" "codebuild_policy_attachment" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = aws_iam_policy.codebuild_policy.arn
}

# policy for codepipeline
resource "aws_iam_policy" "codepipeline_policy" {
  name = "${local.name_prefix}-codepipeline-policy"
  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "codebuild:StartBuild",
          "codebuild:BatchGetBuilds"
        ]

        Resource = "*"
      },

      {
        Effect = "Allow"

        Action = [
          "codedeploy:*"
        ]

        Resource = "*"
      },

      {
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]

        Resource = "${aws_s3_bucket.artifacts.arn}/*"
      },

      {
        Effect = "Allow"

        Action = [
          "ecs:*"
        ]

        Resource = "*"
      },

      {
        Effect = "Allow"

        Action = [
          "iam:PassRole"
        ]

        Resource = "*"
      },

      {
        Effect = "Allow"

        Action = [
          "codeconnections:UseConnection",
          "codestar-connections:UseConnection"
        ]

        Resource = var.codestar_connection_arn
      }
    ]
  })
}

# attach the codepipeline policy to the codepipeline role
resource "aws_iam_role_policy_attachment" "codepipeline_policy_attachment" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.codepipeline_policy.arn
}