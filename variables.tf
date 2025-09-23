variable "aws_region" {
  default = "ap-south-1"
}

variable "environment" {
  default = "Dev"
  type    = string
}

variable "vpc_cidr" {
  default     = "10.0.0.0/16"
  type        = string
  description = "Primary VPC CIDR block."
}

variable "public_subnet_cidr" {
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
  type        = list(string)
  description = "List of public subnet CIDRs (one per AZ)."
}

variable "private_subnet_cidr" {
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
  type        = list(string)
  description = "List of private subnet CIDRs (one per AZ)."
}
