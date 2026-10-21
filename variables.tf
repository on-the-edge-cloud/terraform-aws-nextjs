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
}

variable "app_directory" {
  type = string
}

variable "deploy_artifacts" {
  type    = bool
  default = true
}

variable "force_destroy" {
  type    = bool
  default = false
}