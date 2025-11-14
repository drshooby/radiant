# Enable EventBridge notifications on S3 bucket (still needed)
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket      = aws_s3_bucket.upload_bucket.id
  eventbridge = true
}

# EventBridge module
module "eventbridge" {
  source  = "terraform-aws-modules/eventbridge/aws"
  version = "~> 3.0"

  create_bus = false # Use default event bus

  rules = {
    s3-upload = {
      description = "Trigger on S3 PutObject"
      event_pattern = jsonencode({
        source      = ["aws.s3"]
        detail-type = ["Object Created"]
        detail = {
          reason = ["PutObject"]
          bucket = {
            name = [aws_s3_bucket.upload_bucket.id]
          }
        }
      })
    }
  }

  targets = {
    s3-upload = [
      {
        name = "process-upload-lambda"
        arn  = aws_lambda_function.process_upload_func.arn
      }
    ]
  }
}

# Permission for EventBridge to invoke Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_upload_func.function_name
  principal     = "events.amazonaws.com"
  source_arn    = module.eventbridge.eventbridge_rule_arns["s3-upload"]
}
