# EventBridge Target (Lambda instead of Step Functions)
resource "aws_cloudwatch_event_target" "lambda_trigger" {
  rule = aws_cloudwatch_event_rule.s3_upload.name
  arn  = aws_lambda_function.start_step_function.arn
}

# Permission for EventBridge to invoke Lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.start_step_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.s3_upload.arn
}

# Keep your existing S3 notification and EventBridge rule
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket      = aws_s3_bucket.upload_bucket.id
  eventbridge = true
}

resource "aws_cloudwatch_event_rule" "s3_upload" {
  name        = "s3-upload-trigger-step-functions"
  description = "Trigger Step Functions when video uploaded to S3"

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      reason = ["PutObject"]
      bucket = {
        name = [aws_s3_bucket.upload_bucket.id]
      }
      object = {
        key = [{
          "anything-but" : {
            "prefix" : "output/"
          }
          }, {
          "anything-but" : {
            "prefix" : "music/"
          }
        }]
      }
    }
  })
}
