variable "location" {
  description = "The location (region) for the resources."
  type        = string
  default     = "westeurope"
}

variable "environment" {
  description = "The environment for the resources."
  type        = string
  default     = "dev"
}
