variable "aws_region" {
  description = "AWS region for the EKS cluster and networking."
  type        = string
  default     = "ap-south-1"
}

variable "cluster_name" {
  description = "Name used for the EKS cluster and VPC."
  type        = string
  default     = "mindcircuit-eks"
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS control plane."
  type        = string
  default     = "1.34"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones for the VPC; at least two are required."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "az_count must be 2 or 3."
  }
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDRs allowed to reach the public EKS Kubernetes API endpoint. Use your trusted public IP as a /32."
  type        = list(string)
}

variable "node_instance_type" {
  description = "EC2 instance type used by the EKS managed node group."
  type        = string
  default     = "t3.medium"
}

variable "environment" {
  description = "Environment label applied to EKS resources."
  type        = string
  default     = "dev"
}
