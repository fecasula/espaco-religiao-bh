# Religião, mobilidade e cobertura urbana em Belo Horizonte

Projeto científico reprodutível associado ao trabalho **“Do estudo das práticas à análise dos equipamentos religiosos de Belo Horizonte (MG): uma proposta metodológica para a análise espacial das religiões nas cidades”**, de Felipe Baeta Casula Pereira e Daniel Pimenta de Prado.

> **Escopo espacial da versão atual:** a preparação censitária, o cálculo do Índice de Cobertura Religiosa e o painel cartográfico estão homologados somente para **Belo Horizonte (MG), código IBGE 3106200**.

## O que o projeto entrega

- website Quarto em português e espanhol;
- apresentações Reveal.js nos dois idiomas;
- painel Shiny do Índice de Cobertura Religiosa;
- funções R modulares e pipeline `{targets}`;
- dados públicos mínimos e resultados derivados;
- testes, GitHub Actions, licença e arquivo de citação.

## Estrutura principal do repositório

```text
.
├── _quarto.yml                 # configuração do site
├── index.qmd                   # página inicial em português
├── estudo.qmd                  # página consolidada do estudo
├── resultados.qmd              # página consolidada de resultados
├── apresentacao-pt.qmd         # apresentação Reveal.js em português
├── es/                         # páginas e apresentação em espanhol
├── assets/                     # imagens, mapas, CSS e PDF da publicação
├── bibliography/               # .bib, CSL e notas de citação
├── config/                     # parâmetros do censo e do deploy
├── R/                          # funções modulares do projeto
├── scripts/                    # instalação, pipeline, renderização e deploy
├── shiny/                      # aplicativo Shiny do ICR
├── docs/                       # saída renderizada para GitHub Pages
└── tests/                      # testes automatizados
```

## Origem dos dados

### 1. Deslocamentos religiosos

A análise de deslocamentos parte da pesquisa **Mobilidade de Idosos**, conduzida pelo CEURB/UFMG. O repositório público trabalha apenas com resultados agregados ou bases desidentificadas.

### 2. Estabelecimentos religiosos

Os estabelecimentos religiosos foram identificados a partir do **Cadastro Nacional de Endereços para Fins Estatísticos (CNEFE 2022/IBGE)**.

> **Ponto metodológico importante:** a classificação dos estabelecimentos em categorias como **Católica**, **Protestante/Evangélica**, **Espírita** e **Afro-brasileira** foi feita **manualmente** a partir dos nomes e descrições dos registros. Essa etapa é parte central do trabalho e antecede qualquer cálculo de cobertura.

### 3. Base censitária espacial

A população e a geometria dos setores vêm da **malha com atributos definitiva do Censo 2022 do IBGE**. Para Belo Horizonte, a base validada possui 5.166 setores distintos e 2.315.560 habitantes.

## Início rápido

Na raiz de uma cópia local do projeto:

```bash
Rscript scripts/00_install.R
Rscript scripts/02_prepare_census.R
Rscript scripts/03_run_pipeline.R
Rscript scripts/04_render_site.R
```

Para abrir localmente:

```r
quarto::quarto_preview()
shiny::runApp("shiny")
```

## Publicação

### Site e apresentações (GitHub Pages)

O site é renderizado para `docs/`. Depois da renderização, faça commit e push dessa pasta para o GitHub.

Endereços atuais do projeto:

- repositório: <https://github.com/fecasula/espa-o-religiao-bh>
- site: <https://fecasula.github.io/espa-o-religiao-bh/>
- apresentação em português: <https://fecasula.github.io/espa-o-religiao-bh/apresentacao-pt.html>
- apresentação em espanhol: <https://fecasula.github.io/espa-o-religiao-bh/es/presentacion-es.html>

### Painel Shiny (shinyapps.io)

O painel é publicado separadamente em:

<https://fecasula.shinyapps.io/religiao-mobilidade-bh/>

O deploy deve ser iniciado pela raiz do projeto com:

```r
source("scripts/08_prepare_shiny_lockfile.R")
source("scripts/05_deploy_shiny.R")
```

## Auditoria metodológica central

A fórmula com 4 km/h e 9,7 minutos produz 646,67 m; o texto do manuscrito registra 853,33 m e o mapa aproximadamente 649,33 m. O aplicativo adota o cálculo consistente e mantém os valores históricos como perfis de auditoria.

## Dados e ética

Microdados individuais originais devem permanecer em `data/private/`, diretório ignorado pelo Git. O GeoPackage estadual do IBGE e outros produtos espaciais pesados também ficam fora do versionamento por tamanho e por possibilidade de reconstrução.

## Citação e licença

Use `CITATION.cff` e cite tanto o trabalho acadêmico quanto a versão do software utilizada. Código sob licença MIT; dados de terceiros permanecem sujeitos às condições de suas fontes originais.
