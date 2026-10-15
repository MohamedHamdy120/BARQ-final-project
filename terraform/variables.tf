variable "region" {
  type    = string
  default = "eu-north-1"
}

variable "project_name" {
  type    = string
  default = "barq"
}

variable "environment" {
  type    = string
  default = "dev"
}
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
}
variable "db_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.11.0/24", "10.0.12.0/24"]
}
variable "allowed_ssh_cidrs" {
  type        = list(string)
  description = "CIDRs allowed to SSH, e.g. [\"203.0.113.10/32\"]"

  validation {
    condition     = !contains(var.allowed_ssh_cidrs, "0.0.0.0/0")
    error_message = "SSH must not be open to the world."
  }
}

variable "node_port" {
  type    = number
  default = 30080
}

variable "app_access_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}