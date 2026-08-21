resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "validate" {
  filename         = data.archive_file.validate.output_path
  function_name    = "validateData"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "validate.lambda_handler"
  runtime          = "python3.10"
  source_code_hash = data.archive_file.validate.output_base64sha256
}

resource "aws_lambda_function" "log_metrics" {
  filename         = data.archive_file.log_metrics.output_path
  function_name    = "logMetrics"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "log_metrics.lambda_handler"
  runtime          = "python3.10"
  source_code_hash = data.archive_file.log_metrics.output_base64sha256
}

resource "aws_iam_role" "stepfunction_exec" {
  name               = "stepfunction_exec_role"
  assume_role_policy = data.aws_iam_policy_document.stepfunction_trust.json
}

resource "aws_iam_role_policy" "stepfunction_invoke" {
  name = "stepfunction_invoke_lambda"
  role = aws_iam_role.stepfunction_exec.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "lambda:InvokeFunction",
        Resource = [
          aws_lambda_function.validate.arn,
          aws_lambda_function.log_metrics.arn
        ]
      }
    ]
  })
}

resource "aws_sfn_state_machine" "mlops_pipeline" {
  name     = "MLOpsPipeline"
  role_arn = aws_iam_role.stepfunction_exec.arn

  definition = jsonencode({
    Comment = "MLOps Training Pipeline: Validate -> Log Metrics"
    StartAt = "ValidateData",
    States = {
      ValidateData = {
        Type     = "Task",
        Resource = aws_lambda_function.validate.arn,
        Next     = "LogMetrics"
      },
      LogMetrics = {
        Type     = "Task",
        Resource = aws_lambda_function.log_metrics.arn,
        End      = true
      }
    }
  })
}
