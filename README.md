# AWS DevOps Lifecycle Project

## Project Overview

This project demonstrates an end-to-end DevOps CI/CD pipeline using AWS, Terraform, Docker, Kubernetes, and GitHub Actions.

The pipeline automatically tests a Python Flask application, builds a Docker image, pushes it to Amazon ECR, and deploys it to an Amazon EKS Kubernetes cluster.

---

## Technologies Used

- **AWS EKS** — Managed Kubernetes cluster
- **Amazon ECR** — Docker image registry
- **Amazon EC2** — Self-hosted GitHub Actions runner
- **Terraform** — Infrastructure as Code
- **Docker** — Application containerization
- **Kubernetes** — Container orchestration
- **GitHub Actions** — CI/CD automation
- **Python Flask** — Web application
- **Pytest** — Automated testing

---

## CI/CD Workflow

1. Developer pushes code to the `main` branch.
2. GitHub Actions runs automated tests.
3. Docker builds the application image.
4. The image is pushed to Amazon ECR.
5. A self-hosted runner deploys the image to Amazon EKS.
6. Kubernetes updates the application deployment.
7. An AWS Load Balancer exposes the application.

---

## AWS Infrastructure

Terraform provisions and manages the AWS infrastructure required to run the application.

### Infrastructure Components

- **Amazon VPC** — Provides isolated networking for AWS resources.
- **Public and private subnets** — Separate public-facing and internal resources.
- **Amazon EKS** — Hosts the Kubernetes cluster.
- **EC2 worker nodes** — Run the application containers.
- **EC2 self-hosted GitHub Actions runner** — Deploys application updates to EKS.
- **IAM roles and policies** — Control AWS and Kubernetes access.
- **Security groups** — Control network traffic between resources.
- **AWS Load Balancer** — Routes external HTTP traffic to the application.

### Kubernetes Deployment

The application runs as a Kubernetes Deployment with two replicas for availability.

- **Kubernetes Service type:** LoadBalancer
- **Application container port:** 5001
- **External service port:** 80

### Deployment Automation

The GitHub Actions deployment job runs on the self-hosted EC2 runner. It updates the Kubernetes Deployment to use the newly built Amazon ECR image and waits for the rollout to complete.

---

## Project Structure

```text
devops-life-cycle-lab/
├── .github/
│   └── workflows/
│       └── ci.yml
├── terraform/
│   ├── main.tf
│   ├── github-runner.tf
│   └── .terraform.lock.hcl
├── k8s/
│   ├── deployment.yaml
│   └── service.yaml
├── README.md
└── .gitignore
```

---

## Deployment Verification

After deployment, verify the Kubernetes resources:

```bash
kubectl get deployments -n default
kubectl get pods -n default
kubectl get svc -n default
```

Check the deployment rollout:

```bash
kubectl rollout status deployment/devops-lifecycle-app -n default
```

The application is accessible through the external address assigned to the AWS Load Balancer.

---

## Project Outcome

Successfully implemented an automated CI/CD pipeline that:

- Runs automated Python tests.
- Builds and publishes Docker images to Amazon ECR.
- Deploys application updates to Amazon EKS.
- Uses an EC2 self-hosted GitHub Actions runner.
- Manages AWS infrastructure using Terraform.
- Runs two Kubernetes application replicas.
- Exposes the Flask application through an AWS Load Balancer.

**Result:** A working end-to-end AWS DevOps CI/CD pipeline with automated application deployment.
