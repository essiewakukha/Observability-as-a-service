resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "ALB Requests & 5xx Errors"
          view   = "timeSeries"
          region = var.aws_region
          period = 300
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.main.arn_suffix,
              { stat = "Sum", label = "Requests" }
            ],
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", aws_lb.main.arn_suffix,
              { stat = "Sum", label = "5xx Errors", yAxis = "right" }
            ],
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "ECS CPU & Memory"
          view   = "timeSeries"
          region = var.aws_region
          period = 300
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", aws_ecs_cluster.main.name, "ServiceName", aws_ecs_service.app.name,
              { stat = "Average", label = "CPU %" }
            ],
            ["AWS/ECS", "MemoryUtilization", "ClusterName", aws_ecs_cluster.main.name, "ServiceName", aws_ecs_service.app.name,
              { stat = "Average", label = "Memory %" }
            ],
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "RDS Connections & Latency"
          view   = "timeSeries"
          region = var.aws_region
          period = 300
          metrics = [
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", aws_db_instance.main.identifier,
              { stat = "Average", label = "Connections" }
            ],
            ["AWS/RDS", "ReadLatency", "DBInstanceIdentifier", aws_db_instance.main.identifier,
              { stat = "Average", label = "Read Latency", yAxis = "right" }
            ],
            ["AWS/RDS", "WriteLatency", "DBInstanceIdentifier", aws_db_instance.main.identifier,
              { stat = "Average", label = "Write Latency", yAxis = "right" }
            ],
          ]
        }
      },
      {
        type   = "alarm"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title = "Alarm Status Overview"
          alarms = [
            aws_cloudwatch_metric_alarm.ecs_cpu_high.arn,
            aws_cloudwatch_metric_alarm.alb_5xx_rate_high.arn,
            aws_cloudwatch_metric_alarm.app_error_count_high.arn,
          ]
        }
      },
    ]
  })
}
