terraform {
  backend "s3" {
    bucket = "my-terraform-eks-cicd"
    key    = "jenkins/terraform.tfstate"
    region = "us-east-1"
  }
}