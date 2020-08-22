data "aws_region" "default" {
}

module "label" {
    source     = "../terraform-label"
    namespace  = var.namespace
    name       = var.name
    stage      = var.stage
    delimiter  = var.delimiter
    attributes = var.attributes
    tags       = var.tags
}

######################## CODE DEPLOY #############################

data "aws_iam_policy_document" "assume_role_policy" {
    count = var.enabled && var.use_existing_aws_iam_code_deploy_role == false ? 1 : 0

    statement {
        effect  = "Allow"
        actions = ["sts:AssumeRole"]

        principals {
            type        = "Service"
            identifiers = ["codedeploy.amazonaws.com"]
        }
    }
}

resource "aws_iam_role" "role" {
    count              = var.enabled && var.use_existing_aws_iam_code_deploy_role == false ? 1 : 0
    name               = "AWSCodeDeployRole"
    assume_role_policy = join("", data.aws_iam_policy_document.assume_role_policy.*.json)
}

resource "aws_iam_role_policy_attachment" "code_deploy_policy_attachment" {
    count      = var.enabled && var.use_existing_aws_iam_code_deploy_role == false ? 1 : 0
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
    role       = join("", aws_iam_role.role.*.name)
}

resource "aws_codedeploy_app" "default" {
    compute_platform = var.compute_platform
    name             = module.label.id
}
/*
resource "aws_codedeploy_deployment_config" "default" {
  deployment_config_name = module.label.id

  minimum_healthy_hosts {
    type  = "HOST_COUNT"
    value = 2
  }
}
*/
resource "aws_codedeploy_deployment_group" "default" {
    app_name               = aws_codedeploy_app.default.name
    deployment_group_name  = module.label.id
    service_role_arn       = var.use_existing_aws_iam_code_deploy_role == false ? join("", aws_iam_role.role.*.arn) : var.existing_aws_iam_code_deploy_role_arn
    deployment_config_name = var.deployment_config_name
    autoscaling_groups     = var.autoscaling_groups
  
    dynamic "ec2_tag_filter" {
        for_each = var.ec2_tag_filter == null ? {} : var.ec2_tag_filter
        content {
            key   = ec2_tag_filter.key
            type  = var.ec2_tag_type
            value = ec2_tag_filter.value
        }
    }

    deployment_style {
        deployment_option = var.alb_target_group == null ? "WITHOUT_TRAFFIC_CONTROL" : "WITH_TRAFFIC_CONTROL"
        deployment_type   = var.enable_bluegreen == false || var.alb_target_group == null ? "IN_PLACE" : "BLUE_GREEN"
    }

    dynamic "blue_green_deployment_config" {
        for_each = var.enable_bluegreen == true ? [1] : []
        content {
            deployment_ready_option {
                action_on_timeout    = var.blue_green_action_on_timeout
                wait_time_in_minutes = var.blue_green_wait_time_in_minutes
            }

            green_fleet_provisioning_option {
                action = "DISCOVER_EXISTING"
            }

            terminate_blue_instances_on_deployment_success {
                action = var.blue_instances_action  #"KEEP_ALIVE"
                termination_wait_time_in_minutes = var.terminate_blue_instances_time_in_minutes
            }
        }
    }

    auto_rollback_configuration {
        enabled = var.rollback_enabled
        events  = var.rollback_events
    }

    dynamic "load_balancer_info" {
        for_each = var.alb_target_group == null ? [] : [var.alb_target_group]
        content {
            target_group_info {
                name = var.alb_target_group
            }
        }
    }
    
    dynamic "trigger_configuration" {
        for_each = var.trigger_target_arn == null ? [] : [var.trigger_target_arn]
        content {
            trigger_events     = var.trigger_events
            trigger_name       = module.label.id
            trigger_target_arn = var.trigger_target_arn
        }
    }

    dynamic "alarm_configuration" {
        for_each = var.enable_alarm == true ? [1] : []
        content {
            alarms  = var.alarm
            enabled = var.enable_alarm
        }
    }
}
