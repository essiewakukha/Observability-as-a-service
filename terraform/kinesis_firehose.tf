data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "logs" {
  bucket = "${var.project_name}-logs-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "expire-old-logs"
    status = "Enabled"
    filter {}

    expiration {
      days = 90
    }
  }
}

resource "aws_iam_role" "firehose" {
  name = "${var.project_name}-firehose-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "firehose.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "firehose_s3" {
  name = "${var.project_name}-firehose-s3-policy"
  role = aws_iam_role.firehose.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:PutObject",
        "s3:GetBucketLocation",
        "s3:ListBucket",
        "s3:AbortMultipartUpload",
        "s3:ListBucketMultipartUploads",
      ]
      Resource = [
        aws_s3_bucket.logs.arn,
        "${aws_s3_bucket.logs.arn}/*",
      ]
    }]
  })
}

resource "aws_cloudwatch_log_group" "firehose_delivery" {
  name              = "/aws/kinesisfirehose/${var.project_name}-logs"
  retention_in_days = 14
}

resource "aws_iam_role_policy" "firehose_logs" {
  name = "${var.project_name}-firehose-logs-policy"
  role = aws_iam_role.firehose.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["logs:PutLogEvents"]
      Resource = "${aws_cloudwatch_log_group.firehose_delivery.arn}:*"
    }]
  })
}

resource "aws_kinesis_firehose_delivery_stream" "logs" {
  name        = "${var.project_name}-logs-stream"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose.arn
    bucket_arn = aws_s3_bucket.logs.arn
    prefix     = "cloudwatch-logs/"

    buffering_size     = 5
    buffering_interval = 300

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.firehose_delivery.name
      log_stream_name = "S3Delivery"
    }
  }
}

resource "aws_iam_role" "cwl_to_firehose" {
  name = "${var.project_name}-cwl-to-firehose-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "logs.${var.aws_region}.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "cwl_to_firehose_permissions" {
  name = "${var.project_name}-cwl-to-firehose-policy"
  role = aws_iam_role.cwl_to_firehose.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["firehose:PutRecord", "firehose:PutRecordBatch"]
      Resource = aws_kinesis_firehose_delivery_stream.logs.arn
    }]
  })
}

resource "aws_cloudwatch_log_subscription_filter" "app_to_firehose" {
  name            = "${var.project_name}-app-to-firehose"
  log_group_name  = aws_cloudwatch_log_group.app.name
  filter_pattern  = ""
  destination_arn = aws_kinesis_firehose_delivery_stream.logs.arn
  role_arn        = aws_iam_role.cwl_to_firehose.arn
}

resource "aws_cloudwatch_log_subscription_filter" "web_access_to_firehose" {
  name            = "${var.project_name}-web-access-to-firehose"
  log_group_name  = aws_cloudwatch_log_group.web_access.name
  filter_pattern  = ""
  destination_arn = aws_kinesis_firehose_delivery_stream.logs.arn
  role_arn        = aws_iam_role.cwl_to_firehose.arn
}

resource "aws_cloudwatch_log_subscription_filter" "web_error_to_firehose" {
  name            = "${var.project_name}-web-error-to-firehose"
  log_group_name  = aws_cloudwatch_log_group.web_error.name
  filter_pattern  = ""
  destination_arn = aws_kinesis_firehose_delivery_stream.logs.arn
  role_arn        = aws_iam_role.cwl_to_firehose.arn
}
