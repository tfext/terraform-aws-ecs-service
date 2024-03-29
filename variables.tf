variable "name" {
  type        = string
  nullable    = false
  description = "Name of the ECS service"
}

variable "cluster" {
  type        = string
  nullable    = false
  description = "Name of the ECS cluster to create the service in"
}

variable "load_balancers" {
  type = list(object({
    name          = string
    short_name    = optional(string)
    dns_zone      = string
    dns_subdomain = string
    priority      = optional(number)
    vpc           = string
    ports         = optional(list(number))
  }))
  nullable    = false
  default     = []
  description = <<-DESC
  List of load balancers to attach the service to
  - name:           Name of AWS load balancer
  - short_name:     Short name to use for target group names (< 10 chars)
  - dns_zone:       Route53 zone name to register in
  - dns_subdomain:  Route53 subdomain to register as
  - priority:       Override default priority of generated listener rule
  - vpc:            Name of vpc
  - ports:          Optional port filter for this load balancer. Allows different container ports to be registered on different LBs (ie public vs. internal)
  DESC
}

variable "containers" {
  type = list(object({
    container_name = string
    definition     = any
    service_type   = string
    shared_data = optional(object({
      volume          = string
      efs_id          = string
      access_point_id = string
    }))
    ports = list(object({
      port        = number
      public_port = optional(number)
      health_check = optional(object({
        enabled      = optional(bool)
        path         = optional(string)
        status_codes = optional(string)
        threshold    = optional(number)
        interval     = optional(number)
        timeout      = optional(number)
      }))
    }))
  }))
  description = "List of container definitions generated by terraform-aws-ecs-container-defintion"
}

variable "role_arn" {
  type        = string
  default     = null
  description = "Existing role for service to run as"
}

variable "role_policy" {
  type        = string
  default     = null
  description = "IAM policy for service to run as"
}

variable "health_check" {
  type = object({
    port         = optional(number)
    path         = optional(string)
    status_codes = optional(string)
  })
  default = {}
}

variable "target_scaling" {
  type = object({
    target = number
    metric = string
  })
  default     = null
  description = "Service scaling options"
  validation {
    condition     = contains(["requests", "memory", "cpu"], try(var.target_scaling.metric, "requests"))
    error_message = "Invalid scaling metric. Expected requests, memory or cpu."
  }
}

variable "custom_scaling" {
  type        = bool
  default     = false
  description = "Use if you want to define custom scaling. Reference the scaling_target output."
}

variable "scaling_options" {
  type = object({
    min              = number
    max              = number
    scale_down_delay = number
    scale_up_delay   = number
  })
  default = { min = 1, max = 20, scale_down_delay = 500, scale_up_delay = 30 }
}

variable "singleton" {
  type    = bool
  default = false
  description = "Prevent service from being deployed more than once on any host"
}

variable "create_target_group" {
  default     = false
  description = "Force target group creation when no LB information provided"
}

variable "target_group_prefix" {
  type        = string
  default     = null
  description = "Override target group prefix for long names"
}

variable "wait_for_stable" {
  type    = bool
  default = true
}
