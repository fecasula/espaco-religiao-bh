# Relatório da primeira versão

## Escopo entregue

A versão 0.1.0 transforma os materiais fornecidos em um repositório acadêmico reprodutível, bilíngue e pronto para versionamento. A arquitetura separa site estático, apresentação e aplicativo Shiny, além de organizar dados, funções, pipeline, testes e documentação.

## Melhorias aplicadas aos scripts originais

- remoção de caminhos absolutos como `D:/deslocamentos_religiao`;
- substituição de dependências Java do pacote `xlsx` por `readxl`/`readr`;
- padronização UTF-8 e tratamento explícito do encoding original;
- correção da faixa de renda textual de R$2.600 a R$4.600;
- correção do objeto de saída da preparação da base RMBH;
- separação entre dados confidenciais, públicos e derivados;
- parametrização do intervalo de confiança (Wilson ou Wald);
- funções espaciais com dissolução de buffers e controle de dupla contagem;
- testes automatizados do raio, universo e privacidade.

## Pontos que exigem decisão autoral

1. confirmar a versão definitiva da classificação confessional;
2. confirmar se a população do ICR deve ser total ou exclusivamente 60+;
3. configurar o remoto Git antes de inserir URLs de repositório; a URL pública do Shiny já está registrada;
4. confirmar os metadados de Ardila-Pinto et al. (2025);
5. revisar a lista bibliográfica e a prova final conforme ABNT/instituição;
6. validar visualmente mapas e tabelas após a primeira renderização em R/Quarto.

## Limitação desta entrega

A estrutura, os dados derivados, o YAML, os arquivos tabulares e a consistência interna foram verificados no ambiente de geração. O ambiente não possui R nem Quarto CLI, portanto a renderização integral e a execução do aplicativo devem ser feitas localmente ou pelo GitHub Actions incluído no repositório.

## Atualização 0.1.4 — escopo espacial e configuração censitária

A preparação censitária passou a utilizar `config/censo.yml`, com Belo Horizonte (código IBGE 3106200) como padrão, perfis de geometria para desenvolvimento e publicação e saída em GeoPackage. O script também contém um bloco de inputs opcionais.

A análise espacial desta versão permanece homologada somente para Belo Horizonte. A tentativa de informar outro município é interrompida com mensagem explícita, pois os pontos religiosos, o CRS métrico, os parâmetros de mobilidade e as validações do ICR ainda são específicos do município. A generalização municipal está em desenvolvimento.

Para reduzir o custo computacional durante testes, o perfil de desenvolvimento utiliza geometria simplificada. Os resultados acadêmicos finais devem ser reproduzidos com o perfil de publicação e geometria original.

## Atualização 0.1.5 — base definitiva do IBGE

A preparação espacial foi migrada para a malha com atributos definitiva do Censo 2022, fornecida diretamente pelo IBGE em GeoPackage. Essa fonte reúne geometria e população, evitando incompatibilidades entre versões de malha e agregados.

A base de Belo Horizonte contém 5.167 feições e 5.166 códigos distintos. O setor `310620005670833` possui duas partes com população 171; o pipeline dissolve as geometrias e mantém a população uma única vez. O produto homologado possui 5.166 setores e população total de 2.315.560 habitantes.

O script inclui download por `wininet` e `libcurl`, validação de integridade, gravação atômica, auditoria de setores multipartidos e manifesto da fonte. A parte espacial continua restrita a Belo Horizonte; a generalização municipal está em desenvolvimento.
