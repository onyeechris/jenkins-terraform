# packer-aws

Packer templates for building custom AWS AMIs.

## Structure

There is one template in this folder, `aws-pkr-v01/`, which builds an Ubuntu-based
AMI with nginx pre-installed and configured. Its files:

### `plugins.pkr.hcl`
```hcl
packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.6"
      source  = "github.com/hashicorp/amazon"
    }
  }
}
```
Declares the `amazon` plugin (provides the `amazon-ebs` builder used in `aws.pkr.hcl`).
`packer init .` reads this block and downloads the plugin.

### `variable.pkr.hcl`
```hcl
variable profile {
  type        = string
  description = "aws profile name"
}
variable ami_name {
  type = string
}
variable instance_type {
  type = string
}
variable region {
  type = string
}

variable source_ami {
  type = string
  validation {
    condition     = length(var.source_ami) > 4 && substr(var.source_ami, 0, 4) == "ami-"
    error_message = "The image_version value must be a valid source_ami, starting with \"ami-\"."
  }
}
variable ssh_username {
  type = string
}
```
Declares the six inputs the template needs: which local AWS CLI `profile` to build
with, the name to give the resulting AMI, the build instance type, the region, the
base `source_ami` to build from (validated to look like `ami-xxxxxxxx`), and the SSH
username Packer uses to connect to the temporary build instance (`ubuntu` for
Ubuntu AMIs). None have defaults, so they must come from a `-var-file` (or `-var`).

### `values.pkrvars.hcl`
```hcl
  profile       = "smart-multicloud"
  ami_name      = "e2esa-aws-ubuntu-golden"
  instance_type = "t2.micro"
  region        = "us-east-1"
  source_ami    = "ami-053b0d53c279acc90"
  ssh_username  = "ubuntu"
```
The actual values fed to `variable.pkr.hcl` for this build: AWS CLI profile
`smart-multicloud` (an existing local profile, account `647371007555`, region
`us-east-1`), output AMI named `e2esa-aws-ubuntu-golden`, built on a `t2.micro`
in `us-east-1` starting from base AMI `ami-053b0d53c279acc90`, logging in as `ubuntu`.
Edit this file (AWS profile, region, source AMI, etc.) to point the build at your
own account/region.

### `aws.pkr.hcl`
```hcl
source "amazon-ebs" "ubuntu" {
  profile       = var.profile
  ami_name      = var.ami_name
  instance_type = var.instance_type
  region        = var.region
  source_ami    = var.source_ami
  ssh_username  = var.ssh_username
}
```
The builder definition. Uses the `amazon-ebs` builder to launch a temporary EC2
instance from `source_ami`, wiring every setting through to the variables above.

### `locals.pkr.hcl`
```hcl
locals {
  execute_command = "chmod +x {{ .Path }}; {{ .Vars }} sudo -E sh '{{ .Path }}'"
}
```
Defines the shell command Packer uses to run each provisioner script on the build
instance: make it executable, export the environment vars, then run it with `sudo`
(preserving the environment via `-E`). Referenced by `build.pkr.hcl`.

### `build.pkr.hcl`
```hcl
build {
  name = "nginx-packer-build"
  sources = [
    "source.amazon-ebs.ubuntu"
  ]
  provisioner "shell" {
    environment_vars = [
      "TEMP=hello world",
    ]
    execute_command = local.execute_command
    inline = [
      "echo Installing nginx",
      "sleep 30",
      "sudo apt-get update",
      "sudo apt-get install nginx -y",
      "sudo systemctl enable nginx",
      "sudo systemctl start nginx",
      "sudo ufw allow proto tcp from any to any port 22,80,443",
      "echo 'y' | sudo ufw enable",
      "echo \"Variable value is $TEMP\" > demo.txt"
    ]
  }

  post-processor "vagrant" {}
  post-processor "compress" {}
}
```
Ties everything together. Against the `amazon-ebs.ubuntu` source it runs one
inline shell provisioner that:
- waits 30s (lets cloud-init/networking settle), then `apt-get update`
- installs `nginx` and enables/starts the service
- opens ports 22 (SSH), 80 (HTTP), 443 (HTTPS) via `ufw` and enables the firewall
- writes a `demo.txt` containing the `TEMP` environment variable, as a sanity check
  that `environment_vars` / `execute_command` are wired correctly

After provisioning, two post-processors run: `vagrant` (packages the result as a
Vagrant box) and `compress` (produces a compressed artifact of the build output).
The final registered AMI itself comes from the `amazon-ebs` builder, not these
post-processors.

### `readme.md`
The original, shorter instructions for this template — links to external guides for
installing/configuring Packer and the AWS CLI, and the same `packer init` /
`packer validate` / `packer build` commands reproduced in the **Usage** section below.

## Prerequisites

- [Packer](https://developer.hashicorp.com/packer/install) installed
- AWS CLI installed and configured with a profile matching `profile` in `values.pkrvars.hcl` (currently `smart-multicloud`), with permissions to launch/stop EC2 instances and register AMIs. Verify it works with `aws sts get-caller-identity --profile smart-multicloud`.

## Usage

```bash
cd aws-pkr-v01

# one-time: install the required plugins
packer init .

# format files (optional)
packer fmt .

# validate the template
packer validate -var-file="values.pkrvars.hcl" .

# build the AMI
packer build -var-file="values.pkrvars.hcl" .
```

This launches a temporary EC2 instance from `source_ami` under the `smart-multicloud`
profile, installs nginx, then bakes and registers a new AMI named per `ami_name`
(`e2esa-aws-ubuntu-golden` by default), along with a Vagrant box and a compressed
artifact from the post-processors.

See `aws-pkr-v01/readme.md` for links to AWS CLI install/configure guides.
