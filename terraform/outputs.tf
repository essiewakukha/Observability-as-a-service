output "alb_dns_name" {
  description = "Public DNS name of the ALB - use this to hit the app"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  value = aws_lb.main.arn
}

output "alb_listener_arn" {
  value = aws_lb_listener.http.arn
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "web_asg_name" {
  value = aws_autoscaling_group.web.name
}

output "web_target_group_arn" {
  value = aws_lb_target_group.web.arn
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  value = aws_ecs_service.app.name
}

output "app_target_group_arn" {
  value = aws_lb_target_group.app.arn
}

output "app_log_group_name" {
  value = aws_cloudwatch_log_group.app.name
}

output "web_access_log_group_name" {
  value = aws_cloudwatch_log_group.web_access.name
}

output "web_error_log_group_name" {
  value = aws_cloudwatch_log_group.web_error.name
}

output "rds_endpoint" {
  value = aws_db_instance.main.endpoint
}

output "rds_instance_id" {
  value = aws_db_instance.main.id
}

output "rds_security_group_id" {
  value = aws_security_group.rds.id
}

output "ecs_security_group_id" {
  value = aws_security_group.ecs.id
}