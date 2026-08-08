resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"
}

# Optional email subscription - only created if notification_email is set.
# After apply, check that inbox for a "Subscription Confirmation" email and
# click confirm, or notifications won't actually be delivered.
resource "aws_sns_topic_subscription" "email" {
  count     = var.notification_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# EventBridge needs explicit permission to publish to this topic - SNS
# topics don't allow publishing by default from other AWS services.
resource "aws_sns_topic_policy" "allow_eventbridge" {
  arn = aws_sns_topic.alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowEventBridgePublish"
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action    = "sns:Publish"
      Resource  = aws_sns_topic.alerts.arn
    }]
  })
}
