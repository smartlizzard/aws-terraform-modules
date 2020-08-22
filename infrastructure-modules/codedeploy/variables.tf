variable "namespace" {
  type        = string
  default     = ""
  description = "Namespace, which could be your organization name, e.g. 'eg' or 'cp'"
}

variable "stage" {
  type        = string
  default     = ""
  description = "Stage, e.g. 'prod', 'staging', 'dev', or 'test'"
}

variable "name" {
  type        = string
  description = "Solution name, e.g. 'app' or 'jenkins'"
}

variable "delimiter" {
  type        = string
  default     = "-"
  description = "Delimiter to be used between `name`, `namespace`, `stage`, etc."
}

variable "attributes" {
  type        = list(string)
  default     = []
  description = "Additional attributes (e.g. `policy` or `role`)"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags (e.g. `map('BusinessUnit', 'XYZ')`"
}

variable "compute_platform" {
  type        = string
  default     = ""
  description = "The type of compute platform type.The compute platform can either be ECS, Lambda, or Server. Default is Server."
}

variable "ec2_tag_filter" {
  description = "Filter key and value you want to use for tags filters. Defined as key/value format, example: `{\"Environment\":\"staging\"}`"
  type        = map(string)
  default     = null
}

variable "ec2_tag_type" {
  type        = string
  default     = ""
  description = "The type of EC2 filter."
}

variable "deployment_config_name" {
  type        = string
  default     = ""
  description = "The Deployment config name."
}

variable "use_existing_aws_iam_code_deploy_role" {
  type        = bool
  default     = false
  description = "(Optional) If set to true, use existing IAM code deploy role"
}

variable "enabled" {
  type        = bool
  default     = true
  description = "Whether to create the resources. Set to `false` to prevent the module from creating any resources"
}

variable "existing_aws_iam_code_deploy_role_arn" {
  type        = string
  default     = ""
  description = "Provide existing IAM code deploy role arn"
}

variable "alb_target_group" {
  type        = string
  default     = null
  description = "whether to route deployment traffic behind a load balancer. Valid Values are WITH_TRAFFIC_CONTROL or WITHOUT_TRAFFIC_CONTROL"
}

variable "enable_bluegreen" {
  type        = bool
  default     = false
  description = "Provide deploy steatergy. Either IN_PLACE or BLUE_GREEN"
}

variable "blue_green_action_on_timeout" {
  type        = string
  default     = ""
  description = "When to reroute traffic from an original environment to a replacement environment in a blue/green deployment"
}

variable "blue_green_wait_time_in_minutes" {
  type        = number
  default     = null
  description = "The number of minutes to wait before the status of a blue/green deployment changed to Stopped if rerouting is not started manually. Applies only to the STOP_DEPLOYMENT option for action_on_timeout."
}

variable "rollback_enabled" {
  type        = bool
  default     = false
  description = "Whether to enable auto rollback"
}

variable "rollback_events" {
  description = "The event types that trigger a rollback"
  type        = list(string)
  default     = ["DEPLOYMENT_FAILURE"]
}

variable "autoscaling_groups" {
  type        = list(string)
  default     = []
  description = "Autoscaling groups associated with the deployment group."
}

variable "blue_instances_action" {
  type        = string
  default     = "KEEP_ALIVE"
  description = "The action to take on instances in the original environment after a successful blue/green deployment. Valid values are TERMINATE & KEEP_ALIVE"
}

variable "terminate_blue_instances_time_in_minutes" {
  type        = number
  default     = null
  description = "The number of minutes to wait after a successful blue/green deployment before terminating instances from the original environment."
}

variable "trigger_target_arn" {
  description = "The ARN of the SNS topic through which notifications are sent"
  type        = string
  default     = null
}

variable "trigger_events" {
  description = "events that can trigger the notifications"
  type        = list(string)
  default     = ["DeploymentStop", "DeploymentRollback", "DeploymentSuccess", "DeploymentFailure", "DeploymentStart"]
}

variable "enable_alarm" {
  type        = bool
  default     = false
  description = "Whether to enable auto rollback"
}

variable "alarm" {
  description = "A list of alarms configured for the deployment group."
  type        = list(string)
  default     = []
}
