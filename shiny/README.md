# Aplicativo Shiny

> **Escopo:** esta versão espacial funciona somente para Belo Horizonte (MG). A generalização para outros municípios está em desenvolvimento.

## O que o app faz

O aplicativo recalcula o **Índice de Cobertura Religiosa (ICR)** a partir de parâmetros de caminhada, retornando raio, população coberta e cobertura por confissão.

## Dependências conceituais

- estabelecimentos religiosos identificados no **CNEFE/IBGE**;
- **categorização manual prévia** das denominações religiosas;
- setores censitários da malha com atributos definitiva do Censo 2022;
- parâmetros empíricos derivados da pesquisa local de mobilidade.

## Execução local

Antes de executar:

```bash
Rscript scripts/02_prepare_census.R
Rscript scripts/03_run_pipeline.R
```

Depois, a partir da raiz do projeto:

```r
shiny::runApp("shiny")
```

O script censitário prepara `shiny/data/setores_ativos.gpkg`, uma cópia estável da base definitiva de Belo Horizonte extraída da malha com atributos do IBGE. O arquivo deve conter 5.166 setores distintos e população total de 2.315.560 habitantes.

## Publicação

A publicação deve ser iniciada pela raiz do projeto, usando:

```r
source("scripts/05_deploy_shiny.R")
```

Token e secret ficam no armazenamento local do `{rsconnect}`, nunca neste diretório.
