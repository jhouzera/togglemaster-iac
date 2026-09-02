# Runbook de Execução da Plataforma no Ambiente Dev

## Objetivo
Este runbook descreve a ordem operacional para provisionar a infraestrutura, instalar a camada de plataforma e publicar os microsserviços ToggleMaster no ambiente `dev`.

## Repositórios envolvidos
- `togglemaster-iac`: provisionamento AWS e bootstrap do ArgoCD.
- `togglemaster-addons`: values dos addons instalados pelo ArgoCD.
- `togglemaster-gitops`: ApplicationSets, Helm Chart e values por microsserviço.
- `togglemaster-apps`: código-fonte, Dockerfiles e pipelines DevSecOps.

## Pré-requisitos
- AWS CLI autenticado com permissões adequadas.
- Ferramentas instaladas: `terraform`, `kubectl`, `helm`, `git`.
- Repositórios clonados localmente.
- Acesso de administrador ou mantenedor aos repositorios GitHub envolvidos.

## Governança antes do primeiro deploy

1. Confirme que `togglemaster-bootstrap-ci-iam` já criou o bucket de state e as roles OIDC
	do ambiente `dev`.
2. Em `togglemaster-iac > Settings > Environments`, crie o environment `dev`.
3. No environment `dev`, cadastre as variables `AWS_REGION=us-east-1`, `AWS_ROLE_TO_ASSUME`
	com o ARN da role IaC, `TF_BACKEND_BUCKET`, `TF_BACKEND_REGION=us-east-1` e
	`TF_BACKEND_ROLE_ARN`.
4. Cadastre somente o secret `TF_VAR_DB_PASSWORD` no environment `dev` quando for exigido pelo
	Terraform. Os segredos de runtime sao criados pelo `togglemaster-secrets-generator`.
5. Em `Settings > Actions > General`, permita as actions usadas e os workflows reutilizaveis
	do repositorio `togglemaster-cicd-templates`.
6. Em `Settings > Branches`, proteja a branch usada pelo laboratorio e exija os checks
	`Terraform Validate` e `Terraform Security Scan` antes do merge.
7. Confirme que o workflow usa OIDC e que nao existem secrets de access key configurados.
8. Confirme que `TF_BACKEND_BUCKET` aponta para o bucket correto e usa a key do laboratorio.
9. Confirme que o repositorio GitOps e o repositorio de addons estao acessiveis e possuem
	a estrutura esperada (`bootstrap/` e ApplicationSets).

Nunca execute apply concorrente para o mesmo ambiente. O workflow possui concorrência por
ambiente, mas operações locais ainda precisam ser coordenadas com o pipeline.

## Etapa 1. Validar o repositório de IaC
No repositório `togglemaster-iac`:

```bash
terraform init -backend=false
terraform validate
terraform fmt -check -recursive
```

Se necessário, revise o arquivo `environments/dev.tfvars` antes do primeiro provisionamento.

## Etapa 2. Executar o plan
Dispare o workflow `terraform-plan` no GitHub ou rode localmente, apenas para conferência:

```bash
bash .github/scripts/render-backend-config.sh backend.hcl dev
terraform init -backend-config=backend.hcl
terraform plan -var-file="environments/dev.tfvars"
```

Valide especialmente:
- criação da VPC;
- criação do EKS e node group;
- criação dos 3 RDS, Redis, DynamoDB e SQS;
- criação dos 5 repositórios ECR;
- criação dos segredos no AWS Secrets Manager;
- criação das roles IRSA.

## Etapa 3. Executar o apply
Dispare o workflow `terraform-apply` no GitHub ou rode localmente quando apropriado:

```bash
bash .github/scripts/render-backend-config.sh backend.hcl dev
terraform init -backend-config=backend.hcl
terraform apply -var-file="environments/dev.tfvars"
```

Observação:
- o endpoint da API EKS permite acesso publico somente a `177.94.86.239/32`. Execute o bootstrap e comandos `kubectl` a partir desse IP, de uma VPN/NAT com esse egress ou de um runner auto-hospedado permitido; GitHub-hosted runners nao possuem IP de saida fixo e nao conseguirao acessar o endpoint;
- se a `LabRole` for mandatória no laboratório, preencha `lab_role_arn` antes do apply.
- o workflow de apply gera e aplica o plano no mesmo job protegido; ele não reutiliza
	automaticamente o artefato do plan de um Pull Request anterior;
- antes de um apply, compare o plan do commit aprovado com a mudança que será executada e
	confirme a aprovação do GitHub Environment `dev`, quando configurada.

Se o apply falhar depois de criar parte dos recursos, não rode `destroy` como primeira ação.
Leia o erro, verifique o state remoto e reexecute o mesmo workflow após corrigir a causa.

## Etapa 4. Instalar o ArgoCD localmente

Com o kubeconfig já configurado para a role administrativa do EKS, execute na raiz de `togglemaster-iac`:

```bash
export AWS_PROFILE=<seu-profile>
export AWS_REGION=us-east-1
export CLUSTER_NAME=togglemaster-dev-eks
export ARGOCD_NAMESPACE=argocd
export ARGOCD_CHART_VERSION=7.8.7
export GITOPS_REPO_URL=https://github.com/jhouzera/togglemaster-gitops.git
export GITOPS_BRANCH=main

bash scripts/bootstrap-argocd.sh
```

O script exige `aws`, `kubectl` e `helm`, instala o ArgoCD e aplica a Application de bootstrap que cria os ApplicationSets de addons e microsservicos.

## Etapa 5. Validar o bootstrap do ArgoCD

Após a instalação local:

```bash
kubectl get nodes
kubectl get ns argocd
kubectl get pods -n argocd
kubectl get applications -n argocd
kubectl get applicationsets -n argocd
```

Resultados esperados:
- ArgoCD instalado;
- ApplicationSet de addons criado;
- ApplicationSet de microsserviços criado.

## Etapa 6. Validar a camada de addons
No ArgoCD ou via `kubectl`, confirme os seguintes componentes:

```bash
kubectl get pods -n kube-system
kubectl get pods -n keda
kubectl get pods -n nginx-gateway
kubectl get pods -n external-secrets
kubectl get pods -n reloader
```

Valide também:

```bash
kubectl get gatewayclass
kubectl get secretstores,clustersecretstores -A
kubectl get externalsecrets -A
```

## Etapa 6. Validar a camada de aplicações
Confirme os namespaces e workloads:

```bash
kubectl get ns
kubectl get deploy -n auth
kubectl get deploy -n flag
kubectl get deploy -n targeting
kubectl get deploy -n evaluation
kubectl get deploy -n analytics
kubectl get deploy -n edge
```

Confirme também:

```bash
kubectl get svc -A
kubectl get httproute -n edge
kubectl get gateway -n edge
kubectl get scaledobject -n analytics
kubectl get hpa -n evaluation
```

## Etapa 7. Validar o pipeline de microsserviços
Cada microsserviço possui um workflow próprio no repositório `togglemaster-apps`.

Fluxo esperado:
1. Abrir Pull Request alterando um único microsserviço.
2. Validar o workflow correspondente.
3. Confirmar execução de build, lint, Trivy, gosec ou bandit e scan da imagem.
5. Após merge em `main`, confirmar push da imagem no ECR.
6. Confirmar atualização do arquivo `charts/togglemaster/apps/*-values.yaml` no repositório `togglemaster-gitops`.
7. Confirmar sincronização automática do ArgoCD.

## Etapa 8. Validação contínua do laboratorio

1. Execute os checks no Pull Request da branch protegida.
2. Após o merge, confirme a publicação da imagem `togglemaster-dev` e a sincronização do ArgoCD.
3. Registre no Pull Request o resultado do plan, da imagem e os dashboards/alertas verificados.

## Rollback

- Aplicação: reverta o commit no repositório `togglemaster-gitops` ou restaure o digest
	anterior e aguarde o ArgoCD sincronizar.
- Addon: reverta o commit no `togglemaster-addons` e confirme a saúde dos controllers.
- Infraestrutura: reverta o código Terraform, gere um novo plan e aplique somente após
	revisar destruições e mudanças de dados.
- Banco/Redis: não faça rollback destrutivo sem backup e decisão de migração; o recurso
	atual está configurado para ambiente de laboratório, com baixa retenção e sem proteção
	contra deleção.

## Etapa 9. Troubleshooting rápido
Se o ArgoCD não subir:
- validar `kubectl get pods -n argocd`;
- validar execução do script `scripts/bootstrap-argocd.sh`;
- validar acesso `aws eks update-kubeconfig`.

Se os addons não sincronizarem:
- validar o `ApplicationSet` de addons;
- validar URLs dos charts e values no repositório `togglemaster-addons`.

Se os microsserviços não sincronizarem:
- validar o `ApplicationSet` em `togglemaster-gitops/bootstrap/applicationsets/apps.yaml`;
- validar se o `values.yaml` correto foi atualizado pelo pipeline.

Se os segredos não aparecerem:
- validar a role IRSA do External Secrets Operator;
- validar o `ClusterSecretStore`;
- validar os segredos no AWS Secrets Manager.

Se o backend falhar:
- validar bucket, região, key e permissões `s3:ListBucket`, `s3:GetObject`,
	`s3:PutObject` e `s3:DeleteObject`;
- confirmar que não há outro apply usando a mesma key;
- nunca apagar o objeto de state para resolver lock; preserve versões e investigue a
	execução que reteve o lock.

Se a role OIDC falhar:
- confirmar `AWS_ROLE_TO_ASSUME`, `AWS_REGION` e `permissions: id-token: write`;
- confirmar o `environment:` do job e o claim `sub` permitido na trust policy;
- testar com `aws sts get-caller-identity` imediatamente após o step de credenciais.

## Ações manuais e evidências

As ações manuais previstas são: executar o bootstrap inicial do backend, criar/configurar o
GitHub Environment `dev`, cadastrar variables e secrets, proteger a branch do laboratorio,
configurar required status checks, confirmar conectividade AWS/Kubernetes e aprovar operações
destrutivas ou de rollback.

Para cada deploy, retenha o SHA do commit, ambiente, resultado do plan, aprovação, run URL,
versão/digest da imagem e evidências de saúde do cluster. Não anexe secrets, state ou
arquivos `tfplan` em canais não protegidos.

Se o pipeline falhar por segurança:
- revisar saída do Trivy, gosec ou bandit;
- corrigir a vulnerabilidade antes de reexecutar;
- lembrar que severidade `CRITICAL` deve bloquear o fluxo.
