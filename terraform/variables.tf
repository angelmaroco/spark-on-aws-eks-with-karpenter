variable "tags" {
  type = map(string)
}

variable "aws_baseline_vpc" {
  type = any
}

variable "aws_baseline_kms" {
  type = map(string)
}
variable "aws_baseline_s3_spark" {
  type = any
}

variable "aws_baseline_eks" {
  type = any
}
variable "aws_baseline_monitoring" {
  type = any
}

variable "aws_baseline_ecr" {
  type = map(string)
}

variable "aws_baseline_ecr_jupyter" {
  type = map(string)
}
