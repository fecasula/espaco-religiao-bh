# Atualização para a versão 0.1.10

## Problema corrigido

A versão anterior validava corretamente `shiny/manifest.json`, mas entregava ao
`rsconnect::deployApp()` o caminho absoluto completo. Nessa API, `manifestPath`
é resolvido a partir de `appDir`; no Windows, isso produzia um caminho duplicado:

```text
shiny/C:/.../shiny/manifest.json
```

A versão 0.1.10 mantém o caminho absoluto para validação e limpeza, mas passa ao
deploy somente:

```r
manifestPath = "manifest.json"
```

## Aplicação do patch

Extraia o patch na raiz do projeto e substitua os arquivos existentes. Reinicie
a sessão do R e execute:

```r
source("scripts/08_prepare_shiny_lockfile.R")
source("scripts/07_run_tests.R")
source("scripts/05_deploy_shiny.R")
```

Não é necessário reconstruir a base censitária nem executar o pipeline
`{targets}` novamente.

## Validação esperada

Os testes devem terminar com `DONE`. Durante o deploy, o manifesto continuará
sendo validado como `terra 1.9-41 via GitHub`, mas não deverá mais ocorrer a
mensagem `Manifest file not found` com duplicação de caminho.
