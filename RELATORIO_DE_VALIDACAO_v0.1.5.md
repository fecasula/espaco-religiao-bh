# Relatório de validação da versão 0.1.5

## Verificações realizadas no ambiente de geração

- leitura válida de `config/censo.yml`, `_quarto.yml` e `CITATION.cff`;
- estrutura DCF válida de `DESCRIPTION`;
- balanceamento de parênteses, colchetes e chaves nos arquivos R modificados;
- verificação de escapes inválidos em strings R;
- sincronização de `R/config.R` e `R/coverage.R` com as cópias usadas pelo Shiny;
- geração de manifesto de arquivos e checksums SHA-256;
- criação de ZIP do patch e ZIP consolidado do projeto.

## Controles implementados no código

- fonte oficial definitiva do IBGE em GeoPackage;
- download por `wininet` e `libcurl`;
- validação de tamanho mínimo e camada esperada;
- seleção exclusiva de Belo Horizonte (`3106200`);
- exigência de códigos de setor com 15 dígitos;
- bloqueio de população ausente, negativa ou não finita;
- consolidação de feições multipartidas apenas quando a população coincide;
- referência homologada de 5.166 setores e 2.315.560 habitantes;
- gravação temporária e substituição atômica dos GeoPackages;
- relatórios de diagnóstico, multipartição e proveniência;
- cálculo de cobertura independente do nome da coluna espacial (`geom` ou `geometry`).

## Limitação da validação

O ambiente de geração não possui uma instalação do R. Portanto, os testes automatizados, a execução do `{targets}`, a abertura do Shiny e a renderização Quarto devem ser confirmados na máquina do projeto. A sequência recomendada está em `INSTRUCOES_DE_ATUALIZACAO_v0.1.5.md`.
