variable "vpc_cidr_block" {
  description = "cidr_block for my vpc"
  type        = string
}

variable "my_public_subnets" {
  description = "my public subnets"
  type        = list(string)
}

variable "instances" {
  description = "my instances"
  type        = string
}