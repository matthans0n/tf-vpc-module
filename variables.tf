variable "name" {
  description = "Name of the VPC"
}

variable "environment" {
  description = "Name of the environment"
}

variable "project" {
  description = "Name of the project"
}

variable "cidr" {
  description = "The CIDR block for the VPC"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(any)
}

variable "public_subnets" {
  description = "List of public subnets in availability zones"
  type        = list(any)
}

variable "private_subnets" {
  description = "List of private subnets in availability zones"
  type        = list(any)
}

variable "enable_dns_hostnames" {
  description = "Do you want instances in the VPC to have DNS hostname"
  default     = true
}

variable "enable_dns_support" {
  description = "Do you want amazon DNS server enabled within the VPC"
  default     = true
}
