# Lambda to start Step Function with job ID as execution name
data "archive_file" "start_step_func_files" {
  type        = "zip"
  source_file = "${path.module}/lambda/start_step/main.py"
  output_path = "${path.module}/lambda/start_step/start_step_func.zip"
}

resource "aws_lambda_function" "start_step_function" {
  filename         = data.archive_file.start_step_func_files.output_path
  function_name    = "start-step-function-with-job-id"
  role             = aws_iam_role.start_step_function_role.arn
  handler          = "main.lambda_handler"
  source_code_hash = data.archive_file.start_step_func_files.output_base64sha256
  runtime          = "python3.12"

  environment {
    variables = {
      STATE_MACHINE_ARN     = aws_sfn_state_machine.process_upload.arn
      REKOGNITION_MODEL_ARN = var.rekognition_model_arn
    }
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "start_step_function_role" {
  name = "start-step-function-lambda-role"

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

# Custom policy for Step Functions
resource "aws_iam_role_policy" "start_step_function_policy" {
  name = "start-step-function-policy"
  role = aws_iam_role.start_step_function_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "states:StartExecution"
        ]
        Resource = aws_sfn_state_machine.process_upload.arn
      }
    ]
  })
}
