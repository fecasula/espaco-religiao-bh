# Atualização para a versão 0.1.12

## Motivo

O `renv.lock` já continha os campos GitHub, mas o manifesto enviado ao shinyapps.io ainda chegava sem `GithubUsername`. A versão 0.1.12 passa a gerar o manifesto, corrigir o registro de pacotes GitHub e validar o JSON exato antes do upload.

## Aplicação

Extraia o patch na raiz do projeto e aceite a substituição dos arquivos. Reinicie a sessão do R e execute:

```r
source("scripts/08_prepare_shiny_lockfile.R")
source("scripts/07_run_tests.R")
source("scripts/05_deploy_shiny.R")
```

Não execute novamente os scripts censitários nem o pipeline `{targets}`.

## Saída esperada

O script 08 deverá informar que o manifesto contém `metadata$appmode = "shiny"` e os campos GitHub. O script 05 deverá ultrapassar a etapa `Parsing manifest` e iniciar a construção da imagem.
