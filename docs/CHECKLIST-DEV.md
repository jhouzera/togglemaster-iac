# Checklist de Integracao GitHub + IaC (Ambiente Dev)

## 1. Environment no GitHub
- [ ] Criar o Environment `dev` no repositório `togglemaster-iac`.
- [ ] Habilitar `Required reviewers` para aprovar execucao de apply.
- [ ] Confirmar que os workflows `terraform-plan` e `terraform-apply` apontam para o Environment `dev`.

## 2. Variables do Environment `dev`
- [ ] `AWS_REGION` definido (ex: `us-east-1`).
- [ ] `AWS_ROLE_TO_ASSUME` definido com a role de IaC.
- [ ] `TF_BACKEND_BUCKET` definido com o bucket de state remoto.
- [ ] `TF_BACKEND_REGION` definido com a regiao do bucket.
- [ ] `TF_BACKEND_ROLE_ARN` definido (se houver role separada para backend).
- [ ] `TOGGLEMASTER_GITOPS_REPO_URL` definido (opcional).
- [ ] `TOGGLEMASTER_GITOPS_BRANCH` definido (opcional).
- [ ] `TOGGLEMASTER_ADDONS_REPO_URL` definido (opcional).
- [ ] `TOGGLEMASTER_ADDONS_BRANCH` definido (opcional).

## 3. Secrets do Environment `dev`
- [ ] `TF_VAR_DB_PASSWORD` definido.
- [ ] `TF_VAR_SERVICE_API_KEY` definido.
- [ ] `TF_VAR_MASTER_KEY` definido.
- [ ] Secrets legados `TF_VAR_AWS_ACCESS_KEY_ID` e `TF_VAR_AWS_SECRET_ACCESS_KEY` removidos;
	o fluxo atual usa OIDC/IRSA.

## 4. Permissoes e OIDC
- [ ] O provider OIDC do GitHub existe na conta AWS.
- [ ] A trust policy da role aceita `token.actions.githubusercontent.com`.
- [ ] A trust policy inclui os repositorios e refs corretos (main e PR merge).
- [ ] A role possui permissoes para os recursos de IaC em `dev`.
- [ ] A role possui acesso ao bucket S3 do backend remoto.

## 5. Configuracoes de Actions no GitHub
- [ ] Em `Settings > Actions > General`, a execucao de workflows esta permitida.
- [ ] Actions de terceiros usadas no pipeline estao permitidas pela politica da organizacao.
- [ ] O repositório permite `id-token: write` para OIDC.

## 6. Teste de validacao
- [ ] Executar `terraform-plan` por `workflow_dispatch`.
- [ ] Validar `terraform init`, `validate` e `plan` sem erro.
- [ ] Confirmar publicacao do artefato do plano.
- [ ] Executar `terraform-apply` manualmente.
- [ ] Aprovar a execucao via protection rule do Environment `dev`.
- [ ] Validar aplicacao concluida no AWS.

## 7. Troubleshooting rapido
- [ ] Se falhar em OIDC: revisar trust policy da role.
- [ ] Se falhar em backend S3: revisar bucket, regiao e role do backend.
- [ ] Se falhar em variaveis: conferir nomes exatos dos secrets/variables (case-sensitive).
- [ ] Se falhar em permissoes AWS: revisar policy anexada na role de IaC.

## 8. Criterio de pronto
- [ ] `terraform-plan` executa com sucesso no `dev`.
- [ ] `terraform-apply` executa com sucesso no `dev` com aprovacao do Environment.
- [ ] State remoto em S3 funcionando.
- [ ] Equipe consegue repetir o fluxo sem alteracoes manuais fora do GitHub/AWS.
