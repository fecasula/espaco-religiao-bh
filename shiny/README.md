# Aplicativo Shiny

> **Escopo:** esta versão espacial funciona somente para Belo Horizonte (MG). A generalização para outros municípios está em desenvolvimento.

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

Sem o GeoPackage ativo, o aplicativo mostra uma mensagem metodológica em vez de falhar silenciosamente. O painel utiliza pontos religiosos de Belo Horizonte, CRS métrico SIRGAS 2000 / UTM 23S e parâmetros empíricos derivados da pesquisa local; por isso, a simples troca do código municipal não produz uma análise válida para outra cidade.


## Publicação

A publicação deve ser iniciada pela raiz do projeto, usando:

```r
source("scripts/05_deploy_shiny.R")
```

Não edite `shiny/renv.lock` manualmente. `config/deployment.yml` fixa a versão e o commit de `{terra}`, enquanto `R/deployment.R` mantém os campos `Remote*` do `{renv}` e os campos `Github*` exigidos pelo shinyapps.io. Token e secret ficam no armazenamento local do `{rsconnect}`, nunca neste diretório.
