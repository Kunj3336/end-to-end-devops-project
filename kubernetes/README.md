# Kubernetes

`deployment-service.yaml` contains two resources:

- **Deployment** `boardgame-deployment`: 2 replicas of the application image, container port 8080.
- **Service** `boardgame-ssvc`: type `LoadBalancer`, port 80 forwarding to container port 8080. On EKS this creates an AWS Elastic Load Balancer with a public address.

## Usage

With `kubectl` connected to the cluster (`aws eks update-kubeconfig --region ap-south-1 --name my-eks-cluster`):

```bash
kubectl apply -f deployment-service.yaml
kubectl get deploy,rs,svc
```

The `EXTERNAL-IP` column of the service shows the load balancer address. Open it in a browser to reach the application.

A load balancer and the worker nodes are billed while they exist; delete them when finished: `kubectl delete -f deployment-service.yaml`.

## Possible improvements

Add a readiness probe and an explicit `rollingUpdate` strategy, and use a version tag instead of `latest`.
