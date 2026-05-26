# create aws secrets manager secret for RDS credentials

# create RDS instance and store credentials in secrets manager
resource "aws_secretsmanager_secret" "db_secret" {
  name = "${local.name_prefix}-db-credentials"
}

# create db subnet group for RDS instance
resource "aws_db_subnet_group" "db_subnet_group" {
  name = "${local.name_prefix}-db-subnet-group"

  subnet_ids = [
    aws_subnet.private_app_subnet_1.id, aws_subnet.private_app_subnet_2.id
  ]
}

# create RDS instance
resource "aws_db_instance" "db_instance" {
  identifier           = "${local.name_prefix}-db-instance"
  engine               = "mysql"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  db_name              = var.database_name
  username             = var.db_username
  password             = var.db_password
  port                 = var.database_port
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name

  vpc_security_group_ids = [
    aws_security_group.rds.id
  ]

  skip_final_snapshot = true
}

# store RDS credentials in secrets manager
resource "aws_secretsmanager_secret_version" "db_secret_value" {
  secret_id = aws_secretsmanager_secret.db_secret.id

  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
  })
}