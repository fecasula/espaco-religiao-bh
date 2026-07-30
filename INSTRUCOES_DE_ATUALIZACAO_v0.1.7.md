# Atualização v0.1.7 — correção do tratamento de renda

Esta versão corrige a função `clean_income()`, que interpretava `R$ 1.620,00` como `1.620.00` e retornava `NA`.

## Arquivos modificados

- `R/clean_survey.R`
- `tests/testthat/test-cleaning.R`
- `DESCRIPTION`
- `CITATION.cff`
- `CHANGELOG.md`
- `MANIFEST.json`

## Aplicação do patch

Extraia o patch na raiz do projeto e permita a substituição dos arquivos existentes.

Não é necessário executar novamente o pipeline `{targets}`, porque a execução anterior terminou com 16 alvos concluídos. Execute apenas:

```r
source("scripts/07_run_tests.R")
```

Depois dos testes:

```r
shiny::runApp("shiny")
```

Para inspecionar os avisos produzidos pela execução espacial anterior, execute `warnings()` logo após uma nova execução do pipeline ou invalide somente `icr_default` antes de reexecutá-lo.
