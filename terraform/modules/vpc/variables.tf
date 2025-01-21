variable "environment" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

data "aws_availability_zones" "available" {
  state = "available"
}