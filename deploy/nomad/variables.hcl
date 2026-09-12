variable "name" {
  type = string
}

variable "environment" {
  type = string
}

variable "health_path" {
  type = string
}

variable "image" {
  type = string
}

variable "port" {
  type = number
}

variable "service_tags" {
  type = list(string)
}
