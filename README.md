# GitOps Infrastructure: AWS EKS & Argo CD with Terraform

This project provisions a production-ready Kubernetes cluster on AWS EKS using Terraform and deploys **Argo CD** to manage cluster state via GitOps principles. Application delivery is automated using an **Argo CD `ApplicationSet`**, which continuously monitors a designated GitOps manifest repository for namespace definitions and application deployments.

---

## Repository Structure

```text
eks-vpc-cluster/
├── vpc/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tf
│   └── backend.tf
├── eks/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tf
│   ├── backend.tf
│   └── data.tf
├── argocd/          # Argo CD deployment and ApplicationSet manifest
│   ├── values/
│   │   └── argocd-values.yaml
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tf
│   ├── backend.tf
│   └── data.tf
├── .gitignore
└── README.md
```

---

## Architecture Overview

- **VPC Module**: Uses the official `terraform-aws-modules/vpc/aws` module to create public/private subnets across multiple Availability Zones, a NAT Gateway for outbound internet access from private subnets, and essential Kubernetes subnet tags for load balancer auto-discovery.

- **Terraform Remote State**: The eks/ configuration reads outputs directly from the `vpc/` state file using data `"terraform_remote_state" "vpc"`, maintaining strict decoupling between network and cluster management.

- **Workload-Isolated Node Groups**:

    - `cpu-nodes`: Standard compute nodes (t3.small) designated for controllers, monitoring, and standard microservices.

    - `gpu-nodes`: Workload-isolated node group. For lab/educational environments, this is configured with cost-effective Spot instances (t3.small).

---

## Prerequisites

Before deploying, ensure you have installed and configured:

1. **CLI Tools**:
- **Terraform** (>= 1.5.0) installed locally.
- **AWS CLI** v2 configured with administrator permissions.
- **kubectl** installed and configured.

2. **AWS Credentials**: Configured via `aws configure` or environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`).

3. **S3 Backend Bucket**: An existing S3 bucket in your AWS account to store Terraform state files (configured as `mlops-tfstate-training` in `backend.tf`).

4. **GitOps Manifests Repository**: Ensure you have created the public GitHub repository (`mlops-training-project-manifests`) containing your `namespace/*` structure before deploying Argo CD. Possible example: `https://github.com/ElizPery/mlops-training-project-manifests`.

---

## Deployment Steps

### Step 1: Deploy Network Infrastructure (VPC)

Navigate to the `vpc/` directory, initialize Terraform and apply the configuration:

```bash
cd vpc

# Initialize backend and providers
terraform init

# Review and apply resources
terraform plan
terraform apply
```

Verify that the outputs (`vpc_id`, `private_subnets`, `public_subnets`) are displayed in the terminal upon completion.

### Step 2: Deploy Kubernetes Cluster (EKS)

Navigate to the `eks/` directory, initialize Terraform and provision the cluster:

```bash
cd ../eks

# Initialize backend and providers
terraform init

# Review and apply resources
terraform plan
terraform apply
```

---

## Connecting & Verifying the Cluster

1. Update your local `kubeconfig`:

```bash
aws eks --region us-east-1 update-kubeconfig --name mlops-eks-cluster --profile devops-course
```

2. Verify node status:

```bash
kubectl get nodes -o wide
```
All nodes should report a status of `Ready`.

3. Check node group separation:

```bash
# List CPU workload nodes
kubectl get nodes -l workload=cpu

# List GPU workload nodes
kubectl get nodes -l workload=gpu
```

4. Verify node taints on GPU nodes:

```bash
kubectl describe nodes -l workload=gpu | grep Taints
```
Output should display: `Taints: nvidia.com/gpu=true:NoSchedule`.

---

## Deploy Argo CD & ApplicationSet (Two-Stage Bootstrap)

**⚠️ Important Note on Initial Bootstrap**:

The `ApplicationSet` resource relies on Custom Resource Definitions (CRDs) installed by the Argo CD Helm chart. To prevent Terraform execution errors caused by `no matches for kind "ApplicationSet"`, deploy in two stages using `-target`:

```bash
cd ../argocd

# Initialize Terraform backend and modules
terraform init

# Install Argo CD Helm release to register CRDs in the API server
terraform apply -target=helm_release.argocd 

# Apply all remaining resources (including the ApplicationSet manifest)
terraform apply 
```

---

## Verifying the GitOps Deployment

### 1. Verify Argo CD Control Plane

Check that all core Argo CD components are running in the infra-tools namespace:

```bash
kubectl get pods -n infra-tools
```
Expected output: Pods prefixed with `argocd-server`, `argocd-repo-server`, `argocd-application-controller`, and `argocd-applicationset-controller` should be in the `Running` state.

### 2. Access Argo CD Dashboard UI

```bash
# Extract the initial admin password
kubectl -n infra-tools get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Start port-forwarding
kubectl port-forward svc/argocd-server -n infra-tools 8080:80
```

### 3. Check Argo CD Applications

Verify that the `ApplicationSet` generator automatically discovered the namespaces from your GitOps repository:

```bash
kubectl get applications -n infra-tools
```

### 4. Verify Application Deployment

Check the auto-provisioned resources inside the target `application` namespace:

```bash
# Check deployment state
kubectl get deploy -n application

# Check running pods
kubectl get pods -n application
```

---

## Resource Teardown

To avoid incurring unnecessary cloud expenses, destroy the resources when testing is complete. **Order matters**: you must destroy the EKS cluster prior to destroying the VPC.

```bash
# 1. Destroy Argo CD and ApplicationSet
cd argocd
terraform destroy 

# 2. Destroy EKS Cluster
cd ../eks
terraform destroy 

# 3. Destroy VPC Network
cd ../vpc
terraform destroy 
```