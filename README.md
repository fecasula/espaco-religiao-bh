# Religião, mobilidade e cobertura urbana em Belo Horizonte


Projeto científico reprodutível associado ao trabalho **“Do estudo das práticas à análise dos equipamentos religiosos de Belo Horizonte (MG): uma proposta metodológica para a análise espacial das religiões nas cidades”**, de Felipe Baeta Casula Pereira e Daniel Pimenta de Prado.

> **Escopo espacial da versão atual:** a preparação censitária, o cálculo do Índice de Cobertura Religiosa e o painel cartográfico estão homologados somente para **Belo Horizonte (MG), código IBGE 3106200**. Uma versão aplicável a outros municípios está em desenvolvimento. Informar outro município produz uma interrupção controlada.

## Componentes

- website Quarto em português e espanhol;
- apresentações Reveal.js nos dois idiomas;
- painel Shiny do Índice de Cobertura Religiosa;
- funções R modulares e pipeline `{targets}`;
- dados públicos mínimos e resultados derivados;
- testes, GitHub Actions, licença e arquivo de citação;
- referências autor-data com formatação orientada à ABNT.

## Início rápido

Na raiz de uma cópia local do projeto:

```bash
Rscript scripts/00_install.R
Rscript scripts/02_prepare_census.R
Rscript scripts/03_run_pipeline.R
quarto preview
```

O endereço do repositório deve ser incluído somente depois de um remoto Git ser configurado.

## Base censitária espacial

A versão atual utiliza como fonte padrão a **malha com atributos definitiva do IBGE para o Censo 2022**. O GeoPackage estadual reúne geometria e população no mesmo produto, evitando a incompatibilidade observada quando malhas e agregados de versões diferentes eram combinados.

A configuração fica em `config/censo.yml`:

```yaml
municipio:
  codigo_ibge: "3106200"
  nome: "Belo Horizonte"
  uf: "MG"

fonte:
  tipo: "ibge_definitivo"
  arquivo_uf: "data/raw/census/ibge_definitivo/MG_setores_CD2022.gpkg"

saida:
  arquivo_municipal: "data/derived/setores_3106200_2022_definitivo.gpkg"
  arquivo_shiny: "shiny/data/setores_ativos.gpkg"
```

Na primeira execução, o script baixa aproximadamente 177 MB. No Windows, `download.metodo: auto` tenta `wininet` primeiro e `libcurl` depois, favorecendo redes institucionais que utilizam proxy ou autenticação integrada ao sistema. Também é possível baixar o arquivo manualmente e colocá-lo no caminho configurado.

A base homologada possui:

- 5.166 códigos de setor após a consolidação de um setor multipartido;
- população total de 2.315.560 habitantes;
- códigos de 15 dígitos sem duplicidades;
- geometrias válidas e população não ausente.

Os relatórios de auditoria são gerados em `data/derived/auditoria/`. O produto espacial oficial permanece em GeoPackage.

## Setor multipartido

O código `310620005670833` aparece em duas feições no produto estadual, ambas com população 171. O pipeline une as geometrias e mantém a população uma única vez. A decisão fica registrada em `detalhe_setores_multipartidos.csv`.

## Arquitetura de publicação

O website e as apresentações são estáticos e podem ser publicados no GitHub Pages. O painel Shiny é publicado separadamente no shinyapps.io.

A configuração fica em `config/deployment.yml`; a conta local é indicada por `SHINYAPPS_ACCOUNT` no `.Renviron`, sem armazenar token ou secret no projeto. O pacote `{terra}` é fixado em um commit GitHub compatível com o GDAL do servidor. Para auditar e publicar:

```r
source("scripts/08_prepare_shiny_lockfile.R")
source("scripts/05_deploy_shiny.R")
```

O script de deploy valida a base censitária, os dois lockfiles, a versão local de `{terra}`, os arquivos enviados e as dependências detectadas. O `{rsconnect}` gera internamente o manifesto com `appMode = "shiny"`, evitando a manutenção manual de `manifest.json`. O endereço público é <https://fecasula.shinyapps.io/religiao-mobilidade-bh/>.



## Publicação do website e da apresentação

O painel Shiny está publicado em:

<https://fecasula.shinyapps.io/religiao-mobilidade-bh/>

O website e as apresentações Quarto são renderizados localmente para a pasta `docs/` e podem ser publicados no GitHub Pages usando apenas GitHub Desktop e a interface web do GitHub.

Sequência recomendada:

```r
source("scripts/04_render_site.R")
```

Depois, pelo GitHub Desktop, faça commit e push das alterações, incluindo a pasta `docs/`. No GitHub Web, configure **Settings → Pages → Deploy from a branch → main → /docs**.

Endereços esperados quando o repositório se chamar `religiao-mobilidade-bh` e o usuário GitHub for `fecasula`:

- site: <https://fecasula.github.io/religiao-mobilidade-bh/>
- apresentação: <https://fecasula.github.io/religiao-mobilidade-bh/apresentacao-pt.html>
- painel: <https://fecasula.shinyapps.io/religiao-mobilidade-bh/>

Se o repositório for publicado com outro nome, atualize `site-url` e `repo-url` em `_quarto.yml` antes de renderizar.

## Dados e ética

A base pública de deslocamentos foi desidentificada e não contém identificadores ou nomes de bairros. Microdados individuais originais devem permanecer em `data/private/`, diretório ignorado pelo Git. O GeoPackage estadual do IBGE e os produtos espaciais gerados também são ignorados por tamanho e devem ser reconstruídos pelo script.

## Auditoria metodológica central

A fórmula com 4 km/h e 9,7 minutos produz 646,67 m; o texto do manuscrito registra 853,33 m e o mapa aproximadamente 649,33 m. O aplicativo adota o cálculo consistente e mantém os valores históricos como perfis de auditoria.

Também foi registrada divergência entre a distribuição por confissão da tabela publicada e a classificação do CSV atual, embora ambos resultem em 3.848 pontos após a censura de “IGREJA”. Consulte `data/validation/reconciliacao_metodologica.csv`.

## ABNT

O CSL local padroniza citações autor-data e referências, mas a versão final deve passar por revisão humana segundo a norma e o manual institucional vigentes. Consulte `bibliography/LEIA-ME_ABNT.md`.

## Citação e licença

Use `CITATION.cff` e cite tanto o trabalho acadêmico quanto a versão do software utilizada. Código sob licença MIT; dados de terceiros permanecem sujeitos às condições de suas fontes originais.
