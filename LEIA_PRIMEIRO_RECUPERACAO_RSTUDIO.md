# Versão de recuperação do projeto

Esta cópia foi preparada para evitar a falha de inicialização observada no
RStudio 2026.04.0+526 ao abrir o projeto com estado local antigo e ativação
automática do `renv`.

## Como abrir

1. Extraia a pasta completa para um caminho local.
2. Feche todas as janelas do RStudio.
3. Abra `religiao_mobilidade_bh.Rproj`.
4. Aguarde a criação automática da pasta `.Rproj.user`.
5. No Console do RStudio, confirme:

```r
normalizePath(".", winslash = "/", mustWork = TRUE)
file.exists("religiao_mobilidade_bh.Rproj")
file.exists(".Rproj.user")
```

## Ativar o renv

O `renv` não é carregado durante a inicialização. Depois que o projeto estiver
aberto e estável, execute:

```r
source("scripts/00_ativar_renv_seguro.R")
```

Não execute `renv::snapshot()` antes de validar o estado do projeto, pois os
lockfiles contêm configurações específicas usadas na publicação do Shiny.

## Alterações de recuperação

- removidos `.Rproj.user`, backups de `.Rproj.user`, `.Rhistory` e `.quarto`;
- desativada a indexação automática no arquivo `.Rproj`;
- removida a ativação duplicada e automática do `renv`;
- preservados `.Renviron`, `renv.lock`, `shiny/renv.lock`, dados, documentos,
  histórico Git e demais arquivos do projeto;
- cópias dos arquivos originais alterados foram guardadas em
  `archive/rstudio-startup-recovery-20260730/`.
