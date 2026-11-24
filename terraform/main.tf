data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.13.0"

  name = var.cluster_name
  cidr = var.vpc_cidr

  azs             = slice(data.aws_availability_zones.available.names, 0, var.az_count)
  private_subnets = [for index in range(var.az_count) : cidrsubnet(var.vpc_cidr, 4, index)]
  public_subnets  = [for index in range(var.az_count) : cidrsubnet(var.vpc_cidr, 4, index + 8)]

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.31.6"

  cluster_name                         = var.cluster_name
  cluster_version                      = var.cluster_version
  cluster_endpoint_public_access       = true
  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  enable_cluster_creator_admin_permissions = true

  cluster_addons = {
    coredns    = { most_recent = true }
    kube-proxy = { most_recent = true }
    vpc-cni    = { most_recent = true }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    default = {
      name                     = "${var.cluster_name}-workers"
      iam_role_name            = "${var.cluster_name}-node"
      iam_role_use_name_prefix = false
      instance_types           = [var.node_instance_type]
      min_size                 = 1
      max_size                 = 3
      desired_size             = 2
    }
  }

  tags = {
    Environment = var.environment
    Terraform   = "true"
  }
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "7.7.16"
  namespace        = "argocd"
  create_namespace = true

  depends_on = [module.eks]
}
