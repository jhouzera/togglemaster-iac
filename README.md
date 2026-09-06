# togglemaster-iac

Repositório dedicado à automação da infraestrutura AWS (IaC) da plataforma ToggleMaster utilizando **Terraform**.

## 🎯 Propósito
Provisionar toda a infraestrutura base na AWS necessária para rodar os microsserviços e os componentes de plataforma. 
Isso inclui a rede (VPC), o cluster Kubernetes (EKS), bancos de dados estruturados (RDS PostgreSQL) e não estruturados (DynamoDB), cache (ElastiCache Redis) e mensageria (SQS). 
Além disso, provisiona recursos do IAM OIDC (IRSA) garantindo a segurança seguindo o princípio do menor privilégio.

## ⚙️ Como Funciona
O Terraform atua como um cliente declarativo interagindo com a API da AWS. O controle de estado da infraestrutura (State) fica armazenado de forma segura em um bucket S3 (com lock via DynamoDB), prevenindo conflitos em execuções paralelas. Um dos grandes destaques arquiteturais é o uso de **IRSA (IAM Roles for Service Accounts)**: o cluster EKS recebe um provedor OIDC (OpenID Connect) que permite aos microsserviços (ex: `analytics-service`) assumirem *Roles* da AWS sem o uso de chaves (Access Keys) em texto puro, vinculando permissões nativas de nuvem diretamente à conta de serviço do Kubernetes.

## 🚀 Como Utilizar

A infraestrutura é dividida por módulos lógicos e é provisionada utilizando Terraform. A autenticação com a AWS é feita via perfil do AWS CLI (ex: OIDC/SSO).

### Requisitos
- Terraform >= 1.5.0
- AWS CLI autenticado
- Credenciais ou AWS Profile configurado

### Exemplo Simples de Deploy

```bash
cd infrastructure/environments/dev
# Inicializa os plugins do terraform
terraform init
# Valida e planeja a criação
terraform plan -out=tfplan
# Aplica a infraestrutura na nuvem
terraform apply tfplan
```

## 🔐 Segurança e Boas Práticas
- **Sem chaves estáticas:** Nenhuma Access Key é gerada. Todas as permissões (tanto para Workloads no EKS quanto para CI/CD) utilizam **IAM OIDC (AssumeRoleWithWebIdentity)**.
- Os estados do Terraform (State e Lock) são armazenados em um bucket S3 remoto privado com encriptação e bloqueios via DynamoDB (criados previamente pelo bootstrap).
