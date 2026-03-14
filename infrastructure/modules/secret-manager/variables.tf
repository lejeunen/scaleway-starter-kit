variable "secret_name" {
  description = "Name of the secret in Scaleway Secret Manager."
  type        = string
}

variable "description" {
  description = "Description of the secret."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to associate with the secret."
  type        = list(string)
  default     = []
}
