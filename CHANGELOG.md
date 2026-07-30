# Changelog

## 0.1.12 — manifesto Shiny corrigido antes do upload

- gera o manifesto com `rsconnect::writeManifest(appMode = "shiny")`;
- garante `metadata$appmode = "shiny"`;
- injeta `GithubUsername`, `GithubRepo`, `GithubRef` e `GithubSHA1` no registro de cada pacote GitHub;
- replica os metadados GitHub na descrição embutida do pacote para compatibilidade com o parser do shinyapps.io;
- valida o manifesto final antes do upload;
- usa `manifestPath = "manifest.json"`, relativo à pasta `shiny`;
- remove o manifesto temporário somente depois do deploy;
- adiciona testes sintéticos para o formato efetivamente enviado ao servidor.

## 0.1.11 — deploy direto com manifesto interno do rsconnect

- remove o uso de `manifestPath` e a geração manual de `shiny/manifest.json` no fluxo de produção;
- corrige o erro `Manifest must contain metadata$appmode`;
- passa `appMode = "shiny"`, `quarto = FALSE` e `dependencyResolution = "strict"` diretamente ao `deployApp()`;
- remove manifestos residuais antes da validação e do upload;
- mantém a normalização dos lockfiles e o pin reproduzível de `{terra}` via GitHub;
- valida a linha de `{terra}` devolvida por `appDependencies()` antes do deploy;
- envolve os scripts 05 e 08 em funções principais, garantindo limpeza e restauração do diretório de trabalho;
- adiciona testes de regressão para impedir o retorno de `manifestPath` ao script de publicação.

## 0.1.10 — caminho relativo do manifesto no deploy

- corrige a duplicação de caminho que fazia o `{rsconnect}` procurar `shiny/C:/.../shiny/manifest.json`;
- mantém o caminho absoluto apenas para criação, validação e limpeza do manifesto;
- passa `manifestPath = "manifest.json"` ao `deployApp()`, conforme a resolução relativa a `appDir`;
- valida que o manifesto está diretamente dentro de `shiny/` e possui o nome esperado;
- adiciona testes de regressão para caminhos absolutos, diretórios com espaços e execução no Windows.

## 0.1.9 — comparação canônica de versões de pacotes

- corrige a falsa divergência entre `terra 1.9.41`, exibida por `packageVersion()`, e `terra 1.9-41`, registrada no `DESCRIPTION` e nos lockfiles;
- adiciona normalização centralizada de versões, tratando ponto e hífen como separadores equivalentes;
- mantém `1.9-41` como grafia canônica nos lockfiles de publicação;
- aplica a comparação normalizada à biblioteca local, ao pin de dependências e à validação dos lockfiles;
- adiciona testes de regressão para impedir que a incompatibilidade reapareça.

## 0.1.8 — manifesto reproduzível para shinyapps.io

- corrige o erro `GithubUsername must be specified for GitHub package source`;
- mantém simultaneamente os campos `Remote*`, usados pelo `{renv}`, e `Github*`, exigidos pelo manifesto legado do shinyapps.io;
- fixa `terra 1.9-41` no commit GitHub `afe97b77`;
- adiciona `config/deployment.yml` como fonte única das configurações de publicação;
- cria `R/deployment.R` com validação dos lockfiles, da conta, dos arquivos do aplicativo e do manifesto;
- atualiza `scripts/05_deploy_shiny.R` para localizar a raiz do projeto, gerar um `manifest.json` validado e publicar exatamente esse manifesto;
- adiciona `scripts/08_prepare_shiny_lockfile.R` para auditoria prévia do deploy;
- remove token e secret do modelo `.Renviron`;
- corrige o modo do snapshot em `scripts/00_install.R` para `explicit`, coerente com o `DESCRIPTION`;
- adiciona testes automatizados do fluxo de publicação.

## 0.1.7 — correção do tratamento de renda

- corrige a conversão de valores monetários no padrão brasileiro;
- converte corretamente valores como `R$ 1.620,00`, `1.620` e `1.620,50`;
- preserva os códigos de ausência `99` e `99999` como valores ausentes;
- amplia os testes automatizados do tratamento de renda.

## 0.1.5 — base espacial definitiva do IBGE

- substitui o fluxo espacial padrão `geobr + censobr` pela malha com atributos definitiva do IBGE;
- utiliza geometria e população provenientes do mesmo GeoPackage estadual;
- adiciona download automático com `wininet` e `libcurl` em ordem configurável;
- valida tamanho, camada, CRS, códigos, geometrias e população;
- consolida o setor multipartido `310620005670833` sem duplicar seus 171 habitantes;
- homologa 5.166 setores distintos e população total de 2.315.560 habitantes;
- gera diagnóstico, detalhe de setores multipartidos e manifesto de proveniência;
- altera o produto oficial para `setores_3106200_2022_definitivo.gpkg`;
- atualiza `{targets}` e o Shiny para utilizar exclusivamente a base definitiva;
- corrige o cálculo espacial para não depender do nome físico da coluna geométrica (`geom` ou `geometry`);
- mantém a combinação preliminar anterior apenas como registro histórico;
- reforça na documentação que a parte espacial funciona somente para Belo Horizonte e que a versão multimunicipal está em desenvolvimento.

## 0.1.4 — configuração censitária e escopo espacial explícito

- adiciona `config/censo.yml` com Belo Horizonte como município padrão;
- adiciona bloco de inputs opcionais em `scripts/02_prepare_census.R`;
- mantém GeoPackage como formato espacial oficial;
- cria perfis de geometria de desenvolvimento e publicação;
- gera nomes de arquivo por município, ano e resolução;
- usa `shiny/data/setores_ativos.gpkg` como cópia estável do painel;
- bloqueia municípios diferentes de Belo Horizonte com mensagem metodológica;
- documenta que a generalização municipal está em desenvolvimento;
- adiciona testes para configuração, bloqueio de escopo e nomenclatura dos arquivos.

## 0.1.0 — 2026-07-29

- primeira arquitetura completa Quarto/Shiny bilíngue;
- organização reprodutível de dados e funções;
- resultados descritivos e modelos derivados;
- painel ICR parametrizável;
- auditoria do raio e da classificação confessional;
- documentação ABNT, testes e GitHub Actions.


## v0.1.6

- Corrige o carregamento dos módulos R pela suíte de testes.
- Corrige caminhos de dados públicos nos testes.
- Adiciona scripts/07_run_tests.R.
- Torna scripts/03_run_pipeline.R independente do diretório atual.
