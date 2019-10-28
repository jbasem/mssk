module "vpc_and_subnets" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> v2.0"

  name = "${local.app_name_prefix}-vpc"
  
  cidr = local.vpc_cidr
  azs             = local.azs
  private_subnets = local.private_subnets_cidr
  public_subnets  = local.public_subnets_cidr

  enable_dns_hostnames = true
  enable_dns_support = true

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = local.tags

  # WARNING: Changing the Scope tag values here could break the tool (components in the microservices module use this name format.. needs to be changed in that case)
  private_subnet_tags = {
    Scope = "Private"
  }

  public_subnet_tags = {
    Scope = "Public" 
  }
}