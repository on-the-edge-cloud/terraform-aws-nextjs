variable "name" {
  description = "Optional fully composed resource name. When empty, resource_prefix without its trailing hyphen is used."
  type        = string
  default     = ""
}

variable "environment" {
  type    = string
  default = "production"
}

variable "resource_prefix" {
  type    = string
  default = ""

  validation {
    condition     = var.resource_prefix == "" || endswith(var.resource_prefix, "-")
    error_message = "resource_prefix must end with a hyphen."
  }
}

variable "app_directory" {
  description = "Absolute path to the application checkout; it must contain .open-next/."
  type        = string
  default     = "."
}

variable "build_path" {
  description = "Optional absolute path to OpenNext output; defaults to app_directory/.open-next."
  type        = string
  default     = ""
}

variable "deploy_artifacts" {
  type    = bool
  default = true
}

variable "force_destroy" {
  type    = bool
  default = false
}
