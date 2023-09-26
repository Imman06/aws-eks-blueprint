provider "aws" {
  region ="ap-southeast-1"
}

data "aws_eks_cluster_auth" "cluster-auth" {
  name       = "non-prod-argocd-eks-test-2"
}

data "aws_eks_cluster" "cluster" {
  name       = "non-prod-argocd-eks-test-2"
}
provider "kubernetes" {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster-auth.token
    # load_config_file       = false
}

provider "helm" {
    kubernetes {
      host                   = data.aws_eks_cluster.cluster.endpoint
      cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
      token                  = data.aws_eks_cluster_auth.cluster-auth.token
    #   load_config_file       = false
    }
}


data "aws_availability_zones" "available" {}

# locals {
#   name     = basename(path.cwd)
#   region   = "us-west-2"
#   app_name = "app-2048"

#   vpc_cidr = "10.0.0.0/16"
#   azs      = slice(data.aws_availability_zones.available.names, 0, 3)

#   tags = {
#     Blueprint  = local.name
#     GithubRepo = "github.com/aws-ia/terraform-aws-eks-blueprints"
#   }
# }


################################################################################
# EKS Blueprints Addons
################################################################################

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.0"

  cluster_name      = "non-prod-argocd-eks-test-2"
  cluster_endpoint  = "https://43F975D61CFA3AE79C5DBD1AC2D102C0.gr7.ap-southeast-1.eks.amazonaws.com"
  cluster_version   = "1.27"
  oidc_provider_arn = "https://oidc.eks.ap-southeast-1.amazonaws.com/id/43F975D61CFA3AE79C5DBD1AC2D102C0"

  # We want to wait for the Fargate profiles to be deployed first
#   create_delay_dependencies = [for prof in module.eks.fargate_profiles : prof.fargate_profile_arn]

  # EKS Add-ons
  eks_addons = {
    # coredns = {
    #   configuration_values = jsonencode({
    #     computeType = "Fargate"
    #     # Ensure that the we fully utilize the minimum amount of resources that are supplied by
    #     # Fargate https://docs.aws.amazon.com/eks/latest/userguide/fargate-pod-configuration.html
    #     # Fargate adds 256 MB to each pod's memory reservation for the required Kubernetes
    #     # components (kubelet, kube-proxy, and containerd). Fargate rounds up to the following
    #     # compute configuration that most closely matches the sum of vCPU and memory requests in
    #     # order to ensure pods always have the resources that they need to run.
    #     resources = {
    #       limits = {
    #         cpu = "0.25"
    #         # We are targetting the smallest Task size of 512Mb, so we subtract 256Mb from the
    #         # request/limit to ensure we can fit within that task
    #         memory = "256M"
    #       }
    #       requests = {
    #         cpu = "0.25"
    #         # We are targetting the smallest Task size of 512Mb, so we subtract 256Mb from the
    #         # request/limit to ensure we can fit within that task
    #         memory = "256M"
    #       }
    #     }
    #   })
    # }
    vpc-cni    = {}
    # kube-proxy = {}
  }

#   # Enable Fargate logging
#   enable_fargate_fluentbit = true
#   fargate_fluentbit = {
#     flb_log_cw = true
#   }

#   enable_aws_load_balancer_controller = true
#   aws_load_balancer_controller = {
#     set = [
#       {
#         name  = "vpcId"
#         value = "vpc-02dff488ab28b725a"
#       },
#       {
#         name  = "podDisruptionBudget.maxUnavailable"
#         value = 1
#       },
#     ]
#   }

#   tags = local.tags
}


# ################################################################################
# # Sample App
# ################################################################################

# resource "kubernetes_namespace_v1" "this" {
#   metadata {
#     name = local.app_name
#   }
# }

# resource "kubernetes_deployment_v1" "this" {
#   metadata {
#     name      = local.app_name
#     namespace = kubernetes_namespace_v1.this.metadata[0].name
#   }

#   spec {
#     replicas = 3

#     selector {
#       match_labels = {
#         "app.kubernetes.io/name" = local.app_name
#       }
#     }

#     template {
#       metadata {
#         labels = {
#           "app.kubernetes.io/name" = local.app_name
#         }
#       }

#       spec {
#         container {
#           image = "public.ecr.aws/l6m2t8p7/docker-2048:latest"
#           # image_pull_policy = "Always"
#           name = local.app_name

#           port {
#             container_port = 80
#           }
#         }
#       }
#     }
#   }
# }

# resource "kubernetes_service_v1" "this" {
#   metadata {
#     name      = local.app_name
#     namespace = kubernetes_namespace_v1.this.metadata[0].name
#   }

#   spec {
#     selector = {
#       "app.kubernetes.io/name" = local.app_name
#     }

#     port {
#       port        = 80
#       target_port = 80
#       protocol    = "TCP"
#     }

#     type = "NodePort"
#   }
# }