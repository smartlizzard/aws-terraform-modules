data "aws_caller_identity" "default" {
}

data "aws_region" "default" {
}

module "label" {
  source     = "../terraform-label"
  enabled    = var.enabled
  namespace  = var.namespace
  name       = var.name
  stage      = var.stage
  delimiter  = var.delimiter
  attributes = var.attributes
  tags       = var.tags
}

locals{
  code_build_artifacts_bucket = var.exiting_codepipeline_bucket == null ? join("", aws_s3_bucket.default.*.bucket) : var.exiting_codepipeline_bucket
}

resource "aws_s3_bucket" "default" {
  count         = var.enabled && var.exiting_codepipeline_bucket == null ? 1 : 0
  bucket        = module.label.id
  acl           = "private"
  force_destroy = var.force_destroy
  tags          = module.label.tags
}

resource "aws_iam_role" "default" {
  count              = var.enabled ? 1 : 0
  name               = module.label.id
  assume_role_policy = join("", data.aws_iam_policy_document.assume.*.json)
}

data "aws_iam_policy_document" "assume" {
  count = var.enabled ? 1 : 0

  statement {
    sid = ""

    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com", "cloudformation.amazonaws.com"]
    }

    effect = "Allow"
  }

  statement {
    sid = ""

    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.default.account_id}:root"]
    }

  }
}

resource "aws_iam_role_policy_attachment" "default" {
  count      = var.enabled ? 1 : 0
  role       = join("", aws_iam_role.default.*.id)
  policy_arn = join("", aws_iam_policy.default.*.arn)
}

resource "aws_iam_policy" "default" {
  count  = var.enabled ? 1 : 0
  name   = module.label.id
  policy = join("", data.aws_iam_policy_document.default.*.json)
}

data "aws_iam_policy_document" "default" {
  count = var.enabled ? 1 : 0

  statement {
    sid = ""

    actions = [
      "elasticbeanstalk:*",
      "ec2:*",
      "elasticloadbalancing:*",
      "autoscaling:*",
      "cloudwatch:*",
      "s3:*",
      "sns:*",
      "cloudformation:*",
      "rds:*",
      "sqs:*",
      "ecs:*",
      "iam:PassRole",
      "iam:CreateRole",
      "lambda:*",
      "logs:PutRetentionPolicy",
      "codedeploy:*",
      "sts:*"
    ]

    resources = ["*"]
    effect    = "Allow"
  }
}

resource "aws_iam_role_policy_attachment" "s3" {
  count      = var.enabled ? 1 : 0
  role       = join("", aws_iam_role.default.*.id)
  policy_arn = join("", aws_iam_policy.s3.*.arn)
}

resource "aws_iam_policy" "s3" {
  count  = var.enabled ? 1 : 0
  name   = "${module.label.id}-s3"
  policy = join("", data.aws_iam_policy_document.s3.*.json)
}

data "aws_iam_policy_document" "s3" {
  count = var.enabled ? 1 : 0

  statement {
    sid = ""

    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObject",
    ]

    resources = [
      "arn:aws:s3:::${local.code_build_artifacts_bucket}",
      "arn:aws:s3:::${local.code_build_artifacts_bucket}/*",
    ]

    effect = "Allow"
  }
}

resource "aws_iam_role_policy_attachment" "codebuild" {
  count      = var.enabled ? 1 : 0
  role       = join("", aws_iam_role.default.*.id)
  policy_arn = join("", aws_iam_policy.codebuild.*.arn)
}

resource "aws_iam_policy" "codebuild" {
  count  = var.enabled ? 1 : 0
  name   = "${module.label.id}-codebuild"
  policy = join("", data.aws_iam_policy_document.codebuild.*.json)
}

data "aws_iam_policy_document" "codebuild" {
  count = var.enabled ? 1 : 0

  statement {
    sid = ""

    actions = [
      "codebuild:*"
    ]

    resources = [module.codebuild.project_id]
    effect    = "Allow"
  }
}
######

resource "aws_iam_role_policy" "cloudformation_action_policy" {
  count  = var.deploy_cloudformation ? 1 : 0
  name   = "${module.label.id}-cf-iam-policy"
  role   = join("", aws_iam_role.code_pipeline_cf.*.id)

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "iam:*"
      ],
      "Resource": ["*"],
      "Effect": "Allow"
    }
  ]
}
EOF
}
resource "aws_iam_role" "code_pipeline_cf" {
  count              = var.deploy_cloudformation ? 1 : 0
  name               = "${module.label.id}-cf-role"
  assume_role_policy = join("", data.aws_iam_policy_document.assume.*.json)
}

resource "aws_iam_policy" "cf_policy" {
  count  = var.deploy_cloudformation ? 1 : 0
  name   = "${module.label.id}-cf-policy"
  policy = join("", data.aws_iam_policy_document.default.*.json)
}

resource "aws_iam_role_policy_attachment" "cf_policy_attachment" {
  count      = var.deploy_cloudformation ? 1 : 0
  role       = join("", aws_iam_role.code_pipeline_cf.*.id)
  policy_arn = join("", aws_iam_policy.cf_policy.*.arn)
}

####
module "codebuild" {
  source                      = "../codebuild"
  enabled                     = var.enabled
  namespace                   = var.namespace
  name                        = var.name
  stage                       = var.stage
  build_image                 = var.build_image
  build_compute_type          = var.build_compute_type
  buildspec                   = var.buildspec
  delimiter                   = var.delimiter
  attributes                  = concat(var.attributes, ["build"])
  tags                        = var.tags
  privileged_mode             = var.privileged_mode
  aws_region                  = var.region != "" ? var.region : data.aws_region.default.name
  aws_account_id              = var.aws_account_id != "" ? var.aws_account_id : data.aws_caller_identity.default.account_id
  image_repo_name             = var.image_repo_name
  image_tag                   = var.image_tag
  github_token                = var.github_oauth_token
  environment_variables       = var.environment_variables
  cache_bucket_suffix_enabled = var.codebuild_cache_bucket_suffix_enabled
}

resource "aws_iam_role_policy_attachment" "codebuild_s3" {
  count      = var.enabled ? 1 : 0
  role       = module.codebuild.role_id
  policy_arn = join("", aws_iam_policy.s3.*.arn)
}

resource "aws_codepipeline" "default" {
  count    = var.enabled ? 1 : 0
  name     = module.label.id
  role_arn = join("", aws_iam_role.default.*.arn)

  artifact_store {
    location = local.code_build_artifacts_bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["code"]

      configuration = {
        OAuthToken           = var.github_oauth_token
        Owner                = var.repo_owner
        Repo                 = var.repo_name
        Branch               = var.branch
        PollForSourceChanges = var.poll_source_changes
      }
    }
  }

  stage {
    name = "Build"

    action {
      name     = "Build"
      category = "Build"
      owner    = "AWS"
      provider = "CodeBuild"
      version  = "1"

      input_artifacts  = ["code"]
      output_artifacts = ["package"]

      configuration = {
        ProjectName = module.codebuild.project_name
      }
    }
  }

  dynamic "stage" {
    for_each = var.elastic_beanstalk_application_name != "" && var.elastic_beanstalk_environment_name != "" ? ["true"] : []
    content {
      name = "Deploy"

      action {
        name            = "Deploy"
        category        = "Deploy"
        owner           = "AWS"
        provider        = "ElasticBeanstalk"
        input_artifacts = ["package"]
        version         = "1"

        configuration = {
          ApplicationName = var.elastic_beanstalk_application_name
          EnvironmentName = var.elastic_beanstalk_environment_name
        }
      }
    }
  }

  dynamic "stage" {
    for_each = var.code_deploy_app_name != "" && var.code_deployment_group_id != "" ? ["true"] : []
    content {
      name = "Deploy"

      action {
        name            = "Deploy"
        category        = "Deploy"
        owner           = var.code_deploy_owner
        provider        = var.code_deploy_provider
        input_artifacts = ["package"]
        version         = "1"

        configuration = {
          ApplicationName     = var.code_deploy_app_name
          DeploymentGroupName = var.code_deployment_group_id
        }
      }
    }
  }

  dynamic "stage" {
    for_each = var.deploy_cloudformation ? ["true"] : []
    content {
      name = "Deploy"

      action {
        name            = "CreateChangeSet"
        category        = "Deploy"
        owner           = "AWS"
        provider        = "CloudFormation"
        input_artifacts = ["package"]
        version         = "1"
        #role_arn        = join("", aws_iam_role.code_pipeline_cf.*.arn)

        configuration = {
          ActionMode    = var.cf_action_mode
          StackName     = var.cf_stack_name
          ChangeSetName = "${var.cf_stack_name}-change"
          Capabilities  = var.cf_capabilities
          TemplatePath  = "package::${var.cf_tamplate}"
          RoleArn       = join("", aws_iam_role.code_pipeline_cf.*.arn)
        }
      }
    }
  }
}
