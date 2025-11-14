# Existing archive
data "archive_file" "process_upload_func_files" {
  type        = "zip"
  source_file = "${path.module}/lambda/process_upload/main.py"
  output_path = "${path.module}/lambda/process_upload/process_upload.zip"
}

# IAM role for Lambda
resource "aws_iam_role" "process_upload_lambda_role" {
  name = "process-upload-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for S3 and CloudWatch
resource "aws_iam_role_policy" "process_upload_lambda_policy" {
  name = "process-upload-lambda-policy"
  role = aws_iam_role.process_upload_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:HeadObject"
        ]
        Resource = "${aws_s3_bucket.upload_bucket.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Lambda function
resource "aws_lambda_function" "process_upload_func" {
  filename         = data.archive_file.process_upload_func_files.output_path
  function_name    = "process-upload-function"
  role             = aws_iam_role.process_upload_lambda_role.arn
  handler          = "main.lambda_handler"
  source_code_hash = data.archive_file.process_upload_func_files.output_base64sha256
  runtime          = "python3.12"
  timeout          = 30
  memory_size      = 256
}
