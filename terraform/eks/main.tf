module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  vpc_id     = data.terraform_remote_state.vpc.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnets

  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }

  eks_managed_node_groups = {

    cpu-nodes = {
      min_size     = var.cpu_nodes_min
      max_size     = var.cpu_nodes_max
      desired_size = var.cpu_nodes_desired

      instance_types = [var.cpu_node_instance_type]
      capacity_type  = "ON_DEMAND"

      labels = {
        workload = "cpu"
        env      = var.environment
      }
    }

    gpu-nodes = {
      min_size     = var.gpu_nodes_min
      max_size     = var.gpu_nodes_max
      desired_size = var.gpu_nodes_desired

      instance_types = [var.gpu_node_instance_type]
      capacity_type  = "SPOT"

      labels = {
        workload = "gpu"
        env      = var.environment
      }

      taints = {
        dedicated = {
          key    = "nvidia.com/gpu"
          value  = "present"
          effect = "NO_SCHEDULE"
        }
      }
    }
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = "mlops-course"
  }
}