# Renderização segura do site Quarto a partir da raiz do projeto ativo.
# Este script NÃO usa dirname(rstudioapi::getActiveProject()), pois
# getActiveProject() já retorna a pasta raiz do projeto.

options(warn = 1)

obter_raiz_projeto <- function() {
  raiz <- NULL

  if (requireNamespace("rstudioapi", quietly = TRUE) &&
      rstudioapi::isAvailable()) {
    raiz <- rstudioapi::getActiveProject()
  }

  if (is.null(raiz) || !nzchar(raiz) || !dir.exists(raiz)) {
    raiz <- getwd()
  }

  normalizePath(raiz, winslash = "/", mustWork = TRUE)
}

raiz_projeto <- obter_raiz_projeto()

arquivos_obrigatorios <- c(
  "_quarto.yml",
  "index.qmd",
  "estudo.qmd",
  "resultados.qmd",
  "apresentacao-pt.qmd",
  "es/index.qmd",
  "es/estudio.qmd",
  "es/resultados.qmd",
  "es/presentacion-es.qmd"
)

faltantes <- arquivos_obrigatorios[
  !file.exists(file.path(raiz_projeto, arquivos_obrigatorios))
]

if (length(faltantes) > 0L) {
  stop(
    paste0(
      "A pasta detectada não contém a versão atual do projeto.\n",
      "Raiz detectada: ", raiz_projeto, "\n",
      "Arquivos ausentes: ", paste(faltantes, collapse = ", ")
    ),
    call. = FALSE
  )
}

qmd_raiz <- list.files(
  raiz_projeto,
  pattern = "\\.qmd$",
  full.names = FALSE,
  recursive = FALSE
)

qmd_es <- list.files(
  file.path(raiz_projeto, "es"),
  pattern = "\\.qmd$",
  full.names = FALSE,
  recursive = FALSE
)

cat("\n========================================\n")
cat("RAIZ DO PROJETO:\n", raiz_projeto, "\n", sep = "")
cat("QMD na raiz: ", length(qmd_raiz), "\n", sep = "")
cat("QMD em es/: ", length(qmd_es), "\n", sep = "")
cat("Total esperado nesta renderização: ",
    length(qmd_raiz) + length(qmd_es), "\n", sep = "")
cat("========================================\n\n")

if (!requireNamespace("quarto", quietly = TRUE)) {
  stop(
    "O pacote 'quarto' não está instalado nesta biblioteca do R.",
    call. = FALSE
  )
}

pasta_anterior <- getwd()
on.exit(setwd(pasta_anterior), add = TRUE)
setwd(raiz_projeto)

# O cache interno é reconstruível e pode conservar referências antigas.
if (dir.exists(".quarto")) {
  unlink(".quarto", recursive = TRUE, force = TRUE)
}

quarto::quarto_render(
  input = ".",
  quiet = FALSE
)

saidas_esperadas <- c(
  "docs/index.html",
  "docs/estudo.html",
  "docs/resultados.html",
  "docs/apresentacao-pt.html",
  "docs/es/index.html",
  "docs/es/estudio.html",
  "docs/es/resultados.html",
  "docs/es/presentacion-es.html"
)

informacoes <- file.info(saidas_esperadas)
informacoes$arquivo <- rownames(informacoes)
rownames(informacoes) <- NULL

cat("\nARQUIVOS PRINCIPAIS GERADOS:\n")
print(
  informacoes[, c("arquivo", "size", "mtime")],
  row.names = FALSE
)

if (any(!file.exists(saidas_esperadas))) {
  ausentes <- saidas_esperadas[!file.exists(saidas_esperadas)]
  stop(
    paste(
      "A renderização terminou, mas faltaram:",
      paste(ausentes, collapse = ", ")
    ),
    call. = FALSE
  )
}

cat("\nRenderização concluída a partir da raiz correta.\n")
