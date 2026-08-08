data "archive_file" "restart_ecs_task" {
  type        = "zip"
  source_file = "${path.module}/lambda/restart_ecs_task.py"
  output_path = "${path.module}/lambda/restart_ecs_task.zip"
}

data "archive_file" "tag_ec2_investigate" {
  type        = "zip"
  source_file = "${path.module}/lambda/tag_ec2_investigate.py"
  output_path = "${path.module}/lambda/tag_ec2_investigate.zip"
}

resource "aws_iam_role" "lambda_restart_ecs" {
  name = "${var.project_name}-lambda-restart-ecs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_restart_ecs_logs" {
  role       = aws_iam_role.lambda_restart_ecs.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_restart_ecs_permissions" {
  name = "${var.project_name}-lambda-restart-ecs-policy"
  role = aws_iam_role.lambda_restart_ecs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ecs:UpdateService", "ecs:DescribeServices"]
      Resource = aws_ecs_service.app.id
    }]
  })
}

resource "aws_lambda_function" "restart_ecs_task" {
  function_name    = "${var.project_name}-restart-ecs-task"
  role             = aws_iam_role.lambda_restart_ecs.arn
  handler          = "restart_ecs_task.handler"
  runtime          = "python3.12"
  timeout          = 30
  filename         = data.archive_file.restart_ecs_task.output_path
  source_code_hash = data.archive_file.restart_ecs_task.output_base64sha256

  environment {
    variables = {
      ECS_CLUSTER = aws_ecs_cluster.main.name
      ECS_SERVICE = aws_ecs_service.app.name
    }
  }
}

resource "aws_iam_role" "lambda_tag_ec2" {
  name = "${var.project_name}-lambda-tag-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_tag_ec2_logs" {
  role       = aws_iam_role.lambda_tag_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_tag_ec2_permissions" {
  name = "${var.project_name}-lambda-tag-ec2-policy"
  role = aws_iam_role.lambda_tag_ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["autoscaling:DescribeAutoScalingGroups", "ec2:DescribeInstances", "ec2:CreateTags"]
      Resource = "*"
    }]
  })
}

resource "aws_lambda_function" "tag_ec2_investigate" {
  function_name    = "${var.project_name}-tag-ec2-investigate"
  role             = aws_iam_role.lambda_tag_ec2.arn
  handler          = "tag_ec2_investigate.handler"
  runtime          = "python3.12"
  timeout          = 30
  filename         = data.archive_file.tag_ec2_investigate.output_path
  source_code_hash = data.archive_file.tag_ec2_investigate.output_base64sha256

  environment {
    variables = {
      ASG_NAME = aws_autoscaling_group.web.name
    }
  }
}
