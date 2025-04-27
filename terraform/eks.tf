# EKS 클러스터 모듈
module "eks" {
  # 모듈 소스 및 버전
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.4"

  # 클러스터 기본 설정
  cluster_name    = "spoonlabs-cluster"
  cluster_version = "1.29"

  # 네트워크 설정 (Private Subnet)
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # IRSA(OIDC) 활성화
  enable_irsa = true

  # 관리형 노드 그룹
  eks_managed_node_groups = {
    default_node_group = {
      desired_size   = 2
      min_size       = 1
      max_size       = 3
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"

      # 노드 그룹 라벨
      labels = {
        subnet = "private"
      }
    }
  }

  # API 서버 퍼블릭 엔드포인트 Test용도
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

  # 리소스 태그
  tags = {
    environment = "dev"
    project     = "spoonlabs"
  }
}
