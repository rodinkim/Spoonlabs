module "vpc" {
  # 모듈 소스 및 버전
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.1"

  # VPC 기본 설정
  name = "spoonlabs-vpc"
  cidr = "10.21.0.0/16"

  # 가용 영역
  azs = ["ap-northeast-2a", "ap-northeast-2c"]

  # 서브넷
  public_subnets  = ["10.21.0.0/24", "10.21.1.0/24"]
  private_subnets = ["10.21.32.0/24", "10.21.33.0/24"]

  # DNS 활성화
  enable_dns_support   = true
  enable_dns_hostnames = true

  # NAT Gateway 설정
  enable_nat_gateway = true
  single_nat_gateway = false

  # VPN Gateway 설정
  enable_vpn_gateway = false

  # 리소스 태그
  tags = {
    Name        = "spoonlabs-vpc"
    Environment = "dev"
    Project     = "spoonlabs"
  }
}
