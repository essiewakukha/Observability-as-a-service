data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# ---- IAM for EC2 instances ----

resource "aws_iam_role" "web_instance" {
  name = "${var.project_name}-web-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "web_cw_agent" {
  role       = aws_iam_role.web_instance.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "web_ssm" {
  role       = aws_iam_role.web_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "web" {
  name = "${var.project_name}-web-instance-profile"
  role = aws_iam_role.web_instance.name
}

# ---- CloudWatch Agent config (pulled by instances at boot) ----

resource "aws_ssm_parameter" "cw_agent_config" {
  name = "/${var.project_name}/cloudwatch-agent/config"
  type = "String"
  value = templatefile("${path.module}/templates/cw_agent_config.json.tpl",
{
    project_name = var.project_name
  })
}

resource "aws_cloudwatch_log_group" "web_access" {
  name              = "/${var.project_name}/web/access"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "web_error" {
  name              = "/${var.project_name}/web/error"
  retention_in_days = 14
}

# ---- ALB ----

resource "aws_lb" "main" {
  name               = "${var.short_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  tags = {
    Name = "${var.short_name}-alb"
  }
}

resource "aws_lb_target_group" "web" {
  name     = "${var.short_name}-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# ---- Launch template + ASG ----

resource "aws_launch_template" "web" {
  name_prefix   = "${var.project_name}-web-"
  image_id      = data.aws_ssm_parameter.al2023_ami.value
  instance_type = var.web_instance_type

  iam_instance_profile {
    arn = aws_iam_instance_profile.web.arn
  }

  vpc_security_group_ids = [aws_security_group.web.id]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-web"
    }
  }

  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh.tpl", {
    project_name        = var.project_name
    cw_agent_param_name = aws_ssm_parameter.cw_agent_config.name
  }))
}

resource "aws_autoscaling_group" "web" {
  name                = "${var.project_name}-web-asg"
  min_size            = var.web_min_size
  max_size            = var.web_max_size
  desired_capacity    = var.web_desired_capacity
  vpc_zone_identifier = aws_subnet.public[*].id
  target_group_arns   = [aws_lb_target_group.web.arn]

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-web"
    propagate_at_launch = true
  }
}