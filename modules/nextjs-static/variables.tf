variable "domain" {
  description = "Optional custom domain for CloudFront. ACM certificate and Cloudflare DNS validation are managed automatically."
  type        = string
  default     = null
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