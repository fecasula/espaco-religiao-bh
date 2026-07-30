# Atualização para a versão 0.1.4

## Objetivo

Esta atualização introduz uma configuração censitária explícita, mantém Belo Horizonte como padrão e documenta que a análise espacial ainda não está homologada para outros municípios.

## Substituição

Copie o conteúdo do patch para a raiz do projeto, preservando a estrutura de pastas e autorizando a substituição dos arquivos existentes.

## Arquivos novos

- `config/censo.yml`
- `ESCOPO_ESPACIAL.md`
- `tests/testthat/test-census-config.R`
- `INSTRUCOES_DE_ATUALIZACAO_v0.1.4.md`

## Arquivos modificados

- `DESCRIPTION`
- `CITATION.cff`
- `MANIFEST.json`
- `RELATORIO_DE_ENTREGA.md`
- `CHANGELOG.md`
- `METODOLOGIA_DECISOES.md`
- `README.md`
- `index.qmd`
- `es/index.qmd`
- `_targets.R`
- `R/config.R`
- `R/spatial_population.R`
- `scripts/02_prepare_census.R`
- `reprodutibilidade.qmd`
- `es/reproducibilidad.qmd`
- `indice-cobertura.qmd`
- `shiny/app.R`
- `shiny/R/config.R`
- `shiny/README.md`
- `data/raw/census/README.md`

## Primeira execução

Feche o RStudio e abra novamente o projeto. Depois execute:

```r
source("scripts/00_install.R")
source("scripts/02_prepare_census.R")
source("scripts/03_run_pipeline.R")
```

O instalador deve ser executado novamente porque `yaml` passou a ser dependência direta do projeto.

## Configuração padrão

`config/censo.yml` utiliza:

- município: Belo Horizonte;
- código IBGE: 3106200;
- ano: 2022;
- perfil: desenvolvimento;
- geometria simplificada: sim;
- formato: GeoPackage.

Para resultados acadêmicos finais, altere para:

```yaml
geometria:
  perfil: "publicacao"
  simplificada: false
```

## Limitação deliberada

Alterar o município para outro código provoca uma interrupção controlada. Isso é esperado. A parametrização integral para outras cidades está em desenvolvimento.

## Arquivos gerados

No perfil padrão:

```text
data/derived/setores_3106200_2022_simplificado.gpkg
shiny/data/setores_ativos.gpkg
```

O arquivo antigo `setores_bh_2022.gpkg` pode ser mantido como backup, mas deixa de ser o caminho principal da aplicação.
