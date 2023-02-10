variable "location" {
  type        = string
  description = "The location for the resources."
  default     = "westeurope"
}

variable "environment" {
  type        = string
  description = "The environment for the resources."
  default     = "dev"
}
