output "lambda_validate_arn" {
  description = "ARN of the validate lambda"
  value       = aws_lambda_function.validate.arn
}

output "lambda_log_metrics_arn" {
  description = "ARN of the log metrics lambda"
  value       = aws_lambda_function.log_metrics.arn
}

output "stepfunction_arn" {
  description = "ARN of the Step Functions state machine"
  value       = aws_sfn_state_machine.mlops_pipeline.arn
}

