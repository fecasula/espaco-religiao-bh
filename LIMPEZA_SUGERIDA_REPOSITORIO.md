# Limpeza sugerida do repositório

Os itens abaixo **podem ser removidos do versionamento** se o objetivo for deixar o repositório mais limpo e mais fácil de entender. Antes de excluir, confira se você não precisa deles como histórico local.

## 1. Relatórios e instruções de patches antigos

- `INSTRUCOES_DE_ATUALIZACAO_v0.1.4.md`
- `INSTRUCOES_DE_ATUALIZACAO_v0.1.5.md`
- `INSTRUCOES_DE_ATUALIZACAO_v0.1.7.md`
- `INSTRUCOES_DE_ATUALIZACAO_v0.1.8.md`
- `INSTRUCOES_DE_ATUALIZACAO_v0.1.9.md`
- `INSTRUCOES_DE_ATUALIZACAO_v0.1.10.md`
- `INSTRUCOES_DE_ATUALIZACAO_v0.1.11.md`
- `INSTRUCOES_DE_ATUALIZACAO_v0.1.12.md`
- `RELATORIO_DE_VALIDACAO_v0.1.5.md`
- `RELATORIO_DE_VALIDACAO_v0.1.8.md`
- `RELATORIO_DE_VALIDACAO_v0.1.10.md`
- `RELATORIO_DE_VALIDACAO_v0.1.11.md`
- `RELATORIO_DE_VALIDACAO_v0.1.12.md`
- `ARQUIVOS_IMPACTADOS_SITE_v0.1.14.md`
- `RELATORIO_DE_ENTREGA.md`
- `LEIA_PRIMEIRO_PATCH.md`
- `LEIA_PRIMEIRO_RECUPERACAO_RSTUDIO.md`
- `PASSO_A_PASSO_GITHUB_DESKTOP_E_WEB.md`
- `ARQUIVOS_REMOVIDOS.txt`

## 2. Backups e artefatos temporários

- `PATCH_MANIFEST.json`
- `manifest_raiz_backup_20260729_214943.json`
- `renv.lock.backup-r-universe`
- `CHECKSUMS_SHA256.txt`
- `SHA256SUMS.txt`

## 3. Pastas de arquivo histórico

- `archive/rstudio-startup-recovery-20260730/`
- `archive/original_scripts/`
- `archive/brief_original.txt`

## 4. Itens que normalmente não precisam ficar no Git

- `shiny/manifest_rsconnect_original.json`
- `shiny/rsconnect/` (se você não quiser versionar metadados locais de publicação)
- `_freeze/` (se optar por regenerar sempre que renderizar)
- `_targets/` (artefatos locais do pipeline)

## 5. O que deve permanecer

- `_quarto.yml`
- páginas `.qmd`
- `assets/`
- `bibliography/`
- `config/`
- `R/`
- `scripts/`
- `shiny/`
- `tests/`
- `docs/` (porque é a pasta publicada pelo GitHub Pages)
- `README.md`, `LICENSE`, `CITATION.cff`, `.gitignore`
