variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance size"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "Name of existing AWS EC2 Key Pair to SSH into instance"
  type        = string
  default     = "devops-key"
}