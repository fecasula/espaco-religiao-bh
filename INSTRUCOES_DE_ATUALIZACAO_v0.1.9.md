# Atualização para a versão 0.1.9

Esta correção elimina a falsa incompatibilidade entre as duas grafias equivalentes da versão do pacote `{terra}`:

- `1.9.41`, exibida por `packageVersion("terra")`;
- `1.9-41`, registrada no `DESCRIPTION`, no `renv.lock` e em `config/deployment.yml`.

## Aplicação do patch

Extraia o patch na raiz do projeto e permita a substituição dos arquivos.

Não execute `renv::snapshot()` nem `renv::record()` novamente antes do deploy. Os lockfiles e o commit GitHub de `{terra}` já permanecem fixados.

Reinicie a sessão do R e execute:

```r
source("scripts/08_prepare_shiny_lockfile.R")
```

A validação deverá informar que a versão local `1.9.41` é equivalente ao registro `1.9-41`.

Depois execute:

```r
source("scripts/07_run_tests.R")
source("scripts/05_deploy_shiny.R")
```

Não é necessário reconstruir a base censitária nem executar novamente o pipeline `{targets}`.
