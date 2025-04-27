# Spoonlabs DevOps 실습 과제

## 개요
AWS 기반 인프라를 Terraform을 이용하여 코드로 구성하고,  
EKS 클러스터를 통해 Spring Boot 애플리케이션을 배포하는 프로젝트입니다.

## 프로젝트 구성

1. **Spring Boot 애플리케이션**  
   - `spring-boot-app/` 폴더에 애플리케이션 코드와 Dockerfile이 포함되어 있습니다.

2. **AWS 인프라 구성**  
   - `terraform/` 폴더에 VPC, EKS, ECR 등을 Terraform 코드로 구성하였습니다.

3. **Kubernetes 매니페스트**  
   - `kubernetes-manifests/` 폴더에 Deployment, Service, Ingress 리소스를 작성하여 애플리케이션을 배포합니다.

---

## 1. VPC 구성

- **CIDR**: 10.21.0.0/16
- **AZ**: ap-northeast-2a, ap-northeast-2c
- **Public Subnet**:
  - 10.21.0.0/24
  - 10.21.1.0/24
- **Private Subnet**:
  - 10.21.32.0/24
  - 10.21.33.0/24

> Public Subnet은 ALB 연결 용도,  
> Private Subnet은 EKS 노드 및 내부 통신 용도로 구성했습니다.  
> Zone 별 NAT Gateway를 사용하여 고가용성을 확보했습니다.

---

## 2. ECR 구성

- Terraform으로 `spring-hello-gradle` ECR 리포지토리를 생성했습니다.
- 로컬에서 Docker 빌드한 Spring Boot 이미지를 ECR에 푸시하여,  
  이후 EKS에서 사용할 수 있도록 준비했습니다.

---

## 3. EKS 클러스터 구성

- Terraform 공식 Module(`terraform-aws-modules/eks/aws`)을 사용하여 EKS 클러스터를 구축했습니다.
- 관리형 노드 그룹을 설정하여, Private Subnet에 EC2 워커 노드를 배치했습니다.
- IRSA(IAM Roles for Service Accounts)를 활성화하여 이후 ALB Controller와 연동 준비를 완료했습니다.

---

## 4. Kubernetes 리소스 배포

- `Deployment`, `Service`, `Ingress` 리소스를 작성하여 애플리케이션을 배포합니다.
- 서비스는 NodePort 타입으로 생성하고, Ingress를 통해 ALB를 설정하여 외부 트래픽을 라우팅합니다.
- ALB Controller는 Helm을 통해 설치하여 Kubernetes Ingress 리소스를 관리합니다.
- 만들어진 이미지는 **affinity** 옵션을 통하여 Private Subnet에 전개된 노드에 위치할 수 있도록 합니다.

---

## 5. ALB (Application Load Balancer) 구성

- ALB는 인터넷에서 EKS 클러스터로의 외부 트래픽을 라우팅하는 역할을 합니다.
- **ALB Controller**를 Kubernetes에서 실행하여 Ingress 리소스를 처리합니다.
- ALB는 Public Subnet에 배치되어, 외부에서 접근할 수 있도록 설정됩니다.
- **IAM Role**을 생성하고 Kubernetes ServiceAccount와 연결하여 ALB Controller가 ALB 리소스를 관리하도록 합니다.

---

## 구축 순서 요약

```bash
# Terraform을 통한 인프라 구축
cd terraform
terraform init
terraform apply

# Docker 빌드 및 ECR 업로드
cd spring-boot-app
docker build -t spring-hello-gradle .
docker tag spring-hello-gradle:latest <ECR_URL>:latest
docker push <ECR_URL>:latest

# Kubernetes 매니페스트 적용
cd kubernetes-manifests
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml

# ALB 리소스를 관리하는 AWS Load Balancer Controller를 Kubernetes 클러스터에 배포합니다.
helm install aws-load-balancer-controller \
  eks/aws-load-balancer-controller \
  --namespace kube-system \
  --set clusterName=<cluster-name> \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller

