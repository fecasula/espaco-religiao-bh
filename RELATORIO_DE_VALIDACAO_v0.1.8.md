# Relatório de validação — v0.1.8

## Correção principal

Os dois arquivos `renv.lock` passaram a conter os metadados legados `GithubUsername`, `GithubRepo`, `GithubRef` e `GithubSHA1`, além dos campos `Remote*` do `{renv}`.

## Padronizações aplicadas

- configuração de publicação centralizada em `config/deployment.yml`;
- conta e nome do aplicativo retirados do código e resolvidos por variáveis de ambiente com padrões explícitos;
- criação de `R/deployment.R` para validação e escrita atômica dos lockfiles;
- `scripts/05_deploy_shiny.R` independente do diretório de trabalho;
- manifesto gerado e validado antes do upload;
- deploy realizado por `manifestPath`, evitando que um segundo manifesto divergente seja criado;
- token e secret removidos do modelo `.Renviron`;
- snapshot de instalação corrigido para o modo `explicit` declarado na documentação;
- `jsonlite` declarado em `DESCRIPTION`;
- testes de configuração e compatibilidade do deploy adicionados.

## Validações estáticas executadas

- JSON válido em `renv.lock`, `shiny/renv.lock`, `MANIFEST.json` e `PATCH_MANIFEST.json`;
- YAML válido em `config/deployment.yml`;
- versão do projeto consistente como 0.1.8;
- SHA de `{terra}` com 40 caracteres hexadecimais;
- ausência de `.Renviron`, `.Rhistory`, `.git`, `data/private` e bases censitárias brutas nos pacotes distribuídos.

## Limitação

A execução completa do R e o envio ao shinyapps.io dependem do ambiente local do usuário. O patch inclui um preflight que interrompe o processo antes do upload caso a versão local de `{terra}`, o lockfile ou o manifesto não correspondam à configuração fixada.
