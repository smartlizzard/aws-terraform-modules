output "app_name" {
  description = "Project name"
  value       = join("", aws_codedeploy_app.default.*.name)
}

output "group_id" {
  description = "Group name"
  value       = join("", aws_codedeploy_deployment_group.default.*.deployment_group_name)
}

output "app_id" {
  description = "Project ID"
  value       = join("", aws_codedeploy_app.default.*.id)
}

output "code_deploy_iam_role_arn" {
  description = "IAM Role ARN"
  value       = join("", aws_iam_role.role.*.arn)
}
