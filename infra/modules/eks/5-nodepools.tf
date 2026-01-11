# EC2NodeClass (shared)
# resource "kubernetes_manifest" "default_node_class" {
#   manifest = {
#     apiVersion = "karpenter.k8s.aws/v1beta1"
#     kind       = "EC2NodeClass"
#     metadata = {
#       name = "default"
#     }
#     spec = {
#       subnetSelectorTerms = [{
#         tags = {
#           "kubernetes.io/cluster/${aws_eks_cluster.this.name}" = "owned"
#         }
#       }]
#       securityGroupSelectorTerms = [{
#         tags = {
#           "kubernetes.io/cluster/${aws_eks_cluster.this.name}" = "owned"
#         }
#       }]
#       amiFamily = "AL2"
#       role      = module.karpenter.node_iam_role_name
#     }
#   }
# }

# #x86 NodePool
# resource "kubernetes_manifest" "x86_pool" {
#   manifest = {
#     apiVersion = "karpenter.sh/v1beta1"
#     kind       = "NodePool"
#     metadata = {
#       name = "x86-pool"
#     }
#     spec = {
#       template = {
#         spec = {
#           nodeClassRef = {
#             name = kubernetes_manifest.default_node_class.manifest.metadata.name
#           }
#           requirements = [
#             {
#               key      = "kubernetes.io/arch"
#               operator = "In"
#               values   = ["amd64"]
#             },
#             {
#               key      = "karpenter.sh/capacity-type"
#               operator = "In"
#               values   = ["spot", "on-demand"]
#             }
#           ]
#         }
#       }
#       limits = {
#         cpu = "1000"
#       }
#     }
#   }
# }

# # arm64 (Graviton) NodePool
# resource "kubernetes_manifest" "arm_pool" {
#   manifest = {
#     apiVersion = "karpenter.sh/v1beta1"
#     kind       = "NodePool"
#     metadata = {
#       name = "arm64-pool"
#     }
#     spec = {
#       template = {
#         spec = {
#           nodeClassRef = {
#             name = kubernetes_manifest.default_node_class.manifest.metadata.name
#           }
#           requirements = [
#             {
#               key      = "kubernetes.io/arch"
#               operator = "In"
#               values   = ["arm64"]
#             },
#             {
#               key      = "karpenter.sh/capacity-type"
#               operator = "In"
#               values   = ["spot", "on-demand"]
#             }
#           ]
#         }
#       }
#       limits = {
#         cpu = "1000"
#       }
#     }
#   }
# }
