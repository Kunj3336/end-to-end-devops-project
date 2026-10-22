# EC2 servers managed by Terraform in this project:
#   index 0 -> SonarQube server   (i-0f5cce5f5ec86f14a)
#   index 1 -> Nexus server       (i-0998192b01a523427)
# The remaining servers (Jenkins, Ansible, Kubernetes management host,
# monitoring) and the EKS cluster were created outside this configuration.

locals {
  server_names = ["sonarqube", "nexus"]
}

resource "aws_instance" "projectinstances" {
  count         = length(local.server_names)
  ami           = "ami-019715e0d74f695be"
  instance_type = "t3.medium"
  key_name      = aws_key_pair.projectkeypair.key_name

  root_block_device {
    delete_on_termination = true
    volume_size           = 24
    volume_type           = "gp3"
  }

  tags = {
    Name = local.server_names[count.index]
  }
}

resource "aws_key_pair" "projectkeypair" {
  key_name   = "finalproject-key"
  public_key = file("finalproject-key.pub") # generate locally: ssh-keygen -f finalproject-key
}
