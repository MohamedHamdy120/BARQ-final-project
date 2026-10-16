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
  validation {
    condition     = length(var.allowed_ssh_cidrs) > 0
    error_message = "Provide at least one SSH CIDR."
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

variable "instance_type" {
  type    = string
  default = "t3.medium"
}

variable "public_key_path" {
  type        = string
  description = "Path to the SSH public key, e.g. ~/.ssh/id_ed25519.pub"
}
variable "db_name" {
  type    = string
  default = "barq"
}

variable "db_username" {
  type    = string
  default = "barq_admin"
}

variable "db_password" {
  type      = string
  sensitive = true

  validation {
    condition     = length(var.db_password) >= 12
    error_message = "Use at least 12 characters."
  }
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}