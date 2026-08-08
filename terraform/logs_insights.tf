resource "aws_cloudwatch_query_definition" "app_error_spike_detection" {
  name = "${var.project_name}/app-error-spike-detection"

  log_group_names = [aws_cloudwatch_log_group.app.name]

  query_string = <<-EOT
    fields @timestamp, @message
    | filter @message like /ERROR/
    | stats count(*) as errorCount by bin(5m)
    | sort errorCount desc
  EOT
}

resource "aws_cloudwatch_query_definition" "app_recent_errors" {
  name = "${var.project_name}/app-recent-error-detail"

  log_group_names = [aws_cloudwatch_log_group.app.name]

  query_string = <<-EOT
    fields @timestamp, @message
    | filter @message like /ERROR/
    | sort @timestamp desc
    | limit 50
  EOT
}



