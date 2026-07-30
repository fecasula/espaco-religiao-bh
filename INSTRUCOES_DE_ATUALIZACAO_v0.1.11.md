# Atualização para a versão 0.1.11

## Problema corrigido

O deploy com `manifestPath` falhava com:

```text
Invalid manifest file.
Manifest must contain metadata$appmode.
```

Quando `manifestPath` é fornecido, o `{rsconnect}` ignora `appMode` passado ao `deployApp()` e exige que o modo esteja dentro do próprio manifesto. A versão 0.1.11 elimina essa camada manual e volta ao fluxo padrão: o `deployApp()` gera internamente o manifesto, recebendo explicitamente `appMode = "shiny"`.

## Arquivos substituídos

- `R/deployment.R`
- `scripts/05_deploy_shiny.R`
- `scripts/08_prepare_shiny_lockfile.R`
- `tests/testthat/test-deployment.R`
- `DESCRIPTION`
- `CITATION.cff`
- `CHANGELOG.md`
- `README.md`
- `reprodutibilidade.qmd`
- `es/reproducibilidad.qmd`

## Execução

Reinicie o R e execute:

```r
source("scripts/08_prepare_shiny_lockfile.R")
source("scripts/07_run_tests.R")
source("scripts/05_deploy_shiny.R")
```

O script 08 não cria mais `shiny/manifest.json`. Qualquer manifesto residual é removido antes do deploy. Não execute novamente o pipeline censitário ou `{targets}` para esta correção.
