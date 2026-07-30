# Relatório de validação — v0.1.10

## Falha corrigida

O `manifest.json` era criado e validado por caminho absoluto, mas esse mesmo
caminho era enviado a `rsconnect::deployApp()`. O `{rsconnect}` resolve
`manifestPath` a partir de `appDir`, o que duplicava o caminho no Windows.

## Alteração

- o caminho absoluto continua sendo usado para validação e remoção segura;
- `manifest_path_for_deploy()` confirma que o arquivo está diretamente em
  `shiny/` e retorna `manifest.json`;
- `deployApp()` recebe o caminho relativo;
- foram adicionados testes de regressão para o comportamento.

## Verificações realizadas neste ambiente

- inspeção estrutural dos arquivos R modificados;
- confirmação de que o script de deploy usa o retorno relativo;
- confirmação de que o patch preserva a estrutura de diretórios;
- geração e verificação dos hashes SHA-256 e dos ZIPs.

A execução dos testes R e o deploy real dependem da instalação local do R,
`{rsconnect}`, das credenciais e do shinyapps.io, portanto devem ser confirmados
na máquina do projeto.
