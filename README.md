# Espaço, religião e mobilidade em Belo Horizonte

Projeto científico reprodutível associado ao trabalho **“Do estudo das práticas à análise dos equipamentos religiosos de Belo Horizonte (MG): uma proposta metodológica para a análise espacial das religiões nas cidades”**, de **Felipe Baeta Casula** e **Daniel Pimenta de Prado**.

## Acesso

- site: <https://fecasula.github.io/espaco-religiao-bh>
- repositório: <https://github.com/fecasula/espaco-religiao-bh>
- painel interativo: <https://fecasula.shinyapps.io/religiao-mobilidade-bh/>
- apresentação em português: <https://fecasula.github.io/espaco-religiao-bh/apresentacao-pt.html>
- presentación en español: <https://fecasula.github.io/espaco-religiao-bh/es/presentacion-es.html>

## Contato

- **Felipe Baeta Casula:** felipe.baeta.pereira@gmail.com
- **Daniel Pimenta de Prado:** danielpimentadeprado@gmail.com

> **Escopo espacial da versão atual:** a preparação censitária, o cálculo do Índice de Cobertura Religiosa e o painel cartográfico estão homologados somente para **Belo Horizonte (MG), código IBGE 3106200**.

## Componentes

- website Quarto em português e espanhol;
- apresentações Reveal.js nos dois idiomas;
- painel Shiny do Índice de Cobertura Religiosa;
- funções R modulares e pipeline `{targets}`;
- resultados derivados e documentação metodológica;
- testes, licença e arquivo de citação.

## Estrutura principal

```text
.
├── _quarto.yml                 # configuração do site
├── index.qmd                   # página inicial em português
├── estudo.qmd                  # contexto e métodos
├── resultados.qmd              # resultados e tabelas retráteis
├── apresentacao-pt.qmd         # apresentação em português
├── es/                         # páginas e apresentação em espanhol
├── assets/                     # imagens, mapas e estilos
├── bibliography/               # referências e estilo ABNT
├── config/                     # parâmetros censitários e de deploy
├── R/                          # funções do projeto
├── scripts/                    # instalação, pipeline, renderização e deploy
├── shiny/                      # aplicativo do ICR
├── docs/                       # saída publicada pelo GitHub Pages
└── tests/                      # testes automatizados
```

## Origem dos dados

### Deslocamentos religiosos

A análise de deslocamentos utiliza a pesquisa **Mobilidade de Idosos**, conduzida pelo CEURB/UFMG. O repositório público trabalha apenas com resultados agregados ou bases desidentificadas.

### Estabelecimentos religiosos

Os estabelecimentos foram identificados no **Cadastro Nacional de Endereços para Fins Estatísticos (CNEFE 2022/IBGE)**. A classificação por confissão não estava pronta na fonte original: depois de uma busca inicial por palavras-chave, **622 estabelecimentos foram revisados manualmente**. Os registros descritos apenas como “IGREJA” foram censurados por não permitirem classificação confessional segura.

### Base censitária espacial

A população e a geometria dos setores vêm da **malha com atributos definitiva do Censo 2022 do IBGE**. Para Belo Horizonte, a base validada possui 5.166 setores distintos e 2.315.560 habitantes.

## Início rápido

Na raiz do projeto:

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

O site e as apresentações são renderizados para `docs/`. Após a renderização, faça commit e push das alterações dessa pasta. O GitHub Pages deve permanecer configurado para publicar a branch `main` a partir de `/docs`.

O painel Shiny é publicado separadamente:

```r
source("scripts/08_prepare_shiny_lockfile.R")
source("scripts/05_deploy_shiny.R")
```

## Auditoria metodológica

O cenário padrão usa 4 km/h e 9,7 minutos, produzindo raio de **646,67 m**. O texto submetido registrou 853,33 m e a legenda cartográfica original aproximadamente 649,33 m. Esses perfis históricos são preservados para auditoria, mas o cálculo consistente é adotado como padrão.

## Dados e ética

Microdados individuais originais devem permanecer em `data/private/`, diretório ignorado pelo Git. Produtos espaciais grandes e reconstruíveis também permanecem fora do versionamento.

## Citação e licença

A forma abreviada do primeiro autor deve usar o sobrenome principal **Casula**: `CASULA, F. B.`. Consulte `CITATION.cff` e `bibliography/references.bib`. Código sob licença MIT; dados de terceiros permanecem sujeitos às condições de suas fontes originais.
