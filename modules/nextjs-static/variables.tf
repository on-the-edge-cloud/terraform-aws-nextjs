variable "domain" {
  description = "Optional custom domain for CloudFront, covered by acm_certificate_arn."
  type        = string
  default     = null
}

variable "acm_certificate_arn" {
  description = "ARN of an issued ACM certificate in us-east-1 covering domain. Required when domain is set."
  type        = string
  default     = null

  validation {
    condition     = var.acm_certificate_arn == null ? true : can(regex("^arn:[^:]+:acm:us-east-1:[0-9]{12}:certificate/.+$", var.acm_certificate_arn))
    error_message = "acm_certificate_arn must be an ACM certificate ARN in us-east-1."
  }
}

variable "environment" {
  type = string
}

variable "resource_prefix" {
  type = string

  validation {
    condition     = length(var.resource_prefix) > 1 && endswith(var.resource_prefix, "-")
    error_message = "resource_prefix must be a non-empty resource name prefix ending in a hyphen."
  }
}

variable "app_directory" {
  description = "Absolute path to the application checkout containing the out/ directory."
  type        = string
}

variable "deploy_artifacts" {
  description = "Whether to upload generated static assets. Set false for destroy without a local build."
  type        = bool
  default     = true
}

variable "force_destroy" {
  description = "Whether Terraform may delete all object versions when destroying this bucket."
  type        = bool
  default     = false
}