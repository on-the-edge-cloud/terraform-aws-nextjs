variable "app_slug" {
  description = "Short lowercase application identifier used in AWS resource names."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]+(-[a-z0-9]+)*$", var.app_slug)) && length(var.app_slug) <= 24
    error_message = "app_slug must be lowercase, use single hyphens, and be at most 24 characters."
  }
}

variable "app_directory" {
  description = "Absolute path to the application checkout."
  type        = string
}

variable "deployment_type" {
  description = "Deployment mode: ssr or static."
  type        = string

  validation {
    condition     = contains(["ssr", "static"], var.deployment_type)
    error_message = "deployment_type must be either ssr or static."
  }
}

variable "pr_number" {
  description = "Pull request number; leave empty for production."
  type        = string
  default     = ""

  validation {
    condition     = var.pr_number == "" || can(regex("^[1-9][0-9]*$", var.pr_number))
    error_message = "pr_number must be empty or a positive integer."
  }
}

variable "deploy_artifacts" {
  description = "Whether to upload build artifacts. Set false when destroying without a local build."
  type        = bool
  default     = true
}