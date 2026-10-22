# Credits and Attribution

## Application

The application used in this project, **Board Game DB** (Java, Spring Boot), was **not written by me**. It was provided by my mentor at **Q-Spiders Institute** for DevOps practice, and I forked it to work on it:

- Forked repository: https://github.com/Kunj3336/Board_game_DBproject
- Most of its commit history is by **Aditya Jaiswal** and **Sharath-yp25**; full credit for the application code goes to them and to Q-Spiders.

Please respect the original repository's license and terms; this repository does not redistribute the application source.

## My work

Everything in this repository is my DevOps work around that application: the Terraform configuration, Ansible playbook, Jenkins pipeline, Kubernetes manifest, monitoring setup, documentation and screenshots. In the application repository I also pointed Maven's `distributionManagement` at my Nexus server and set the image name in the Kubernetes manifest.

## Reconstructed files

Some files (the Jenkinsfile, Ansible playbook and Prometheus configuration) were rebuilt from the working setup and screenshots after the originals were lost. See the Notes section of the main README.
