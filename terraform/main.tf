# Terraform 버전 요구사항
terraform {
  required_version = ">= 1.3.0"  

  required_providers {
    aws = {
      source  = "hashicorp/aws"  
      version = "~> 5.0"          
    }
  }

  # 상태 파일을 로컬에 저장하도록 설정
  backend "local" {
    path = "terraform.tfstate"  
  }
}

# AWS provider 설정
provider "aws" {
  region = "ap-northeast-2"  
}
