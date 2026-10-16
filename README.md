## Project Progress

### === Phase 0: Baseline & Containerization Complete ===
- **Application**: Spring Boot 2.5.6 compiled with Maven and running on Java 17 JRE Alpine runtime.
- **Local Validation**: Maven clean, unit tests, and packaging verified (`mvn clean test`, `mvn package`).
- **Containerization**: Built lightweight Docker image (`boardgame-app:v1`) and verified local container startup on host port `8085` (`http://localhost:8085`).

---

### === Phase 1: AWS Foundation (Terraform) Complete ===
- Provisioned Ubuntu 22.04 LTS EC2 (`t3.medium`, 30GB gp3 storage) in `ap-south-1` using Terraform.
- Configured Security Group allowing ports 22 (SSH), 8080 (Jenkins), 9000 (SonarQube), 8081 (Nexus), and 8085.
- Verified live instance creation in AWS Console and established programmatic SSH connectivity.

---

### === Phase 2 & 3: Configuration Management & CI Server Complete ===
- Configured Ansible control node inside WSL targeting the AWS EC2 instance.
- Automated Docker Engine installation and group configuration using idempotent playbook (`playbooks/docker.yml`).
- Automated Jenkins LTS installation and OpenJDK 21 setup using Ansible (`playbooks/jenkins.yml`).
- Unlocked Jenkins, installed essential pipeline plugins, and created the administrator profile.
- Granted `jenkins` system user access to the `docker` group (`groups=121(docker)`) for seamless container builds in CI pipelines.