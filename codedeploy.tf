# CodeDeploy configuration blue/green deployment

# Iam role for codedeploy to access ecs and alb
resource "aws_iam_role" "codedeploy_role" {
  name = "${local.name_prefix}-codedeploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "codedeploy.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Attach the AWSCodeDeployRole policy to the CodeDeploy role
resource "aws_iam_role_policy_attachment" "codedeploy_policy" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}

# create codedeploy application
resource "aws_codedeploy_app" "ecs_app" {
  name             = "${local.name_prefix}-ecs-app"
  compute_platform = "ECS"
}

# attach deployment group to ecs service and alb target groups
resource "aws_codedeploy_deployment_group" "ecs_codedeploy_group" {
  app_name               = aws_codedeploy_app.ecs_app.name
  deployment_group_name  = "${local.name_prefix}-ecs-deployment-group"
  service_role_arn       = aws_iam_role.codedeploy_role.arn
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"

  deployment_style {
    deployment_type   = "BLUE_GREEN"
    deployment_option = "WITH_TRAFFIC_CONTROL"
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.main.name
    service_name = aws_ecs_service.backend_service.name
  }

  blue_green_deployment_config {

    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [
          aws_alb_listener.http.arn
        ]
      }
      test_traffic_route {
        listener_arns = [
          aws_alb_listener.test.arn
        ]
      }
      target_group {
        name = aws_alb_target_group.blue.name
      }
      target_group {
        name = aws_alb_target_group.green.name
      }
    }
  }
}