module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.4.0"

  name                   = var.vpc_name
  cidr                   = var.vpc_cidr
  azs                    = var.aws_azs
  private_subnets        = var.private_subnet_cidrs
  public_subnets         = var.public_subnet_cidrs
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
}
