# Relatório de validação — v0.1.11

## Correção

O fluxo de publicação não fornece mais `manifestPath` ao `deployApp()`. O manifesto passa a ser criado internamente pelo `{rsconnect}` com `appMode = "shiny"`, `quarto = FALSE` e `dependencyResolution = "strict"`.

## Verificações estruturais

- nenhum `writeManifest()` permanece nos scripts 05 e 08;
- nenhum `manifestPath` permanece no script 05;
- o script 05 informa explicitamente o modo Shiny e a resolução estrita;
- `R/deployment.R` remove manifestos residuais e valida a dependência `{terra}`;
- os lockfiles e o pin GitHub de `{terra}` foram preservados;
- os arquivos JSON e YAML do projeto foram analisados estruturalmente;
- os ZIPs foram testados quanto à integridade.

A execução dos testes R e o deploy real dependem do ambiente local, das credenciais e do serviço shinyapps.io.
