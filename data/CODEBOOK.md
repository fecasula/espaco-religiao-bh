# Dicionário das bases públicas

## `public/od_religiao_public.csv`

| Campo | Tipo | Descrição |
|---|---|---|
| `id_deslocamento` | inteiro | Identificador sequencial criado para a base pública; não corresponde ao participante. |
| `dia_codigo` | texto | Código abreviado do dia da semana. |
| `mesmo_bairro` | inteiro | 1 quando origem residencial e destino religioso foram classificados no mesmo bairro; 0 caso contrário. |
| `tempo_minutos` | numérico | Duração corrigida do deslocamento, em minutos. |
| `modo_transporte` | texto | Modo principal informado. |
| `companhia_original` | texto | Categoria original sem identificação pessoal. |
| `companhia` | texto | Categoria analítica harmonizada. |
| `dia` | texto | Dia da semana por extenso. |

## `public/pontos_religiosos_bh.csv`

| Campo | Tipo | Descrição |
|---|---|---|
| `id_estabelecimento` | inteiro | Identificador sequencial derivado. |
| `cod_setor` | texto | Código do setor censitário no CNEFE. |
| `latitude`, `longitude` | numérico | Coordenadas geográficas do cadastro. |
| `dsc_estabe` | texto | Descrição pública do estabelecimento. |
| `categoria_original` | texto | Categoria detalhada fornecida na classificação atual. |
| `confissao` | texto | Grupo amplo usado nos mapas e no ICR. |

## Dados derivados

Arquivos em `derived/` contêm tabelas descritivas, modelos, perfis religiosos e valores congelados da publicação. Campos `ic95_wald_*` reproduzem a estratégia original; campos `ic95_wilson_*` oferecem a alternativa recomendada para proporções.
