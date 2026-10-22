# End-to-End DevOps CI/CD Pipeline with Kubernetes Deployment & Monitoring

> A complete DevOps workflow on AWS: infrastructure is provisioned with **Terraform**, servers are configured with **Ansible**, every GitHub push triggers a **Jenkins** pipeline that builds, tests, scans and containerises a Java application with **Docker**, and the image is deployed to **Amazon EKS** (Kubernetes) and monitored with **Prometheus, Blackbox Exporter and Grafana**.

Built during my DevOps & Cloud Engineering training, February to March 2026.

| | |
|---|---|
| **Cloud** | AWS, region `ap-south-1` (Mumbai) |
| **Pipeline** | Jenkins Declarative Pipeline, 15 stages, triggered by a GitHub webhook |
| **Quality & security** | SonarQube, Trivy (filesystem, build and image scans) |
| **Artifacts & images** | Nexus (Maven artifact), Docker Hub (container image) |
| **Runtime** | Amazon EKS, 2 worker nodes, Deployment with 2 replicas behind a LoadBalancer |
| **Monitoring** | Prometheus, Blackbox Exporter, Grafana |

---

# 1. Problem / Goal

> *Take an application from source code to a running, monitored deployment on Kubernetes, with no manual steps between a `git push` and the live release.*

Doing this by hand is slow and error-prone: servers are set up differently each time, code is shipped without quality or security checks, and nobody notices when the application goes down. This project automates the whole path.

### Key Challenges & Engineering Realities

* **Many tools, many servers.** Jenkins, SonarQube, Nexus, the Kubernetes management host and the monitoring stack each run on their own EC2 server, so every integration (Maven to Nexus, Jenkins to SonarQube, Jenkins to EKS) had to be wired across the network with the right ports, tokens and credentials.
* **Credentials must stay out of code.** The SonarQube token, Docker Hub login and AWS keys live in the Jenkins credential store and are referenced by ID from the pipeline.
* **Changing public IPs.** Stopping and starting EC2 instances changes their public IPs. The Nexus URLs in the application's `pom.xml` had to be updated repeatedly (the commit history of the application repository shows it). In a real setup I would use Elastic IPs or DNS names.
* **Security scanning at three levels.** A single scan is not enough: source files, the built artifact and the final Docker image can each contain different vulnerabilities, so the pipeline scans all three.

---

# 2. What I Did

## Architecture Overview

```mermaid
flowchart LR
    Dev["Developer push"] --> GH["GitHub"]
    GH -- webhook --> J["Jenkins"]
    J --> Build["Maven build and test"]
    Build --> Sonar["SonarQube analysis"]
    Sonar --> TrivyFS["Trivy scans"]
    TrivyFS --> Nexus["Nexus artifact upload"]
    Nexus --> Docker["Docker build"]
    Docker --> TrivyImg["Trivy image scan"]
    TrivyImg --> Hub["Docker Hub"]
    Hub --> EKS["Amazon EKS"]
    EKS --> LB["LoadBalancer service"]
    Prom["Prometheus + Blackbox Exporter"] -- probes --> LB
    Prom --> Graf["Grafana dashboard"]
```

* **Terraform:** provisions the SonarQube and Nexus EC2 servers and the SSH key pair.
* **Ansible:** installs Docker on target servers with a single playbook.
* **Jenkins:** the CI/CD engine. It runs the pipeline on every push, using a webhook from GitHub.
* **Maven:** compiles, tests and packages the Java application, and uploads the artifact to Nexus.
* **SonarQube:** analyses code quality and applies a quality gate.
* **Trivy:** scans the source tree, the built artifact and the final Docker image, and publishes HTML reports in Jenkins.
* **Docker:** packages the application into an image (see below).
* **Amazon EKS:** runs the application as a Kubernetes Deployment (2 replicas) exposed through a LoadBalancer service.
* **Prometheus, Blackbox Exporter and Grafana:** probe the application's public URL and show uptime and response time on a dashboard.

## The Application

The Board Game DB application is a **Java 17 Spring Boot** web app (Thymeleaf UI, Spring Security login, in-memory H2 database) listening on port 8080. It is a fork of a project provided by my mentor at **Q-Spiders Institute**; I did not write the application, and full credit for it goes to its original authors and Q-Spiders (see [NOTICE.md](NOTICE.md)). The work in this repository is the DevOps side. In the application repository ([Board_game_DBproject](https://github.com/Kunj3336/Board_game_DBproject)) I pointed Maven's `distributionManagement` at my Nexus server (`maven-releases` and `maven-snapshots` repositories) and set the image name in the Kubernetes manifest.

## Where Docker Is Used

Docker appears at four points in this project:

1. **Installed by Ansible** on target servers (`ansible/dockerplaybook.yaml`).
2. **Runs the tools:** SonarQube and Nexus run as containers on their own servers (`docker ps` output in the screenshots).
3. **Packages the application:** the `docker/Dockerfile` starts from the `eclipse-temurin:17-jdk` base image, copies in the jar that Maven built, exposes port 8080 and starts the app with `java -jar`. The pipeline builds it with `docker build`, scans it with Trivy and pushes it to Docker Hub.
4. **Runs in Kubernetes:** EKS pulls that image from Docker Hub and runs it in pods.

## Servers

| Server | Role | How it was created |
|---|---|---|
| SonarQube | Code quality analysis (container, port 9000) | Terraform |
| Nexus | Artifact repository (container, port 8081) | Terraform |
| Jenkins | CI/CD controller (port 8080) | Launched separately from the Terraform configuration |
| Ansible | Configuration management control node | Launched separately from the Terraform configuration |
| Kubernetes management host | Runs `eksctl` and `kubectl` | Launched separately from the Terraform configuration |
| Monitoring server | Prometheus (9090), Grafana (3000), Blackbox Exporter (9115) | Launched separately from the Terraform configuration |
| EKS worker nodes (2 x t3.medium) | Run the application pods | Created with `eksctl` as a managed node group |

## Project Structure

Every folder has its own README with setup and usage details.

```
End-to-End-DevOps-CI-CD-Pipeline-with-Kubernetes-Deployment-Monitoring/
├── README.md
├── NOTICE.md                       # credits and attribution
├── .gitignore
├── docs/
│   └── architecture.md             # design decisions and known limitations
├── terraform/
│   ├── README.md
│   ├── main.tf                     # SonarQube and Nexus servers + key pair
│   ├── providers.tf                # AWS provider, region ap-south-1
│   └── .terraform.lock.hcl
├── ansible/
│   ├── README.md
│   ├── dockerplaybook.yaml         # installs Docker
│   └── inventory.ini.example       # target servers (copy to inventory.ini)
├── docker/
│   ├── README.md
│   └── Dockerfile                  # application image
├── jenkins/
│   ├── README.md                   # required tools, plugins, credentials
│   └── Jenkinsfile                 # 15-stage CI/CD pipeline
├── kubernetes/
│   ├── README.md
│   └── deployment-service.yaml     # Deployment (2 replicas) + LoadBalancer Service
├── monitoring/
│   ├── README.md
│   └── prometheus.yml              # Blackbox scrape configuration
└── screenshots/
    ├── README.md                   # index of the 20 screenshots
    └── *.png
```

---

# 3. Configurations & Code Used

The main configuration of each folder is shown below with an explanation. Setup details are in each folder's own README.

## 3.1 Infrastructure as Code (`terraform/`)

Terraform creates the two servers that host SonarQube and Nexus, plus the SSH key pair used to log in. Names come from a list, so each instance gets its own tag.

```hcl
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
```

The provider is pinned to a fixed version for reproducible runs:

```hcl
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.32.1"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}
```

Run with `terraform init`, `terraform plan` and `terraform apply`. The EKS cluster and the remaining servers were created outside this configuration, which is one of the improvements listed at the end.

---

## 3.2 Configuration Management (`ansible/`)

An inventory (`inventory.ini.example`, copied to `inventory.ini` and filled in before use) lists the target servers and the SSH settings:

```ini
[servers]
# One public IP per line. The original run targeted a single server.
<target-server-public-ip>

[servers:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=/home/ubuntu/finalproject-key.pem
```

The playbook installs Docker from the official Docker repository. It reads `ansible_distribution_release`, so the same playbook works across Ubuntu releases:

```yaml
---
- name: Install Docker on all servers
  hosts: servers
  become: yes

  tasks:
    - name: Update apt packages
      ansible.builtin.apt:
        update_cache: yes

    - name: Install required dependencies
      ansible.builtin.apt:
        name:
          - ca-certificates
          - curl
          - gnupg
          - lsb-release
        state: present

    - name: Add Docker GPG key
      ansible.builtin.apt_key:
        url: https://download.docker.com/linux/ubuntu/gpg
        state: present

    - name: Add Docker repository
      ansible.builtin.apt_repository:
        repo: "deb https://download.docker.com/linux/ubuntu {{ ansible_distribution_release }} stable"
        state: present

    - name: Update apt cache after adding Docker repo
      ansible.builtin.apt:
        update_cache: yes

    - name: Install Docker packages
      ansible.builtin.apt:
        name:
          - docker-ce
          - containerd.io
        state: present

    - name: Start and enable Docker service
      ansible.builtin.service:
        name: docker
        state: started
        enabled: yes
```

Run from the Ansible server with `ansible-playbook -i inventory.ini dockerplaybook.yaml`.

---

## 3.3 Containerisation (`docker/Dockerfile`)

```dockerfile
# Copied from the application repository (github.com/Kunj3336/Board_game_DBproject).
# Used by the Jenkins "Build Docker image" stage, after `mvn package` has produced target/*.jar.
FROM eclipse-temurin:17-jdk

EXPOSE 8080

ENV APP_HOME /usr/src/app

COPY target/*.jar $APP_HOME/app.jar

WORKDIR $APP_HOME

CMD ["java", "-jar", "app.jar"]
```

| Instruction | Purpose |
|---|---|
| `FROM eclipse-temurin:17-jdk` | Java 17 runtime base image |
| `EXPOSE 8080` | The port the Spring Boot app listens on |
| `COPY target/*.jar ...` | Copies the jar produced by `mvn package` into the image |
| `CMD ["java", "-jar", "app.jar"]` | Starts the application when the container starts |

In the pipeline the image is built with `docker build -t kunj0701/boardgameprojectimage .`. To try it locally after `mvn package`, run `docker run -p 8080:8080 kunj0701/boardgameprojectimage`.

---

## 3.4 CI/CD Pipeline (`jenkins/Jenkinsfile`)

The Jenkins job `final-project` is triggered by a GitHub webhook ("GitHub hook trigger for GITScm polling"). The pipeline runs 15 stages:

| # | Stage | What it does |
|---|---|---|
| 1 | Git-clone | Pulls the application source from GitHub |
| 2 | Maven compile | Compiles the Java code |
| 3 | Maven test | Runs the unit tests |
| 4 | SonarQube code analysis | Sends the code to SonarQube for analysis and the quality gate |
| 5 | Trivy filesystem scan | Scans the source tree for vulnerable dependencies |
| 6 | Publish Trivy report | Publishes the HTML report in Jenkins |
| 7 | Maven package | Builds the application jar |
| 8 | Trivy build scan | Scans the built output |
| 9 | Publish build scan | Publishes the HTML report |
| 10 | Deploy artifact to Nexus | Uploads the artifact with `mvn deploy` |
| 11 | Build Docker image | Builds the image from the Dockerfile |
| 12 | Trivy image scan | Scans the Docker image for OS and library vulnerabilities |
| 13 | Publish image scan | Publishes the HTML report |
| 14 | Push image to Docker Hub | Uploads the image |
| 15 | Deploy to EKS | Updates the kubeconfig and runs `kubectl apply` |

A mail notification is sent after every run, on success or failure.

<details>
<summary><b>Show the full Jenkinsfile</b></summary>

```groovy
// Declarative pipeline for the Jenkins job "final-project".
// Triggered by a GitHub webhook ("GitHub hook trigger for GITScm polling").
// Cluster name, region and credential IDs match the Jenkins and EKS screenshots.
// Note: kubernetes/deployment-service.yaml is also kept in the application repo
// so the deploy stage can apply it from the Jenkins workspace.
pipeline {
    agent any

    tools {
        jdk 'openjdk-17'
        maven 'maven'
    }

    environment {
        AWS_REGION   = "ap-south-1"
        CLUSTER_NAME = "my-eks-cluster"
        DOCKER_IMAGE = "kunj0701/boardgameprojectimage"
    }

    stages {
        stage('Git-clone') {
            steps {
                git branch: 'main', url: 'https://github.com/Kunj3336/Board_game_DBproject.git'
            }
        }
        stage('Maven compile') {
            steps { sh 'mvn compile' }
        }
        stage('Maven test') {
            steps { sh 'mvn test' }
        }
        stage('SonarQube code analysis') {
            steps {
                withSonarQubeEnv('sonarqube') {
                    sh 'mvn verify sonar:sonar -Dsonar.projectName=BoardGame -Dsonar.projectKey=BoardGame'
                }
            }
        }
        stage('Trivy filesystem scan') {
            steps {
                sh '''
                    mkdir -p reports
                    curl -fsSL -o trivy-template.tpl https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/html.tpl
                    trivy fs --format table .
                    trivy fs . --format template --template "@trivy-template.tpl" -o reports/trivy-report.html
                '''
            }
        }
        stage('Publish Trivy report') {
            steps {
                publishHTML([allowMissing: false, alwaysLinkToLastBuild: true, keepAll: true,
                             reportDir: 'reports', reportFiles: 'trivy-report.html',
                             reportName: 'Trivy Security Report'])
            }
        }
        stage('Maven package') {
            steps { sh 'mvn package' }
        }
        stage('Trivy build scan') {
            steps {
                sh '''
                    trivy fs --format table target/
                    trivy fs target/ --format template --template "@trivy-template.tpl" -o reports/trivy-build-report.html
                '''
            }
        }
        stage('Publish build scan') {
            steps {
                publishHTML([allowMissing: false, alwaysLinkToLastBuild: true, keepAll: true,
                             reportDir: 'reports', reportFiles: 'trivy-build-report.html',
                             reportName: 'Trivy Build Scan Report'])
            }
        }
        stage('Deploy artifact to Nexus') {
            steps {
                withMaven(globalMavenSettingsConfig: 'maven-settings', jdk: 'openjdk-17', maven: 'maven', traceability: true) {
                    sh 'mvn clean deploy'
                }
            }
        }
        stage('Build Docker image') {
            steps {
                withDockerRegistry(credentialsId: 'dockerid', url: 'https://index.docker.io/v1/') {
                    sh 'docker build -t ${DOCKER_IMAGE} .'
                }
            }
        }
        stage('Trivy image scan') {
            steps {
                sh '''
                    trivy image --format table ${DOCKER_IMAGE}
                    trivy image ${DOCKER_IMAGE} --format template --template "@trivy-template.tpl" -o reports/trivy-image-report.html
                '''
            }
        }
        stage('Publish image scan') {
            steps {
                publishHTML([allowMissing: false, alwaysLinkToLastBuild: true, keepAll: true,
                             reportDir: 'reports', reportFiles: 'trivy-image-report.html',
                             reportName: 'Trivy Image Security Report'])
            }
        }
        stage('Push image to Docker Hub') {
            steps {
                withDockerRegistry(credentialsId: 'dockerid', url: 'https://index.docker.io/v1/') {
                    sh 'docker push ${DOCKER_IMAGE}'
                }
            }
        }
        stage('Deploy to EKS') {
            steps {
                withAWS(credentials: 'awsid', region: "${AWS_REGION}") {
                    sh '''
                        aws eks update-kubeconfig --region ${AWS_REGION} --name ${CLUSTER_NAME}
                        kubectl apply -f deployment-service.yaml
                    '''
                }
            }
        }
    }

    post {
        success {
            mail to: '<notify-email>', subject: 'Deployment success mail',
                 body: 'Hello, this mail is to notify that the deployment is success'
        }
        failure {
            mail to: '<notify-email>', subject: 'Deployment failure mail',
                 body: 'Hello, this mail is to notify that the deployment is failed'
        }
    }
}
```

</details>

Credentials (`sonar-token`, `dockerid`, `awsid`) are stored in the Jenkins credential store and referenced by ID, never written in the pipeline.

---

## 3.5 Kubernetes Deployment (`kubernetes/deployment-service.yaml`)

```yaml
apiVersion: apps/v1
kind: Deployment # Kubernetes resource kind we are creating
metadata:
  name: boardgame-deployment
spec:
  selector:
    matchLabels:
      app: boardgame
  replicas: 2 # Number of replicas that will be created for this deployment
  template:
    metadata:
      labels:
        app: boardgame
    spec:
      containers:
        - name: boardgame
          image: kunj0701/boardgameprojectimage # Image that will be used to containers in the cluster
          imagePullPolicy: Always
          ports:
            - containerPort: 8080 # The port that the container is running on in the cluster


---

apiVersion: v1 # Kubernetes API version
kind: Service # Kubernetes resource kind we are creating
metadata: # Metadata of the resource kind we are creating
  name: boardgame-ssvc
spec:
  selector:
    app: boardgame
  ports:
    - protocol: "TCP"
      port: 80
      targetPort: 8080 
  type: LoadBalancer # type of the service.
```

* The **Deployment** runs 2 replicas of the application image.
* The **Service** of type `LoadBalancer` makes AWS create an Elastic Load Balancer, so the application gets a public URL on port 80 that forwards to the container's port 8080.

---

## 3.6 Monitoring (`monitoring/prometheus.yml`)

Prometheus asks Blackbox Exporter to probe the application's load balancer URL over HTTP and records whether the response is a success (HTTP 2xx) and how long it took. Grafana reads this data from Prometheus.

> This file was reconstructed from the Prometheus *Targets* page (screenshot 5.15) because the original was not saved.

```yaml
# RECONSTRUCTED from the Prometheus "Targets" page (screenshots/18-prometheus-target-health.png).
# The original file was not saved; replace <monitoring-server-ip> with the host running Blackbox Exporter.
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets: ["localhost:9090"]

  - job_name: blackbox
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
      - targets:
          - http://prometheus.io
          - https://prometheus.io
          - http://acaa47bfeac32423a98941d776e6de58-1480642863.ap-south-1.elb.amazonaws.com   # deployed app (ELB)
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: <monitoring-server-ip>:9115
```

---

# 4. How It Was Built, Step by Step

1. **Provision servers.** Write the Terraform configuration, then run `terraform init` and `terraform apply` to create the SonarQube and Nexus servers. Launch the other servers and open the required ports in the security group (22, 8080, 8081, 9000, 6443, 3306).
2. **Install Docker with Ansible.** Write the inventory and playbook on the Ansible server and run the playbook against the target servers.
3. **Set up the tools.** Run SonarQube and Nexus as containers on their servers, install Jenkins on its own server, and install the Jenkins plugins the pipeline uses (SonarQube Scanner, Pipeline Maven, Docker Pipeline, AWS Steps, HTML Publisher, email notification).
4. **Create the EKS cluster.** On the management host, create the cluster `my-eks-cluster` with `eksclustergroup`, a managed node group of 2 `t3.medium` nodes, using `eksctl`, and verify with `kubectl get nodes`.
5. **Connect the pieces.** Add the SonarQube token, Docker Hub login and AWS keys to the Jenkins credential store. Point the application's `pom.xml` at Nexus. On the Jenkins server, connect `kubectl` to the cluster with `aws eks update-kubeconfig --region ap-south-1 --name my-eks-cluster`.
6. **Create the Jenkins pipeline job.** Create the `final-project` pipeline, enable the GitHub hook trigger and add the webhook in the GitHub repository settings.
7. **Run it.** Push a commit. The webhook starts the pipeline, which builds, tests, scans, pushes the image and deploys to EKS. A success email arrives at the end.
8. **Add monitoring.** Run Prometheus, Blackbox Exporter and Grafana on the monitoring server, add the load balancer URL as a probe target, and import the *Prometheus Blackbox Exporter* dashboard in Grafana.

---

# 5. Results & Visual Evidence

## Summary of Results

| Area | Result |
|---|---|
| EKS cluster | `my-eks-cluster`, 2 worker nodes in `Ready` state, Kubernetes v1.34 |
| Deployment | `boardgame-deployment` showing 2/2 replicas ready |
| Public access | Application served through an AWS load balancer URL |
| SonarQube | Project `BoardGame` analysed: quality gate **Passed**, 549 lines of Java and XML, 36.7% test coverage, 0.0% duplication |
| Nexus | Artifact `database_service_project` version `0.0.7-SNAPSHOT` stored in `maven-snapshots` |
| Docker Hub | Application image (353.8 MB) pushed with the `latest` tag |
| Notifications | "Deployment success mail" received after a pipeline run |
| Monitoring | Blackbox probes of the application URL returning `Success` for the `http_2xx` check, visualised in Grafana |

## 5.1 Infrastructure: EC2 Instances

All servers running in `ap-south-1`: Jenkins, SonarQube, Nexus, Ansible, the Kubernetes management host, the monitoring server and the two EKS worker nodes.

![EC2 instances](screenshots/01-all-instances.png)

---

## 5.2 Security Group Inbound Rules

The ports opened for SSH and the tools (Jenkins 8080, Nexus 8081, SonarQube 9000, Kubernetes API 6443).

![Security group rules](screenshots/02-inbound-rules.png)

---

## 5.3 Ansible Inventory

The target server and SSH settings used by the playbook.

![Ansible inventory](screenshots/03-inventory-file-in-ansible.png)

---

## 5.4 Ansible Docker Playbook

The playbook that installs Docker, shown in two parts as written on the Ansible server.

![Playbook part 1](screenshots/04-playbook-in-ansible-1.png)

![Playbook part 2](screenshots/05-playbook-in-ansible-2.png)

---

## 5.5 SonarQube and Nexus Containers

SonarQube (port 9000) and Nexus run as Docker containers on their own servers.

![SonarQube container](screenshots/06-container-in-sonarqube.png)

![Nexus container](screenshots/07-container-in-nexus.png)

---

## 5.6 SonarQube Analysis

The `BoardGame` project analysed by the pipeline: quality gate passed, 549 lines of code, 36.7% coverage, 0.0% duplication.

![SonarQube dashboard](screenshots/08-sonarqube-ui.png)

---

## 5.7 Nexus Artifact Repository

The Maven artifact uploaded by the pipeline's `mvn deploy` stage, in the `maven-snapshots` repository.

![Nexus repository](screenshots/09-nexus-repo.png)

---

## 5.8 Jenkins Credentials

Secrets are stored in Jenkins (SonarQube token, Docker Hub login, AWS keys) and referenced by ID from the pipeline. The AWS key ID is blurred.

![Jenkins credentials](screenshots/10-credentials.png)

---

## 5.9 Image Pushed to Docker Hub

The Docker image pushed by the pipeline. In this first run the Docker Hub repository was named `boardingimage`; the manifest and Jenkinsfile in this repository use the later name `boardgameprojectimage`.

![Docker Hub](screenshots/11-docker-hub-pushed-image.png)

---

## 5.10 GitHub Webhook and Jenkins Trigger

The webhook in GitHub and the "GitHub hook trigger for GITScm polling" option in the Jenkins job, which together start the pipeline on every push.

![GitHub webhook](screenshots/14-github-webhook.png)

![Jenkins trigger](screenshots/15-github-webhook-jenkins-trigger.png)

---

## 5.11 EKS Cluster Created with eksctl

`eksctl` output creating `my-eks-cluster` with a managed node group of 2 nodes, followed by `kubectl get nodes` showing both nodes `Ready`.

![EKS cluster nodes](screenshots/12-nodes-on-cluster-server.png)

---

## 5.12 Application Deployed on EKS

From the Jenkins server: the deployment shows 2/2 replicas ready, and the `LoadBalancer` service has an external AWS load balancer address.

![Deployment and service](screenshots/13-svc-on-jenkins-server.png)

---

## 5.13 Application Running

The Board Game application served through the load balancer URL.

![Application](screenshots/16-application-deployed.png)

---

## 5.14 Success Notification

The email sent by the pipeline's `post` block after a successful run.

![Success mail](screenshots/17-success-mail.png)

---

## 5.15 Prometheus Targets and Blackbox Exporter

Prometheus scraping the Blackbox Exporter, and the exporter's own page listing recent probes of the application URL with the result `Success`.

![Prometheus targets](screenshots/18-prometheus-target-health.png)

![Blackbox Exporter](screenshots/19-blackbox.png)

---

## 5.16 Grafana Dashboard

The *Prometheus Blackbox Exporter* dashboard showing probe duration for the application URL.

![Grafana](screenshots/20-grafana.png)

---

# 6. Challenges & Lessons Learned

* **Public IPs change when instances restart.** I had to update the Nexus URLs in `pom.xml` several times. Lesson: use Elastic IPs or DNS names for long-lived tools.
* **Keep every script in Git from day one.** I built most of this by running commands on servers, and several files were lost once the servers were shut down. I rebuilt them for this repository from my screenshots and notes. Since then I commit every change as I go.
* **One scan is not enough.** Scanning source, artifact and image separately catches different problems.
* **Wiring matters more than installing.** Installing each tool was quick; making Jenkins, SonarQube, Nexus, Docker Hub and EKS work together through credentials, tokens and network rules took most of the time.

# 7. What I Would Improve Next

* Put all servers and the EKS cluster under Terraform, including security groups, instead of mixing Terraform, manually launched servers and `eksctl`.
* Add a readiness probe and an explicit `rollingUpdate` strategy to the Deployment, and tag images with the build number or commit SHA instead of `latest`.
* Make the pipeline fail on high and critical Trivy findings, resolve the open SonarQube findings, and restrict security group rules to known IP ranges.
* Add Grafana alert rules for failed probes and slow responses.

---

# Notes

* The project was completed during training and the AWS resources have since been shut down. SSH keys and Terraform state files are deliberately not included (see `.gitignore`).
* The Jenkinsfile, Ansible playbook and Prometheus configuration were rebuilt from the working setup and my screenshots after the original files were lost, and aligned with what the screenshots show (cluster name, region, credential IDs).

# Credits

The Board Game DB application belongs to its original authors and to my mentor's team at Q-Spiders Institute. Details are in [NOTICE.md](NOTICE.md).

# Author

**Kunj Patel**, DevOps & Cloud Engineering
[LinkedIn](https://www.linkedin.com/in/kunj-patel-3348ba2bb/)
