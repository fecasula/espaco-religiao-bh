# Atualização para a versão 0.1.8

Esta versão corrige a publicação do Shiny quando `{terra}` é restaurado a partir do GitHub.

## Causa do erro

O `{renv}` registrou corretamente `RemoteUsername`, `RemoteRepo`, `RemoteRef` e `RemoteSha`. Entretanto, ao construir o manifesto para o shinyapps.io, a versão atual do `{rsconnect}` preserva os campos iniciados por `Github` por compatibilidade. Sem `GithubUsername`, o servidor rejeitou o manifesto.

A versão 0.1.8 mantém os dois conjuntos de metadados:

```text
RemoteUsername / GithubUsername
RemoteRepo     / GithubRepo
RemoteRef      / GithubRef
RemoteSha      / GithubSHA1
```

## Aplicação do patch

Extraia o patch na raiz do projeto, substituindo os arquivos existentes. Não substitua seu `.Renviron` real; use `.Renviron.example` apenas como modelo.

Depois reinicie o R e execute:

```r
source("scripts/08_prepare_shiny_lockfile.R")
source("scripts/07_run_tests.R")
source("scripts/05_deploy_shiny.R")
```

O preflight deve informar:

```text
Manifesto validado: terra 1.9-41 via GitHub (rspatial/terra@afe97b77).
```

O deploy deve reutilizar o aplicativo:

```text
https://fecasula.shinyapps.io/religiao-mobilidade-bh/
```

## Segurança

Não coloque `SHINYAPPS_TOKEN` nem `SHINYAPPS_SECRET` no `.Renviron`. A conta já registrada é confirmada por:

```r
rsconnect::accounts()
```

## Snapshot do ambiente

O projeto usa snapshot `explicit`, orientado pelo `DESCRIPTION`. Após qualquer alteração deliberada nas versões dos pacotes, execute o script de instalação e depois o preflight do deploy. Uma atualização de `{terra}` exige atualizar conjuntamente `version` e `github_sha1` em `config/deployment.yml`.
