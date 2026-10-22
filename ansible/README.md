# Ansible

`dockerplaybook.yaml` installs Docker from the official Docker apt repository on every host in the `servers` inventory group.

## What the playbook does

1. Updates the apt cache and installs prerequisites (`ca-certificates`, `curl`, `gnupg`, `lsb-release`)
2. Adds Docker's GPG key and repository (using `ansible_distribution_release`, so it works across Ubuntu releases)
3. Installs `docker-ce` and `containerd.io`
4. Starts and enables the Docker service

## Usage

1. Copy the example inventory and edit it:
   ```bash
   cp inventory.ini.example inventory.ini
   ```
   Put the target server's public IP under `[servers]` and make sure `ansible_ssh_private_key_file` points to your key (kept outside this repository).
2. Check connectivity: `ansible -i inventory.ini servers -m ping`
3. Run the playbook: `ansible-playbook -i inventory.ini dockerplaybook.yaml`
4. Verify on the target: `docker --version`

In the original project the playbook was run from the Ansible server, against one target server.
