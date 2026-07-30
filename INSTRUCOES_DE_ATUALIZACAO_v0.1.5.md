# Atualização para a versão 0.1.5

## Objetivo

Esta atualização substitui o fluxo padrão `geobr + censobr` pela malha com atributos definitiva do IBGE. Geometria e população passam a ser obtidas do mesmo GeoPackage estadual.

## Arquivos principais alterados

- `config/censo.yml`
- `R/config.R`
- `R/spatial_population.R`
- `scripts/02_prepare_census.R`
- `scripts/03_run_pipeline.R`
- `_targets.R`
- `README.md`
- `ESCOPO_ESPACIAL.md`
- `reprodutibilidade.qmd`
- `es/reproducibilidad.qmd`
- `data/README.md`
- `data/raw/census/README.md`
- `shiny/README.md`
- `.gitignore`
- `DESCRIPTION`
- `CHANGELOG.md`
- `METODOLOGIA_DECISOES.md`
- `RELATORIO_DE_ENTREGA.md`
- `tests/testthat/test-census-config.R`
- `tests/testthat/test-spatial-population.R`
- `shiny/R/config.R`

## Procedimento

1. Feche QGIS, Shiny e processos que possam manter GeoPackages abertos.
2. Substitua os arquivos do projeto pelos arquivos desta versão.
3. Mantenha o arquivo oficial já baixado em:

```text
data/raw/census/ibge_definitivo/MG_setores_CD2022.gpkg
```

4. Execute:

```r
source("scripts/02_prepare_census.R")
```

O resultado esperado é:

```text
Setores: 5.166
População total: 2.315.560
Setores multipartidos consolidados: 1
```

5. Limpe apenas os metadados antigos do `{targets}` e execute o pipeline:

```r
targets::tar_destroy(destroy = "meta")
source("scripts/03_run_pipeline.R")
```

6. Execute os testes e o aplicativo:

```r
testthat::test_dir("tests/testthat")
shiny::runApp("shiny")
```

## Observação de escopo

A parte espacial continua disponível somente para Belo Horizonte. A parametrização multimunicipal está em desenvolvimento e permanece bloqueada para evitar combinações metodologicamente inválidas.
