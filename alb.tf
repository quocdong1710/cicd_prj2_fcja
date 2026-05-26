# create a public endpoint for user and target group for blue/green

# create application load balancer
resource "aws_alb" "main" {
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups = [
    aws_security_group.alb.id
  ]
  subnets = [
    aws_subnet.public_subnet1.id,
    aws_subnet.public_subnet2.id
  ]
}

# create target group for blue/green deployment
resource "aws_alb_target_group" "blue" {
  name        = "${local.name_prefix}-blue-tg"
  port        = var.backend_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id
  health_check {
    path    = "/health"
    matcher = "200"
  }
}
resource "aws_alb_target_group" "green" {
  name        = "${local.name_prefix}-green-tg"
  port        = var.backend_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id
  health_check {
    path    = "/health"
    matcher = "200"
  }
}

# create listener for ALB
resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_alb.main.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.blue.arn
  }
}

# create test listener port 8080
resource "aws_alb_listener" "test" {
  load_balancer_arn = aws_alb.main.arn
  port              = 8080
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.green.arn
  }
}