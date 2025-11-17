data "archive_file" "polling_func_files" {
  type        = "zip"
  source_file = "${path.module}/lambda/polling/main.py"
  output_path = "${path.module}/lambda/polling/polling_func.zip"
}

resource "aws_lambda_function" "polling_func" {
  filename         = data.archive_file.polling_func_files.output_path
  function_name    = "poll-job-status"
  role             = aws_iam_role.poll_job_status_role.arn
  handler          = "main.lambda_handler"
  source_code_hash = data.archive_file.polling_func_files.output_base64sha256
  runtime          = "python3.12"

  environment {
    variables = {
      STATE_MACHINE_ARN = aws_sfn_state_machine.process_upload.arn
    }
  }
}

resource "aws_iam_role" "poll_job_status_role" {
  name = "poll-job-status-lambda-role"

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

resource "aws_iam_role_policy_attachment" "poll_lambda_basic" {
  role       = aws_iam_role.poll_job_status_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "poll_step_functions_policy" {
  name = "poll-step-functions-policy"
  role = aws_iam_role.poll_job_status_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "states:DescribeExecution"
        ]
        Resource = "${replace(aws_sfn_state_machine.process_upload.arn, ":stateMachine:", ":execution:")}:*"
      }
    ]
  })
}
