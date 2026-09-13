# EKS

Terraform stack that provisions a VPC and an Amazon EKS cluster with a managed
node group, using the community `terraform-aws-modules` modules.

## What it creates

- **VPC** (`terraform-aws-modules/vpc/aws`)
  - CIDR block from `var.vpc_cidr_block` (`172.16.0.0/16` in `terraform.tfvars`)
  - Public and private subnets across all AZs in the region (`var.my_public_subnets`, `var.my_private_subnets`)
  - A single NAT gateway, DNS hostnames enabled
  - Subnets tagged for Kubernetes/ELB discovery (`kubernetes.io/cluster/my-eks-cluster`, `kubernetes.io/role/elb`, `kubernetes.io/role/internal-elb`)
- **EKS cluster** (`terraform-aws-modules/eks/aws`), named `my_eks_cluster`, version `1.24`, deployed into the VPC's private subnets
  - One managed node group (`nodes`): `t2.small` instances, min 1 / desired 2 / max 3

## Files

### `provider.tf`
```hcl
provider "aws" {
  region = "us-east-1"
}
```
Configures the AWS provider. All resources in this stack are created in `us-east-1`.

### `backened.tf`
```hcl
terraform {
  backend "s3" {
    bucket = "my-terraform-eks-cicd"
    key    = "jenkins/terraform.tfstate"
    region = "us-east-1"
  }
}
```
Points Terraform at a remote state file stored in S3 (bucket `my-terraform-eks-cicd`,
object key `jenkins/terraform.tfstate`) instead of keeping state locally. The bucket
itself is **not** created by this stack — it must already exist before `terraform init`
runs. (Note: the filename has a typo — "backened" instead of "backend" — the content
is a normal Terraform backend block.)

### `data.tf`
```hcl
data "aws_availability_zones" "my_azs" {
}
```
A data source that queries AWS for the list of availability zones available in the
configured region. Its output (`data.aws_availability_zones.my_azs.names`) is fed into
the VPC module in `maint.tf` so subnets are spread across all AZs automatically.

### `variables.tf`
```hcl
variable "vpc_cidr_block" {
  description = "cidr_block for my vpc"
  type        = string
}

variable "my_public_subnets" {
  description = "my public subnets"
  type        = list(string)
}
variable "my_private_subnets" {
  description = "my private subnets"
  type        = list(string)
}
```
Declares the three inputs the stack needs: the VPC's CIDR block and the lists of
public/private subnet CIDRs. No defaults are set, so values must come from
`terraform.tfvars` (or `-var`/`-var-file` on the CLI).

### `terraform.tfvars`
```hcl
vpc_cidr_block     = "172.16.0.0/16"
my_public_subnets  = ["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24"]
my_private_subnets = ["172.16.4.0/24", "172.16.5.0/24", "172.16.6.0/24"]
```
Concrete values for this environment: a `/16` VPC split into three `/24` public
subnets and three `/24` private subnets (one pair per AZ, matched up positionally
with whatever AZs `data.tf` returns).

### `maint.tf`
The main resource file (note: "maint" — main/maintenance — not a typo for anything
else important, just the filename chosen for this stack). It defines two modules:

- **`module "my_vpc"`** (`terraform-aws-modules/vpc/aws`)
  - Creates the VPC using `var.vpc_cidr_block`
  - Spreads `my_public_subnets`/`my_private_subnets` across `data.aws_availability_zones.my_azs.names`
  - Enables DNS hostnames and a single (cost-saving) NAT gateway for private subnet egress
  - Tags the VPC and subnets so EKS/AWS Load Balancer Controller can auto-discover them:
    `kubernetes.io/cluster/my-eks-cluster = shared`, `kubernetes.io/role/elb = 1` on
    public subnets, `kubernetes.io/role/internal-elb = 1` on private subnets
- **`module "eks"`** (`terraform-aws-modules/eks/aws`)
  - Creates an EKS cluster named `my_eks_cluster`, Kubernetes version `1.24`
  - Deploys worker nodes into the VPC's private subnets
  - One managed node group `nodes`: instance type `t2.small`, `min_size = 1`,
    `desired_size = 2`, `max_size = 3`
  - Tags: `Environment = dev`, `Terraform = true`

### `.gitignore`
```
.terraform/*
.terraform.lock.hcl
```
Keeps the local provider/module cache (`.terraform/`) and the lock file out of
version control.

## Prerequisites

- Terraform CLI
- AWS credentials configured (`aws configure` or environment variables) with permissions to create VPC/EKS/IAM resources
- The S3 bucket referenced in `backened.tf` (`my-terraform-eks-cicd`) must already exist in `us-east-1` — Terraform does not create its own backend bucket
- `kubectl` and the AWS CLI, to interact with the cluster after it's up

## Usage

```bash
cd EKS

# initialize providers/modules and the S3 backend
terraform init

# review the plan
terraform plan

# create the VPC + EKS cluster
terraform apply
```

Once the cluster is up, point `kubectl` at it:

```bash
aws eks update-kubeconfig --region us-east-1 --name my_eks_cluster
kubectl get nodes
```

Tear everything down when done:

```bash
terraform destroy
```
