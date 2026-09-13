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

| File | Purpose |
|---|---|
| `provider.tf` | AWS provider, region `us-east-1` |
| `backened.tf` | Remote state backend (S3 bucket `my-terraform-eks-cicd`, key `jenkins/terraform.tfstate`, region `us-east-1`) |
| `data.tf` | Looks up available AZs in the region |
| `maint.tf` | Main resources — VPC module and EKS module |
| `variables.tf` | Variable declarations (CIDR, public/private subnet lists) |
| `terraform.tfvars` | Values for this environment |

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
