variable "registry_name" {
  description = "Name of the container registry namespace."
  type        = string
}

variable "description" {
  description = "Description of the registry namespace."
  type        = string
  default     = null
}

variable "is_public" {
  description = "Whether images are publicly downloadable."
  type        = bool
  default     = false
}

variable "region" {
  description = "Scaleway region."
  type        = string
  default     = null
}
