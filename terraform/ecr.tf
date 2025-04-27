# ECR 리포지토리 생성
resource "aws_ecr_repository" "spring_app" {
  # 레포지토리 이름
  name                 = "spring-hello-gradle"
  # 태그 변경 가능 설정
  image_tag_mutability = "MUTABLE"

  # 리소스 태그
  tags = {
    Environment = "dev"
    Project     = "spoonlabs"
  }
}
