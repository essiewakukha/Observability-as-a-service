resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name          = "${var.project_name}-ecs-cpu-high"
  alarm_description   = "ECS app tier average CPU above 80% for 2 consecutive 5-minute periods"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  threshold           = 80
  treat_missing_data  = "notBreaching"

  namespace   = "AWS/ECS"
  metric_name = "CPUUtilization"
  period      = 300
  statistic   = "Average"

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.app.name
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx_rate_high" {
  alarm_name          = "${var.project_name}-alb-5xx-rate-high"
  alarm_description   = "ALB 5xx error rate above 5% for 2 consecutive 5-minute periods"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  threshold           = 5
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "error_rate"
    expression  = "(m_5xx / m_total) * 100"
    label       = "5xx error rate (%)"
    return_data = true
  }

  metric_query {
    id = "m_5xx"
    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "HTTPCode_Target_5XX_Count"
      period      = 300
      stat        = "Sum"
      dimensions = {
        LoadBalancer = aws_lb.main.arn_suffix
      }
    }
  }

  metric_query {
    id = "m_total"
    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "RequestCount"
      period      = 300
      stat        = "Sum"
      dimensions = {
        LoadBalancer = aws_lb.main.arn_suffix
      }
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "app_errors" {
  name           = "${var.project_name}-app-error-filter"
  log_group_name = aws_cloudwatch_log_group.app.name
  pattern        = "\"ERROR\""

  metric_transformation {
    name          = "AppErrorCount"
    namespace     = "${var.project_name}/App"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "app_error_count_high" {
  alarm_name          = "${var.project_name}-app-error-count-high"
  alarm_description   = "More than 10 app error log lines in a single 5-minute period"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 10
  treat_missing_data  = "notBreaching"

  namespace   = aws_cloudwatch_log_metric_filter.app_errors.metric_transformation[0].namespace
  metric_name = aws_cloudwatch_log_metric_filter.app_errors.metric_transformation[0].name
  period      = 300
  statistic   = "Sum"
}
