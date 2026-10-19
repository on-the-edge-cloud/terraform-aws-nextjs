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