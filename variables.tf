variable "domain" {
  description = "Optional custom domain for CloudFront, covered by acm_certificate_arn."
  type        = string
  default     = null
}

variable "acm_certificate_arn" {
  description = "ARN of an issued ACM certificate in us-east-1 covering domain. Required when domain is set."
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