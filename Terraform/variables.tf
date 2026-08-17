variable "aws_region" {
  description = "The AWS region to deploy the EKS cluster into"
  type        = string
  default     = "us-west-2"
}

variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
  default     = "o11y-scale-cluster"
}