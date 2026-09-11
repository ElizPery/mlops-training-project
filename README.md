# GitOps Infrastructure: AWS EKS & Argo CD with Terraform

This project provisions a production-ready Kubernetes cluster on AWS EKS using Terraform and deploys **Argo CD** to manage cluster state via GitOps principles. Application delivery is automated using an **Argo CD `ApplicationSet`**, which continuously monitors a designated GitOps manifest repository for namespace definitions and application deployments.

---

## Architecture Diagram

**Multi-Namespace Architecture and Control Plane Isolation:**

```text
               ┌───────────────────────────────────────────┐
               │             argocd Namespace              │
               │   (ArgoCD Server, Repo Server, AppSets)   │
               └─────────────────────┬─────────────────────┘
                                     │
         ┌───────────────────────────┼───────────────────────────┐
         ▼                           ▼                           ▼
┌───────────────────┐       ┌───────────────────────┐       ┌───────────────────────┐
│  mlops-system NS  │       │   monitoring NS       │       │ staging / prod NS     │
│ (MLflow, MinIO,   │       │ (Prometheus, Grafana, │       │(Inference API,        │
│    PostgreSQL)    │       │   Loki, Pushgateway)  │       │  Blue/Green Rollouts) │
└───────────────────┘       └───────────────────────┘       └───────────────────────┘
```
---

## Dependencies & Tools Versions

Before deploying, ensure you have installed and configured:

- **Terraform** (>= 1.5.0)
- **AWS CLI** v2 (configured with administrator permissions)
- **kubectl** (version v1.30.0)
- **Docker** (for building and pushing container images to ECR)

---

## Repository Structure

```text
mlops-training-project/
├── .github/workflows/       # CI/CD pipelines (ci.yml, promote.yml, train.yml)
├── terraform/               # Infrastructure as Code (vpc, ecr, eks, argocd)
├── argocd-apps/             # GitOps application manifests organized by namespace
├── src/                     # Source code (inference, monitoring, training)
├── k8s/                     # Kubernetes manifests (production, staging)
├── rbac/                    # Roles and access permissions (RBAC)
└── tests/                   # Unit and integration tests
```

---

## Deployment Guide from Scratch (terraform apply → Status Verification)

### Step 1: Deploy Network Infrastructure (VPC)

Navigate to the `vpc/` directory, initialize Terraform and apply the configuration:

```bash
cd terraform/vpc
terraform init
terraform plan
terraform apply
```

### Step 2: Deploy ECR and EKS

```bash
# ECR
cd ../ecr
terraform init
terraform plan
terraform apply

# EKS Cluster
cd ../eks
terraform init
terraform plan
terraform apply
```

### Step 3: Configure Cluster Access

```bash
aws eks --region us-east-1 update-kubeconfig --name mlops-eks-cluster --profile devops-course
kubectl get nodes -o wide
```

### Step 4: Deploy Argo CD (Two-Stage Bootstrap)

Due to Custom Resource Definition (CRD) dependencies for `ApplicationSet`, deploy in two stages:

```bash
cd ../argocd
terraform init
terraform apply -target=helm_release.argocd 
terraform apply
```

### Step 5: Verify Status

Check pod statuses across namespaces:

```bash
kubectl get pods -n argocd
kubectl get pods -n mlops-system
kubectl get pods -n production
```