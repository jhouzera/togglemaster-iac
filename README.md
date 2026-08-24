# togglemaster-iac

Repositorio dedicado a infraestrutura AWS da plataforma ToggleMaster.

Responsabilidades:
- Terraform para VPC, EKS, Node Groups, RDS, Redis, DynamoDB, SQS e Secrets Manager.
- IAM com IRSA para workloads e operadores.
- Bootstrap do ArgoCD quando necessário.

Estrutura:
- `main.tf`, `providers.tf`, `variables.tf` e `outputs.tf` na raiz.
- `modules/` com os componentes reutilizaveis de VPC, EKS, dados, IAM e ECR.
- `scripts/bootstrap-argocd.sh` para instalar o ArgoCD apos o provisionamento do cluster.
- `.github/workflows/terraform-ci.yml` para validacao e scan de seguranca do IaC.
- `docs/CHECKLIST-BOOTSTRAP-DEV.md` com o checklist de execucao do ambiente `dev`.
- `docs/CHECKLIST-DEV.md` com o checklist de integracao GitHub no ambiente `dev`.
- `docs/RUNBOOK-DEV.md` com o procedimento operacional ponta a ponta.

Fluxo operacional:
- Use `terraform.tfvars.example` como base para variaveis do ambiente.
- Nao versione `terraform.tfvars` com credenciais ou segredos reais.
- Execute `terraform init -backend=false && terraform validate` para validacao local rapida.
- O bootstrap do ArgoCD exige `aws`, `kubectl` e `helm` no host de execucao do Terraform.

Pipeline por ambiente:
- `terraform-plan.yml`: executa `fmt`, `init`, `validate` e `plan` para o ambiente `dev`.
- `terraform-apply.yml`: executa `apply` manual via `workflow_dispatch`, protegido pelo GitHub Environment `dev`.
- O arquivo versionado em `environments/dev.tfvars` e a base operacional atual do projeto. Os arquivos `qa` e `prod` podem ser ativados futuramente quando a promocao entre ambientes entrar no escopo.

Secrets e variables esperados no GitHub:
- Environment variables: `AWS_REGION`, `AWS_ROLE_TO_ASSUME`, `TF_BACKEND_BUCKET`, `TF_BACKEND_REGION`, `TF_BACKEND_ROLE_ARN` no Environment `dev`.
- Environment variables opcionais: `TOGGLEMASTER_GITOPS_REPO_URL`, `TOGGLEMASTER_GITOPS_BRANCH`, `TOGGLEMASTER_ADDONS_REPO_URL`, `TOGGLEMASTER_ADDONS_BRANCH`.
- `DB_PASSWORD` continua sendo o unico secret do bootstrap do Terraform, exportado no pipeline como `TF_VAR_db_password` quando a base de dados ainda precisa ser criada.
- `SERVICE_API_KEY` e `MASTER_KEY` nao sao obrigatorios para o Terraform; eles sao gerados pelo pipeline `togglemaster-secrets-generator` e publicados no AWS Secrets Manager com os nomes `togglemaster-dev/app/service-api-key` e `togglemaster-dev/app/master-key`.
- O repositório GitOps sincroniza esses valores para os workloads via `ExternalSecret` e os expõe nas variaveis dos containers (`SERVICE_API_KEY` e `MASTER_KEY`).
- Nao configure `TF_VAR_AWS_ACCESS_KEY_ID` ou `TF_VAR_AWS_SECRET_ACCESS_KEY`: o fluxo usa
	OIDC/IRSA e essas credenciais legadas nao sao consumidas.

Escopo de seguranca:
- Secrets de runtime devem ser gerenciados pelo AWS Secrets Manager e pelo repositório
	`togglemaster-secrets-generator` quando aplicável.
- Workloads e operadores devem autenticar na AWS via IRSA. O IaC não cria mais um secret
	de credenciais AWS legadas.

Este repositorio nao deve conter codigo dos microsservicos nem manifests de aplicacao.

## Contrato entre repositorios

```text
togglemaster-bootstrap-ci-iam
	-> bucket S3 do state + roles OIDC do GitHub
togglemaster-iac
	-> VPC, EKS, dados, ECR, IAM/IRSA e bootstrap inicial do ArgoCD
togglemaster-addons
	-> addons de plataforma reconciliados pelo ArgoCD
togglemaster-gitops
	-> ApplicationSets, charts e valores das aplicações
togglemaster-apps
	-> imagens versionadas no ECR e atualização dos valores GitOps
togglemaster-secrets-generator
	-> secrets de runtime no AWS Secrets Manager
```

O apply do IaC instala o ArgoCD apenas para entregar o controle ao GitOps. Depois que o
ArgoCD estiver saudável, mudanças de addons e aplicações devem ocorrer nos repositórios
GitOps correspondentes, não por `kubectl apply` manual.

## Configuração dos GitHub Environments

Configure `dev`, `qa` e `prod` separadamente. Em cada environment, defina:

- Variables: `AWS_REGION`, `AWS_ROLE_TO_ASSUME`, `TF_BACKEND_BUCKET`,
	`TF_BACKEND_REGION` e opcionalmente `TF_BACKEND_ROLE_ARN`.
- Variables opcionais: URLs e branches de `togglemaster-gitops` e
	`togglemaster-addons`.
- Secrets gerados pelo pipeline `togglemaster-secrets-generator`: `DB_PASSWORD`, `SERVICE_API_KEY` e `MASTER_KEY` no Secrets Manager, com sincronização pelo `ExternalSecret` do repositório GitOps.

Remova secrets antigos `TF_VAR_AWS_ACCESS_KEY_ID` e `TF_VAR_AWS_SECRET_ACCESS_KEY`; eles não
são mais consumidos pelo Terraform. Em `prod`, configure reviewers obrigatórios e impeça
deploy a partir de branches que não sejam a branch protegida do ambiente.

O trust policy das roles deve casar com o claim OIDC do workflow e com o `environment:` do
job. Alterar o nome do environment ou o repositório exige atualizar também o stack
`togglemaster-bootstrap-ci-iam`.
