#VPC
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = var.vpc_cidr_block

  azs             = data.aws_availability_zones.my_azs.names
 
  public_subnets  = var.my_public_subnets
  enable_dns_hostnames = true


  tags = {
     Name = jenk-terra-vpc
    Terraform = "true"
    Environment = "dev"
  }


}


#SG
#EC2