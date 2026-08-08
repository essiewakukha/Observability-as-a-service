resource "aws_cloudwatch_event_rule" "ecs_cpu_alarm" {
  name        = "${var.project_name}-ecs-cpu-alarm-rule"
  description = "Fires when the ECS CPU alarm enters ALARM state"

  event_pattern = jsonencode({
    source        = ["aws.cloudwatch"]
    "detail-type" = ["CloudWatch Alarm State Change"]
    detail = {
      alarmName = [aws_cloudwatch_metric_alarm.ecs_cpu_high.alarm_name]
      state     = { value = ["ALARM"] }
    }
  })
}

resource "aws_cloudwatch_event_target" "ecs_cpu_to_lambda" {
  rule      = aws_cloudwatch_event_rule.ecs_cpu_alarm.name
  target_id = "restart-ecs-task-lambda"
  arn       = aws_lambda_function.restart_ecs_task.arn
}

resource "aws_lambda_permission" "allow_eventbridge_restart_ecs" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.restart_ecs_task.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ecs_cpu_alarm.arn
}

resource "aws_cloudwatch_event_rule" "alb_5xx_alarm" {
  name        = "${var.project_name}-alb-5xx-alarm-rule"
  description = "Fires when the ALB 5xx rate alarm enters ALARM state"

  event_pattern = jsonencode({
    source        = ["aws.cloudwatch"]
    "detail-type" = ["CloudWatch Alarm State Change"]
    detail = {
      alarmName = [aws_cloudwatch_metric_alarm.alb_5xx_rate_high.alarm_name]
      state     = { value = ["ALARM"] }
    }
  })
}

resource "aws_cloudwatch_event_target" "alb_5xx_to_sns" {
  rule      = aws_cloudwatch_event_rule.alb_5xx_alarm.name
  target_id = "notify-oncall-sns"
  arn       = aws_sns_topic.alerts.arn
}

resource "aws_cloudwatch_event_rule" "app_error_alarm" {
  name        = "${var.project_name}-app-error-alarm-rule"
  description = "Fires when the app ErrorCount alarm enters ALARM state"

  event_pattern = jsonencode({
    source        = ["aws.cloudwatch"]
    "detail-type" = ["CloudWatch Alarm State Change"]
    detail = {
      alarmName = [aws_cloudwatch_metric_alarm.app_error_count_high.alarm_name]
      state     = { value = ["ALARM"] }
    }
  })
}

resource "aws_cloudwatch_event_target" "app_error_to_lambda" {
  rule      = aws_cloudwatch_event_rule.app_error_alarm.name
  target_id = "tag-ec2-investigate-lambda"
  arn       = aws_lambda_function.tag_ec2_investigate.arn
}

resource "aws_lambda_permission" "allow_eventbridge_tag_ec2" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.tag_ec2_investigate.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.app_error_alarm.arn
}
