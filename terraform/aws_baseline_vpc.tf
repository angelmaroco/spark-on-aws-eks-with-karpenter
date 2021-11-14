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
