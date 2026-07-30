# Relatório de validação v0.1.12

A validação foi estrutural. O ambiente desta sessão não possui R, portanto a execução de `testthat` e o deploy real devem ser confirmados na máquina do projeto.

## Verificações

- OK JSON: MANIFEST.json
- OK JSON: renv/settings.json
- OK YAML: _quarto.yml
- OK YAML: config/deployment.yml
- OK YAML: config/censo.yml
- OK YAML: .github/workflows/check.yml
- OK YAML: .github/workflows/publish.yml
- OK estrutura R: R/deployment.R: ok
- OK estrutura R: scripts/05_deploy_shiny.R: ok
- OK estrutura R: scripts/08_prepare_shiny_lockfile.R: ok
- OK estrutura R: tests/testthat/test-deployment.R: ok
