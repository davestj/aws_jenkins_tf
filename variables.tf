# variables.tf

variable "ami_id" {
  description = "The ID of the AMI to use for the EC2 instance"
}

variable "vpc_id" {
  description = "ID of the VPC"
}

variable "subnet_ids" {
  description = "List of subnet IDs for load balancer"
  type        = list(string)
}

variable "domain_name" {
  description = "Domain name for ACM certificate"
}

variable "ssh_private_key_path" {
  description = "Path to the SSH private key file"
}

variable "ssh_key_name" {
  description = "Name of the SSH key pair"
}

