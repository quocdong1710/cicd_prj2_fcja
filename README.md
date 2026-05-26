# PRJ2 Terraform Learning Guide

Muc tieu: ban tu tao tung file Terraform de deploy kien truc:

```text
GitHub -> CodePipeline -> CodeBuild -> ECR -> ECS Fargate -> ALB -> RDS PostgreSQL
                                      |
                                      -> CodeDeploy blue/green
```

Thu muc app can auto deploy:

```text
D:\Code\project aws\prj2\aws-fcj-container-app
```

Luu y quan trong: CodePipeline khong doc truc tiep source code tu o `D:`. Ban can push app len GitHub repo, sau do CodePipeline lay source tu GitHub.

## 1. Tao `versions.tf`

Muc dich: khai bao Terraform version va provider can dung.

Viet gi:

- Terraform version
- AWS provider
- Random provider de tao DB password

Vi du syntax:

```hcl
terraform {
  required_version = ">= 1.15.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 6.0"
    }

    random = {
      source  = "hashicorp/random"
      version = ">= 3.6, < 4.0"
    }
  }
}
```

## 2. Tao `variables.tf`

Muc dich: khai bao cac bien dau vao de project de sua.

Viet gi:

- Region
- Project name
- Environment
- VPC CIDR
- Subnet CIDR
- Container port
- DB name/user
- GitHub owner/repo/branch
- CodeStar connection ARN

Vi du syntax:

```hcl
variable "aws_region" {
  type        = string
  description = "AWS region."
  default     = "ap-southeast-1"
}

variable "project_name" {
  type        = string
  description = "Project name."
  default     = "prj2"
}

variable "github_owner" {
  type        = string
  description = "GitHub owner or organization."
}
```

## 3. Tao `terraform.tfvars.example`

Muc dich: file mau de sau nay copy thanh `terraform.tfvars`.

Viet gi:

- Gia tri that hoac placeholder cho variables

Vi du syntax:

```hcl
aws_region   = "ap-southeast-1"
project_name = "prj2"
environment  = "dev"

github_owner            = "your-github-user"
github_repo             = "your-repo"
github_branch           = "main"
codestar_connection_arn = "arn:aws:codestar-connections:..."
```

## 4. Tao `providers.tf`

Muc dich: cau hinh AWS provider.

Viet gi:

- Region lay tu variable
- Default tags

Vi du syntax:

```hcl
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}
```

## 5. Tao `locals.tf`

Muc dich: tao gia tri dung lai nhieu lan.

Viet gi:

- Prefix ten resource
- Ten container
- Common tags

Vi du syntax:

```hcl
locals {
  name_prefix    = "${var.project_name}-${var.environment}"
  container_name = "app"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
```

## 6. Tao `data.tf`

Muc dich: lay thong tin co san tu AWS.

Viet gi:

- Availability Zones
- AWS account ID

Vi du syntax:

```hcl
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}
```

## 7. Tao `networking.tf`

Muc dich: tao VPC va subnet.

Viet gi:

- `aws_vpc`
- `aws_internet_gateway`
- Public subnets
- Private app subnets
- Private DB subnets
- Route tables
- NAT Gateway (elastic ip)

Vi du syntax:

```hcl
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}
```

## 8. Tao `security-groups.tf`

Muc dich: mo dung traffic can thiet.

Viet gi:

- ALB security group: Internet vao port 80
- ECS security group: ALB vao container port
- RDS security group: ECS vao port 5432

Vi du syntax:

```hcl
resource "aws_security_group" "alb" {
  name   = "${local.name_prefix}-alb-sg"
  vpc_id = aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}
```

## 9. Tao `ecr.tf`

Muc dich: tao Docker image registry.

Viet gi:

- ECR repository (name, image tag mutability, image scanning configuration)
- Image scan on push 
- Lifecycle policy neu muon (repository, policy)

Vi du syntax:

```hcl
resource "aws_ecr_repository" "app" {
  name                 = "${local.name_prefix}-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
```

## 10. Tao `secrets-rds.tf`

Muc dich: tao Mysql va luu password trong Secrets Manager.

Viet gi:

- `random_password` (dung name password cua local)
- `aws_secretsmanager_secret` (name)
- `aws_db_subnet_group` (name, subnet ids)
- `aws_db_instance` (identifier, instance storage, db name, username, password, port, db subnet group name, vpc security, skip final snapshot)
- `aws_secretsmanager_secret_version` (secret id, secret string)

Vi du syntax:

```hcl
resource "random_password" "db" {
  length  = 24
  special = false
}

resource "aws_secretsmanager_secret" "db" {
  name = "${local.name_prefix}/database"
}
```

## 11. Tao `iam-ecs.tf`

Muc dich: cap quyen cho ECS task.

Viet gi:

- ECS task execution role (name, assume role policy)
- Attach `AmazonECSTaskExecutionRolePolicy` (role, policy arn)
- Policy cho phep doc DB secret (name, policy)
- ECS task role (name, assume role policy)

Vi du syntax:

```hcl
resource "aws_iam_role" "ecs_task_execution" {
  name = "${local.name_prefix}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}
```

## 12. Tao `ecs.tf`

Muc dich: chay container tren ECS Fargate.

Viet gi:

- CloudWatch log group (name, retention)
- ECS cluster (name)
- ECS task definition (family, network mode, requires compatibility, cpu,memory, execution role arn, task role arn, container definition )
- ECS service (name, cluster, task definitation, desired count, launch type, network configuration, load balancer,depends on)

Vi du syntax:

```hcl
resource "aws_ecs_cluster" "main" {
  name = "${local.name_prefix}-cluster"
}

resource "aws_ecs_service" "app" {
  name            = "${local.name_prefix}-service"
  cluster         = aws_ecs_cluster.main.id
  desired_count   = 2
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.app.arn
}
```

## 13. Tao `alb.tf`

Muc dich: tao public endpoint cho user va target group blue/green.

Viet gi:

- Application Load Balancer (name,internal,lb type,security gr, subnet)
- Blue target group (name,port,protocol,target type, vpc, health check)
- Green target group
- Listener port 80 (lb arn, port, protocol, default action)
- Test listener port 8080 (lb arn, port, protocol, default action)

Vi du syntax:

```hcl
resource "aws_lb" "app" {
  name               = "${local.name_prefix}-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id
}

resource "aws_lb_target_group" "blue" {
  name        = "${local.name_prefix}-blue"
  port        = var.container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id
}
```

## 14. Tao `codedeploy.tf`

Muc dich: blue/green deployment cho ECS.

Viet gi:

- IAM role cho CodeDeploy (name, assume role policy)
- CodeDeploy app (name, compute platform)
- Deployment group gan voi ECS service va ALB target groups (app_name, deployment group name, service role arn, deployment config name, deployment style, ecs service, blue green deployment config, load balancer info)

Vi du syntax:

```hcl
resource "aws_codedeploy_app" "ecs" {
  name             = "${local.name_prefix}-ecs-app"
  compute_platform = "ECS"
}
```

## 15. Tao `iam-cicd.tf`

Muc dich: cap quyen cho CodeBuild va CodePipeline.

Viet gi:

- CodeBuild role (name, assume role policy)
- CodePipeline role (name, assume role policy)
- Policy cho CodeBuild:ECR, S3 artifact ; CodeDeploy: ECS, IAM PassRole (name, policy)

Vi du syntax:

```hcl
resource "aws_iam_role" "codebuild" {
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
```

## 16. Tao `cicd.tf`

Muc dich: tao pipeline tu GitHub den ECS.

Viet gi:

- S3 bucket artifact (bucket, force destroy)
- CodeBuild project (name, service role, artifacts, environment, source)
- CodePipeline 3 stage: Source, Build, Deploy (name, role arn, artifact store)
stage (name,action)

Vi du syntax:

```hcl
resource "aws_codepipeline" "app" {
  name     = "${local.name_prefix}-pipeline"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.artifacts.bucket
    type     = "S3"
  }
}
```

## 17. Tao `buildspec.yml`

Muc dich: cac lenh CodeBuild se chay de build Docker image.

Viet gi:

- Login ECR
- Build image
- Push image
- Tao `taskdef.json`
- Tao `appspec.yaml`

Vi du syntax:

```yaml
version: 0.2

phases:
  pre_build:
    commands:
      - echo "Login to ECR"
  build:
    commands:
      - docker build -t "$IMAGE_URI" .
  post_build:
    commands:
      - docker push "$IMAGE_URI"

artifacts:
  files:
    - taskdef.json
    - appspec.yaml
```

## 18. Tao `outputs.tf`

Muc dich: in ra thong tin can dung sau khi apply.

Viet gi:

- ALB URL
- ECR repository URL
- ECS cluster/service name
- RDS endpoint
- Secret ARN
- Pipeline name

Vi du syntax:

```hcl
output "alb_url" {
  description = "Application URL."
  value       = "http://${aws_lb.app.dns_name}"
}
```

## 19. Tao `.gitignore`

Muc dich: tranh commit state va secret local.

Viet gi:

```gitignore
.terraform/
.terraform.lock.hcl
terraform.tfstate
terraform.tfstate.*
*.tfvars
plan.out
```

## Cach chay bang Docker Terraform

Tu thu muc Terraform:

```powershell
cd "D:\Code\project aws\prj2\terraform-prj"
```

Neu dung AWS profile:

```powershell
docker run --rm -it `
  -v "${PWD}:/workspace" `
  -v "$env:USERPROFILE\.aws:/root/.aws" `
  -w /workspace `
  -e AWS_PROFILE=default `
  hashicorp/terraform:latest init
```

Plan:

```powershell
docker run --rm -it `
  -v "${PWD}:/workspace" `
  -v "$env:USERPROFILE\.aws:/root/.aws" `
  -w /workspace `
  -e AWS_PROFILE=default `
  hashicorp/terraform:latest plan -var-file="terraform.tfvars"
```

## Thu tu hoc de khong bi roi

```text
1. versions/providers/variables/locals/data
2. networking/security-groups
3. ecr/secrets-rds
4. iam-ecs/ecs
5. alb/codedeploy
6. iam-cicd/cicd/buildspec
7. outputs/gitignore
```

Bây giờ bạn chạy tiếp Terraform theo thứ tự này:

## init
docker run --rm -it `
  -v "${PWD}:/workspace" `
  -v "$env:USERPROFILE\.aws:/root/.aws" `
  -w /workspace `
  -e AWS_PROFILE=default `
  hashicorp/terraform:latest init

## format
docker run --rm -it `
  -v "${PWD}:/workspace" `
  -w /workspace `
  hashicorp/terraform:latest fmt -recursive

## validate
docker run --rm -it `
  -v "${PWD}:/workspace" `
  -v "$env:USERPROFILE\.aws:/root/.aws" `
  -w /workspace `
  -e AWS_PROFILE=default `
  hashicorp/terraform:latest validate

## plan
docker run --rm -it `
  -v "${PWD}:/workspace" `
  -v "$env:USERPROFILE\.aws:/root/.aws" `
  -w /workspace `
  -e AWS_PROFILE=default `
  hashicorp/terraform:latest plan -var-file="terraform.tfvars"

## apply
docker run --rm -it `
  -v "${PWD}:/workspace" `
  -v "$env:USERPROFILE\.aws:/root/.aws" `
  -w /workspace `
  -e AWS_PROFILE=default `
  hashicorp/terraform:latest apply -var-file="terraform.tfvars"

## kiem tra pipeline
docker run --rm -it `
  -v "$env:USERPROFILE\.aws:/root/.aws" `
  -e AWS_PROFILE=default `
  amazon/aws-cli codepipeline start-pipeline-execution `
  --name project2-dev-codepipeline `
  --region ap-southeast-1

docker run --rm -it `
  -v "$env:USERPROFILE\.aws:/root/.aws" `
  -e AWS_PROFILE=default `
  amazon/aws-cli codepipeline get-pipeline-state `
  --name project2-dev-codepipeline `
  --region ap-southeast-1 `
  --query "stageStates[].{stage:stageName,status:latestExecution.status,summary:latestExecution.summary}" `
  --output table

  
## destroy 
docker run --rm -it `
  -v "${PWD}:/workspace" `
  -v "$env:USERPROFILE\.aws:/root/.aws" `
  -w /workspace `
  -e AWS_PROFILE=default `
  hashicorp/terraform:latest destroy -var-file="terraform.tfvars"

Terraform sẽ hỏi:

Do you really want to destroy all resources?
Gõ:

yes
Lệnh này sẽ xóa các resource như:

CodePipeline
CodeBuild
CodeDeploy
ECS Service/Cluster
ALB
Target Groups
RDS
Secrets Manager secret
ECR
S3 artifact bucket
VPC/Subnet/NAT Gateway/Security Groups
IAM roles/policies
Nếu destroy bị lỗi vì ECR còn image, xóa image trước:

docker run --rm -it `
  -v "$env:USERPROFILE\.aws:/root/.aws" `
  -e AWS_PROFILE=default `
  amazon/aws-cli ecr batch-delete-image `
  --repository-name project2-dev-app `
  --image-ids imageTag=latest `
  --region ap-southeast-1
Rồi chạy lại destroy.

Nếu muốn “tắt tạm” ECS trước khi destroy, scale service về 0:

docker run --rm -it `
  -v "$env:USERPROFILE\.aws:/root/.aws" `
  -e AWS_PROFILE=default `
  amazon/aws-cli ecs update-service `
  --cluster project2-dev-cluster `
  --service project2-dev-backend-service `
  --desired-count 0 `
  --region ap-southeast-1
Nhưng để tránh tốn tiền thật sự, nên dùng terraform destroy, vì các thứ như NAT Gateway, ALB, RDS vẫn tính phí nếu chỉ stop ECS.

Sau khi destroy xong, kiểm tra lại:

docker run --rm -it `
  -v "$env:USERPROFILE\.aws:/root/.aws" `
  -e AWS_PROFILE=default `
  amazon/aws-cli ecs list-clusters `
  --region ap-southeast-1
Và vào AWS Console kiểm tra thêm các mục dễ tốn tiền:

EC2 -> Load Balancers
VPC -> NAT Gateways
RDS -> Databases
ECS -> Clusters
ECR -> Repositories
S3 -> Buckets
CodePipeline
Quan trọng nhất: NAT Gateway, RDS, ALB là mấy món nên xóa nếu không dùng nữa.