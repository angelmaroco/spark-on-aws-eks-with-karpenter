terraform {
  backend "s3" {
    key            = "infrastructure/spark-on-aws-eks.tfstate"
    region         = "eu-west-1"
    encrypt        = true
  }
}
