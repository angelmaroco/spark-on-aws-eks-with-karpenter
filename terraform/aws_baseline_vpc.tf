module "aws_baseline_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  create_vpc                       = var.aws_baseline_vpc.create_vpc
  name                             = format("%s-%s", var.aws_baseline_vpc.vpc_name, var.tags.environment)
  cidr                             = var.aws_baseline_vpc.cidr
  azs                              = data.aws_availability_zones.available.names
  private_subnets                  = var.aws_baseline_vpc.private_subnets
  public_subnets                   = var.aws_baseline_vpc.public_subnets
  enable_nat_gateway               = var.aws_baseline_vpc.enable_nat_gateway
  single_nat_gateway               = var.aws_baseline_vpc.single_nat_gateway
  one_nat_gateway_per_az           = var.aws_baseline_vpc.one_nat_gateway_per_az
  default_vpc_enable_dns_hostnames = var.aws_baseline_vpc.default_vpc_enable_dns_hostnames
  default_vpc_enable_dns_support   = var.aws_baseline_vpc.default_vpc_enable_dns_support
  enable_dns_hostnames             = var.aws_baseline_vpc.enable_dns_hostnames
  enable_dns_support               = var.aws_baseline_vpc.enable_dns_support

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/elb"              = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.name}" = "shared"
    "kubernetes.io/role/internal-elb"     = "1"
  }

  tags = var.tags
}


module "endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "3.11.0"

  vpc_id             = module.aws_baseline_vpc.vpc_id
  security_group_ids = [aws_security_group.non_default.id]
  subnet_ids         = module.aws_baseline_vpc.private_subnets

  endpoints = {
    s3 = {
      service             = "s3"
      private_dns_enabled = false
      tags                = { Name = "${var.tags.project}-${var.tags.environment}-s3-vpc-endpoint" }
    },
    ecr_api = {
      service             = "ecr.api"
      private_dns_enabled = true
      subnet_ids          = module.aws_baseline_vpc.private_subnets
      tags                = { Name = "${var.tags.project}-${var.tags.environment}-ecr-api-vpc-endpoint" }
    },
    ecr_dkr = {
      service             = "ecr.dkr"
      private_dns_enabled = true
      subnet_ids          = module.aws_baseline_vpc.private_subnets
      tags                = { Name = "${var.tags.project}-${var.tags.environment}-ecr-dkr-vpc-endpoint" }
    }
  }

  depends_on = [aws_security_group.non_default]

  tags = var.tags
}

resource "aws_security_group" "non_default" {
  vpc_id      = module.aws_baseline_vpc.vpc_id
  name        = "sg_endpoints_ecr"
  description = "Endpoint ECR security group"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.aws_baseline_vpc.cidr]
    description = "Endpoint ECR security group 443"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = [var.aws_baseline_vpc.cidr]
    description = "Endpoint ECR security group (all traffic)"
  }
}
