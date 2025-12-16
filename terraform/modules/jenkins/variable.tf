variable "vpc_id" {
  description = "VPC ID where Jenkins will be deployed"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for Jenkins EC2 instance"
  type        = string
}

variable "key_name" {
  description = "Name of the SSH key pair (created manually in AWS Console)"
  type        = string
  default     = "jenkins"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}
