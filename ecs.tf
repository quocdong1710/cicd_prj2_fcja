#run container on ECS Fargate

#store logs container logs in CloudWatch
resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/${local.name_prefix}"
  retention_in_days = 3
}

#ecs cluster
resource "aws_ecs_cluster" "main" {
  name = "${local.name_prefix}-cluster"
}

#ecs task definition
resource "aws_ecs_task_definition" "backend" {
  family                   = "${local.name_prefix}-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = "${aws_ecr_repository.app.repository_url}:latest"
      essential = true

      portMappings = [
        {
          containerPort = var.backend_port
          hostPort      = var.backend_port
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "DB_HOST"
          value = aws_db_instance.db_instance.address
        }
      ]

      secrets = [
        {
          name      = "DB_PASSWORD"
          valueFrom = "${aws_secretsmanager_secret.db_secret.arn}:password::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_log_group.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

#ecs service
resource "aws_ecs_service" "backend_service" {
  name            = "${local.name_prefix}-backend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets = [
      aws_subnet.private_app_subnet_1.id,
      aws_subnet.private_app_subnet_2.id
    ]
    security_groups = [
      aws_security_group.ecs.id
    ]
    assign_public_ip = false
  }

  load_balancer {
    container_name = "backend"
    container_port = var.backend_port

    target_group_arn = aws_alb_target_group.blue.arn
  }
  depends_on = [
    aws_alb_listener.http
  ]
  deployment_controller {
    type = "CODE_DEPLOY"
  }
}