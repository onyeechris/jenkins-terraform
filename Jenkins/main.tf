#VPC
module "my_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "my-vpc"
  cidr = var.vpc_cidr_block

  azs = data.aws_availability_zones.my_azs.names

  public_subnets          = var.my_public_subnets
  map_public_ip_on_launch = true
  enable_dns_hostnames    = true


  tags = {
    Name        = "jenk-terra-vpc"
    Terraform   = "true"
    Environment = "dev"

  }

  public_subnet_tags = {
    Name = "jenk-terra-subnet"
  }
}

#SG
module "my_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "user-service"
  description = "My Security group module"
  vpc_id      = module.my_vpc.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      description = "https-service ports"
      cidr_blocks = "0.0.0.0/0"
    },

    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "ssh"
      cidr_blocks = "0.0.0.0/0"
    }

  ]
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "outgoing traffic"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
  tags = {
    Name = "Jenk-SG"
  }
}

# #EC2
# module "ec2_instance" {
#   source = "terraform-aws-modules/ec2-instance/aws"

#   name = "my_instance"

#   instance_type = var.instances
#   key_name      = "TerraKeyPair"

#   vpc_security_group_ids      = [module.my_sg.security_group_id]
#   subnet_id                   = module.my_vpc.public_subnets[0]
#   associate_public_ip_address = true

#   user_data         = file("jenk-install.sh")
#   availability_zone = data.aws_availability_zones.my_azs.names[0]

#   tags = {
#     Name        = "My_Jenks_instance"
#     Terraform   = "true"
#     Environment = "dev"
#   }
# }

#Create an instance application
#aws ec2 instance
resource "aws_instance" "my-first-server" {
  ami                    = "ami-080e1f13689e07408"
  instance_type          = var.instances
  key_name               = "TerraKeyPair"
  vpc_security_group_ids = [module.my_sg.security_group_id]
  subnet_id              = module.my_vpc.public_subnets[0]


  user_data = file("jenk-install.sh")

  availability_zone = data.aws_availability_zones.my_azs.names[0]
  tags = {
    "Name" : "Terra-Instance"
  }
}