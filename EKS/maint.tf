#VPC
module "my_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = var.vpc_cidr_block

  azs = data.aws_availability_zones.my_azs.names

  public_subnets  = var.my_public_subnets
  private_subnets = var.my_private_subnets

  enable_dns_hostnames = true
  enable_nat_gateway   = true
  single_nat_gateway   = true

  tags = {
    "kubernetes.io/cluster/my-eks-cluster" = "shared"

  }

  public_subnet_tags = {
    "kubernetes.io/cluster/my-eks-cluster" = "shared"
    "kubernetes.io/role/elb"               = 1

  }
  private_subnet_tags = {
    "kubernetes.io/cluster/my-eks-cluster" = "shared"
    "kubernetes.io/role/internal-elb"      = 1

  }
}

module "eks" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name    = "my_eks_cluster"
  cluster_version = "1.24"

  vpc_id     = module.my_vpc.vpc_id
  subnet_ids = module.my_vpc.private_subnets



  eks_managed_node_groups = {
    nodes = {
      min_size     = 1
      max_size     = 3
      desired_size = 2

      instance_type = ["t2.small"]
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}



