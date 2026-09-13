# packer-aws

Packer templates for building custom AWS AMIs.

## Structure

- `aws-pkr-v01/` — builds an Ubuntu-based AMI with nginx pre-installed and configured
  - `plugins.pkr.hcl` — requires the `amazon` Packer plugin (>= 1.2.6)
  - `variable.pkr.hcl` — input variables (`profile`, `ami_name`, `instance_type`, `region`, `source_ami`, `ssh_username`)
  - `values.pkrvars.hcl` — actual values for this build (AWS profile `e2esaprofile`, `t2.micro`, `us-east-1`, output AMI name `e2esa-aws-ubuntu-golden`)
  - `aws.pkr.hcl` — `amazon-ebs` source definition (builds from `source_ami` using the values above)
  - `build.pkr.hcl` — the build: installs and starts nginx, opens ports 22/80/443 via `ufw`, then runs the `vagrant` and `compress` post-processors
  - `locals.pkr.hcl` — shell provisioner execute-command local

## Prerequisites

- [Packer](https://developer.hashicorp.com/packer/install) installed
- AWS CLI installed and configured with a profile matching `profile` in `values.pkrvars.hcl` (default: `e2esaprofile`), with permissions to launch/stop EC2 instances and register AMIs

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

This launches a temporary EC2 instance from `source_ami`, installs nginx, then
bakes and registers a new AMI named per `ami_name` (`e2esa-aws-ubuntu-golden`
by default), along with a Vagrant box and a compressed artifact from the
post-processors.

See `aws-pkr-v01/readme.md` for links to AWS CLI install/configure guides.
