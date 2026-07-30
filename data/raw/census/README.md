# Fontes censitárias espaciais

## Escopo atual

Somente **Belo Horizonte (MG), código IBGE 3106200**, está homologada. A adaptação para outros municípios está em desenvolvimento.

## Fonte oficial padrão

A versão 0.1.5 utiliza o arquivo definitivo do IBGE:

```text
data/raw/census/ibge_definitivo/MG_setores_CD2022.gpkg
```

O arquivo pode ser obtido automaticamente por `scripts/02_prepare_census.R` ou baixado manualmente a partir da URL definida em `config/censo.yml`.

O GeoPackage estadual não é incluído no repositório porque possui aproximadamente 177 MB. Ele contém a malha e os atributos censitários, inclusive a população (`v0001`), evitando cruzamentos entre versões incompatíveis.

## Produtos gerados

```text
data/derived/setores_3106200_2022_definitivo.gpkg
shiny/data/setores_ativos.gpkg
data/derived/auditoria/diagnostico_base_ibge_definitiva.csv
data/derived/auditoria/detalhe_setores_multipartidos.csv
data/derived/auditoria/manifesto_fonte_censitaria.csv
```

## Arquivos históricos

Parquets do `{geobr}`, arquivos do `{censobr}` e combinações preliminares podem ser mantidos localmente para auditoria histórica, mas não são usados pelo pipeline acadêmico padrão.
