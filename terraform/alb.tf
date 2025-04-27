# EKS 클러스터 정보 및 OIDC 프로바이더
data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_name  # EKS 클러스터 이름
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name  # EKS 클러스터 인증 정보
}

data "aws_iam_openid_connect_provider" "eks" {
  url = module.eks.cluster_oidc_issuer_url  # OIDC 프로바이더 URL
}

# IAM Role을 ServiceAccount에 연결하기 위한 Trust Policy
data "aws_iam_policy_document" "alb_assume" {
  statement {
    effect = "Allow"  
    principals {
      type        = "Federated"  # 외부 시스템(여기서는 EKS OIDC 프로바이더)
      identifiers = [data.aws_iam_openid_connect_provider.eks.arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]  
    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:sub"  # 서브젝트
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]  # 특정 ServiceAccount에만 허용
    }
  }
}

# EKS ALB Controller를 위한 IAM Role 생성
resource "aws_iam_role" "alb_controller" {
  name               = "eks-alb-controller-role"  
  assume_role_policy = data.aws_iam_policy_document.alb_assume.json  
}

# IAM Policy를 ALB Controller에 연결
resource "aws_iam_policy" "alb_controller" {
  name        = "eks-alb-controller-policy"  
  description = "Policy for AWS Load Balancer Controller"  
  policy      = file("${path.module}/alb-iam-policy.json")  
}

# IAM Role에 정책을 연결
resource "aws_iam_role_policy_attachment" "alb_attach" {
  role       = aws_iam_role.alb_controller.name  
  policy_arn = aws_iam_policy.alb_controller.arn  
}

# Kubernetes Provider 설정 (EKS 클러스터와 연결)
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint  
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)  
  token                  = data.aws_eks_cluster_auth.cluster.token  
}

# Kubernetes ServiceAccount 생성
resource "kubernetes_service_account" "alb" {
  metadata {
    name      = "aws-load-balancer-controller"  
    namespace = "kube-system"  
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.alb_controller.arn  
    }
  }
}

# Helm을 사용하여 AWS Load Balancer Controller 설치
resource "helm_release" "alb_controller" {
  name       = "aws-load-balancer-controller"  
  repository = "https://aws.github.io/eks-charts"  
  chart      = "aws-load-balancer-controller"  
  namespace  = "kube-system"  
  version    = "1.7.4"  

  # ServiceAccount는 이미 생성했으므로 새로 만들지 않음
  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  # 기존 ServiceAccount 이름 설정
  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.alb.metadata[0].name
  }

  # EKS 클러스터 이름 설정
  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  # 리전 설정
  set {
    name  = "region"
    value = "ap-northeast-2"
  }

  # 의존성 설정 (ServiceAccount와 IAM Role 연결 후 실행)
  depends_on = [
    kubernetes_service_account.alb,
    aws_iam_role_policy_attachment.alb_attach
  ]
}
