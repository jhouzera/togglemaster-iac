# Checklist de Bootstrap do Ambiente Dev

## 1. Preparação local
- Instalar `aws`, `kubectl`, `helm`, `terraform` e `git`.
- Garantir acesso AWS com permissões para VPC, EKS, IAM, RDS, ElastiCache, DynamoDB, SQS, ECR e Secrets Manager.
- Validar autenticação AWS com `aws sts get-caller-identity`.
- Confirmar acesso de escrita aos repositórios `togglemaster-iac`, `togglemaster-addons`, `togglemaster-gitops` e `togglemaster-apps`.

## 2. Configuração do GitHub
- Criar o Environment `dev` no repositório `togglemaster-iac`.
- Definir no Environment `dev` as variables `AWS_REGION`, `AWS_ROLE_TO_ASSUME`, `TF_BACKEND_BUCKET`, `TF_BACKEND_REGION` e `TF_BACKEND_ROLE_ARN`.
- Definir no Environment `dev` o secret `TF_VAR_DB_PASSWORD` para o bootstrap inicial do banco, quando necessário.
- Os segredos `SERVICE_API_KEY` e `MASTER_KEY` devem ser gerados pelo workflow `togglemaster-secrets-generator` e publicados no AWS Secrets Manager com os nomes `togglemaster-dev/evaluation/service-api-key` e `togglemaster-dev/auth/master-key`.
- Remover secrets legados `TF_VAR_AWS_ACCESS_KEY_ID` e `TF_VAR_AWS_SECRET_ACCESS_KEY`; eles
	nao fazem parte do contrato atual.
- Definir opcionalmente no Environment `dev` as variables `TOGGLEMASTER_GITOPS_REPO_URL`, `TOGGLEMASTER_GITOPS_BRANCH`, `TOGGLEMASTER_ADDONS_REPO_URL` e `TOGGLEMASTER_ADDONS_BRANCH`.
- Definir no `togglemaster-apps` a variable `AWS_ROLE_TO_ASSUME_DEV` e, se usado, `SONAR_TOKEN`.
- Configurar no `togglemaster-apps` os secrets `GITOPS_TOKEN` e `GITOPS_REPO` para a criacao de Pull Requests de promocao.

## 3. Revisão do IaC
- Revisar `environments/dev.tfvars`.
- Preencher `lab_role_arn` em `environments/dev.tfvars` se a AWS Academy exigir a associação da `LabRole`.
- Revisar `terraform.tfvars.example` apenas como referência, sem versionar segredos reais.
- Executar `terraform init -backend=false && terraform validate` antes do primeiro apply.

## 4. Provisionamento da infraestrutura
- Executar o workflow `terraform-plan` no repositório `togglemaster-iac`.
- Revisar o plano do ambiente `dev`.
- Executar o workflow `terraform-apply` no repositório `togglemaster-iac`.
- Confirmar que o bootstrap do ArgoCD foi concluído sem erro.

## 5. Validação do cluster
- Validar o acesso ao cluster com `kubectl get nodes`.
- Confirmar a presença do namespace `argocd`.
- Confirmar os pods do ArgoCD com `kubectl get pods -n argocd`.
- Confirmar que o `ClusterSecretStore` e os `ExternalSecrets` podem ser reconciliados posteriormente.

## 6. Validação do GitOps
- Confirmar que o `ApplicationSet` de addons foi criado no ArgoCD.
- Confirmar que o `ApplicationSet` de microsserviços foi criado no ArgoCD.
- Verificar sincronização de `metrics-server`, `keda`, `nginx-gateway`, `external-secrets` e `reloader`.
- Verificar sincronização dos Applications `togglemaster-auth`, `togglemaster-flag`, `togglemaster-targeting`, `togglemaster-evaluation`, `togglemaster-analytics` e `togglemaster-edge`.

## 7. Validação do CI/CD
- Abrir um Pull Request simples em um microsserviço e confirmar execução do workflow específico.
- Confirmar `build`, `lint`, `SCA`, `SAST` e `container scan`.
- Confirmar falha do pipeline quando o Trivy encontrar vulnerabilidade `CRITICAL`.
- Fazer merge na `develop` para validar `dev` e confirmar push da imagem para o ECR.
- Confirmar criacao do Pull Request que atualiza o values correspondente no repositorio `togglemaster-gitops`.
- Confirmar sincronizacao automatica do ArgoCD apos o merge da imagem por digest.

## 8. Critérios de aceite
- Infraestrutura provisionada com sucesso no ambiente `dev`.
- ArgoCD instalado e sincronizando addons e aplicações.
- Segredos de runtime consumidos via AWS Secrets Manager e External Secrets Operator.
- Um pipeline independente por microsserviço funcionando na `main` e em Pull Requests.
- Imagens publicadas no ECR com tag semver `vMAJOR.MINOR.PATCH`.
