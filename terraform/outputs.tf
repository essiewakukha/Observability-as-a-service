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
output "ecs_cpu_alarm_name" {
  value = aws_cloudwatch_metric_alarm.ecs_cpu_high.alarm_name
}

output "alb_5xx_alarm_name" {
  value = aws_cloudwatch_metric_alarm.alb_5xx_rate_high.alarm_name
}

output "app_error_alarm_name" {
  value = aws_cloudwatch_metric_alarm.app_error_count_high.alarm_name
}

output "app_error_metric_namespace" {
  value = aws_cloudwatch_log_metric_filter.app_errors.metric_transformation[0].namespace
}
output "sns_alerts_topic_arn" {
  value = aws_sns_topic.alerts.arn
}

output "restart_ecs_lambda_name" {
  value = aws_lambda_function.restart_ecs_task.function_name
}

output "tag_ec2_lambda_name" {
  value = aws_lambda_function.tag_ec2_investigate.function_name
}

output "logs_s3_bucket_name" {
  value = aws_s3_bucket.logs.bucket
}

output "firehose_delivery_stream_name" {
  value = aws_kinesis_firehose_delivery_stream.logs.name
}

output "dashboard_name" {
  value = aws_cloudwatch_dashboard.main.dashboard_name
}
