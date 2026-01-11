# IAM for karpenter

resource "aws_iam_role" "karpenter" {
  name = "karpenter-controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_eks_cluster.this.identity[0].oidc[0].issuer
      }
      Action = "sts:AssumeRoleWithWebIdentity"
    }]
  })
}

module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 20.0"

  cluster_name = aws_eks_cluster.this.name

  irsa_oidc_provider_arn = aws_iam_openid_connect_provider.this.arn

  node_iam_role_name = "karpenter-node-role"

  tags = {
    Environment = "${var.env}"
  }
}

# Helm install for karpenter
data "aws_eks_cluster" "cluster" {
  depends_on = [aws_eks_cluster.this]
  name = var.eks_name
}

data "aws_eks_cluster_auth" "cluster" {
  depends_on = [aws_eks_cluster.this]
  name = var.eks_name
}

provider "kubernetes" {
  host = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token = data.aws_eks_cluster_auth.cluster.token
}

resource "null_resource" "kubeconfig" {
  provisioner "local-exec" {
    command = <<EOT
aws eks update-kubeconfig \
  --region ${var.region} \
  --name ${aws_eks_cluster.this.name}
EOT
  }
}

provider "helm" {
  kubernetes {
    host = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token = data.aws_eks_cluster_auth.cluster.token
  }
}

data "aws_eks_cluster_auth" "this" {
  name = aws_eks_cluster.this.name
}

resource "helm_release" "karpenter" {
  name       = "karpenter"
  namespace  = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = "0.35.0"

  create_namespace = true

  values = [yamlencode({
    settings = {
      clusterName     =  aws_eks_cluster.this.name
      clusterEndpoint = data.aws_eks_cluster.cluster.endpoint
      interruptionQueue = module.karpenter.queue_name
    }
    serviceAccount = {
      annotations = {
        "eks.amazonaws.com/role-arn" = module.karpenter.iam_role_arn
      }
    }
  })]
}
