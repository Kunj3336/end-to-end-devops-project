# Jenkins Pipeline

`Jenkinsfile` is a 15-stage Declarative Pipeline for the Jenkins job `final-project`. The job is triggered by a GitHub webhook ("GitHub hook trigger for GITScm polling").

## Stages

Git-clone, Maven compile, Maven test, SonarQube analysis, Trivy filesystem scan (+ report), Maven package, Trivy build scan (+ report), deploy artifact to Nexus, Docker build, Trivy image scan (+ report), push to Docker Hub, deploy to EKS. A mail is sent on success and on failure.

## What Jenkins needs

| Item | Name used in the pipeline |
|---|---|
| JDK tool | `openjdk-17` |
| Maven tool | `maven` |
| SonarQube server (Manage Jenkins, System) | `sonarqube` |
| Maven settings file with the Nexus credentials | `maven-settings` |
| Secret text credential, SonarQube token | `sonar-token` |
| Username/password credential, Docker Hub | `dockerid` |
| AWS credential | `awsid` |
| Plugins | SonarQube Scanner, Pipeline Maven Integration, Docker Pipeline, AWS Steps, HTML Publisher, Mailer |
| Tools on the Jenkins server | Docker, Trivy, AWS CLI, `kubectl` |

Credentials are referenced by ID only; no secret values belong in this repository.

## Placeholders to replace

- `<notify-email>` in the `post` block: the address for success and failure mails.
- `DOCKER_IMAGE`, `CLUSTER_NAME` and `AWS_REGION` in the `environment` block if you use your own Docker Hub account, cluster or region.

The deploy stage runs `kubectl apply -f deployment-service.yaml` from the workspace, so the manifest (`kubernetes/deployment-service.yaml` in this repository) is also kept in the application repository root.

## Trigger

In the job configuration enable **GitHub hook trigger for GITScm polling**, then add a webhook in the GitHub repository settings pointing to `http://<jenkins-server>:8080/github-webhook/`.
