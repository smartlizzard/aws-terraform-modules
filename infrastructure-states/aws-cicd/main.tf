provider "aws" {
  region  = var.aws_region
  version = "~> 2.0"
}

data "aws_caller_identity" "current" {}

module "api_deploy" {
  source              = "../../infrastructure-modules/codedeploy"
  namespace           = "eskool"
  stage               = "dev"
  name                = "api"

  compute_platform    = "Server"
  autoscaling_groups  = ["code-deploy"]

  deployment_config_name = "CodeDeployDefault.OneAtATime"
  use_existing_aws_iam_code_deploy_role = false

  enable_bluegreen        = true
  blue_instances_action   = "TERMINATE"
  terminate_blue_instances_time_in_minutes = 5
  blue_green_action_on_timeout = "CONTINUE_DEPLOYMENT"
}

module "api_cicd" {
  source                                = "../../infrastructure-modules/aws-cicd"
  namespace                             = "eskool"
  stage                                 = "dev"
  name                                  = "api"
  region                                = var.aws_region
  github_oauth_token                    = var.github_oauth_token
  build_image                           = "aws/codebuild/standard:4.0"
  build_compute_type                    = "BUILD_GENERAL1_SMALL"
  repo_owner                            = var.repo_owner
  repo_name                             = "eskool-api"
  branch                                = "codepipeline"
  poll_source_changes                   = var.poll_source_changes
  buildspec                             = "buildspec.yml"
  environment_variables                 = var.environment_variables
  codebuild_cache_bucket_suffix_enabled = var.codebuild_cache_bucket_suffix_enabled
  force_destroy                         = var.force_destroy
  exiting_codepipeline_bucket           = var.exiting_codepipeline_bucket

  code_deploy_app_name                  = module.api_deploy.app_name
  code_deployment_group_id              = module.api_deploy.group_id
  code_deploy_owner                     = "AWS"
  code_deploy_provider                  = "CodeDeploy"
}

module "admin_deploy" {
  source              = "../../infrastructure-modules/codedeploy"
  namespace           = "eskool"
  stage               = "dev"
  name                = "admin"

  compute_platform    = "Server"
  autoscaling_groups  = ["code-deploy"]

  deployment_config_name = "CodeDeployDefault.OneAtATime"
  use_existing_aws_iam_code_deploy_role = true
  existing_aws_iam_code_deploy_role_arn = module.api_deploy.code_deploy_iam_role_arn

  enable_bluegreen        = true
  blue_instances_action   = "TERMINATE"
  terminate_blue_instances_time_in_minutes = 5
  blue_green_action_on_timeout = "CONTINUE_DEPLOYMENT"
}

module "admin_cicd" {
  source                                = "../../infrastructure-modules/aws-cicd"
  namespace                             = "eskool"
  stage                                 = "dev"
  name                                  = "admin"
  region                                = var.aws_region
  github_oauth_token                    = var.github_oauth_token
  build_image                           = "aws/codebuild/standard:4.0"
  build_compute_type                    = "BUILD_GENERAL1_SMALL"
  repo_owner                            = var.repo_owner
  repo_name                             = "eskool-admin"
  branch                                = "docker"
  poll_source_changes                   = var.poll_source_changes
  buildspec                             = "buildspec.yml"
  environment_variables                 = var.environment_variables
  codebuild_cache_bucket_suffix_enabled = var.codebuild_cache_bucket_suffix_enabled
  force_destroy                         = var.force_destroy
  exiting_codepipeline_bucket           = var.exiting_codepipeline_bucket

  code_deploy_app_name                  = module.admin_deploy.app_name
  code_deployment_group_id              = module.admin_deploy.group_id
  code_deploy_owner                     = "AWS"
  code_deploy_provider                  = "CodeDeploy"
}

module "dataprocess_lambda_cicd" {
  source                                = "../../infrastructure-modules/aws-cicd"
  namespace                             = "eskool"
  stage                                 = "dev"
  name                                  = "dataprocess"
  region                                = var.aws_region
  github_oauth_token                    = var.github_oauth_token
  build_image                           = "aws/codebuild/standard:4.0"
  build_compute_type                    = "BUILD_GENERAL1_SMALL"
  repo_owner                            = var.repo_owner
  repo_name                             = "eskool-lambda"
  branch                                = "dev"
  poll_source_changes                   = var.poll_source_changes
  buildspec                             = "buildspec.yml"
  environment_variables                 = var.environment_variables
  codebuild_cache_bucket_suffix_enabled = var.codebuild_cache_bucket_suffix_enabled
  force_destroy                         = var.force_destroy
  exiting_codepipeline_bucket           = var.exiting_codepipeline_bucket

  deploy_cloudformation                 = true
  cf_action_mode                        = "CREATE_UPDATE"
  cf_capabilities                       = "CAPABILITY_AUTO_EXPAND,CAPABILITY_IAM"
  cf_stack_name                         = "dataprocess"
  cf_tamplate                           = "outputSamTemplate.yaml"
}