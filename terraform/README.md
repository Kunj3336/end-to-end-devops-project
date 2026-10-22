# Terraform

Defines the EC2 servers for **SonarQube** and **Nexus** and the SSH key pair used to log in, in `ap-south-1`.

| File | Purpose |
|---|---|
| `main.tf` | Two `t3.medium` instances (24 GB gp3 root volume) named from a list, plus the key pair |
| `providers.tf` | AWS provider, pinned version, region `ap-south-1` |
| `.terraform.lock.hcl` | Provider version lock |

## Scope

Terraform's state from the original run confirms these two servers (SonarQube and Nexus). The other servers (Jenkins, Ansible, Kubernetes management host, monitoring) and the EKS cluster were created separately, so they are not defined here.

## Usage

1. Configure AWS credentials (for example `aws configure`).
2. Generate the key pair next to `main.tf`: `ssh-keygen -f finalproject-key` (the private key must never be committed).
3. Run:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```
4. Run `terraform destroy` when finished; `t3.medium` instances are billed while running.

`*.tfstate`, `.terraform/` and key files are excluded by `.gitignore`.
