# Renderização local do website e das apresentações Quarto.
# Método recomendado para publicar via GitHub Desktop + GitHub Pages:
# 1. Renderizar localmente para docs/.
# 2. Fazer commit de docs/ pelo GitHub Desktop.
# 3. Configurar GitHub Pages no navegador para main / docs.

find_project_root <- function(path = getwd()) {
  path <- normalizePath(path, winslash = "/", mustWork = TRUE)

  repeat {
    markers <- file.path(path, c("_quarto.yml", ".git", "renv.lock"))
    if (any(file.exists(markers))) {
      return(path)
    }

    parent <- dirname(path)
    if (identical(parent, path)) {
      stop("Não foi possível localizar a raiz do projeto.", call. = FALSE)
    }

    path <- parent
  }
}

project_root <- find_project_root()
setwd(project_root)

message("Projeto: ", normalizePath(project_root, winslash = "/", mustWork = TRUE))

if (!requireNamespace("quarto", quietly = TRUE)) {
  stop(
    "Instale o pacote quarto e o Quarto CLI antes de renderizar o site.",
    call. = FALSE
  )
}

if (!file.exists("_quarto.yml")) {
  stop("Arquivo _quarto.yml não encontrado na raiz do projeto.", call. = FALSE)
}

# Evita que GitHub Pages processe arquivos com Jekyll.
writeLines(character(0), ".nojekyll")

message("Renderizando website e apresentações para docs/...")
quarto::quarto_render(input = project_root)

if (!dir.exists("docs")) {
  stop("A renderização não criou a pasta docs/.", call. = FALSE)
}

writeLines(character(0), file.path("docs", ".nojekyll"))

required_outputs <- c(
  "docs/index.html",
  "docs/indice-cobertura.html",
  "docs/apresentacao-pt.html",
  "docs/es/presentacion-es.html"
)

missing_outputs <- required_outputs[!file.exists(required_outputs)]

if (length(missing_outputs)) {
  stop(
    "Arquivos esperados não foram gerados: ",
    paste(missing_outputs, collapse = ", "),
    call. = FALSE
  )
}

text_files <- list.files(
  c(".", "es"),
  pattern = "\\.(qmd|yml|yaml|md)$",
  recursive = TRUE,
  full.names = TRUE,
  ignore.case = TRUE
)

placeholder_hits <- unlist(lapply(text_files, function(file) {
  lines <- readLines(file, warn = FALSE, encoding = "UTF-8")
  hits <- grep("URL-DO-SHINY|SEU-USUARIO|SEU_USUARIO", lines, value = TRUE)

  if (!length(hits)) {
    return(NULL)
  }

  paste0(file, ": ", hits)
}), use.names = FALSE)

if (length(placeholder_hits)) {
  warning(
    "Ainda existem placeholders em arquivos de texto:\n",
    paste(placeholder_hits, collapse = "\n"),
    call. = FALSE
  )
}

message("Renderização concluída.")
message("Arquivos principais:")
for (file in required_outputs) {
  message("- ", normalizePath(file, winslash = "/", mustWork = TRUE))
}
message("\nPróximo passo: commit e push da pasta docs/ pelo GitHub Desktop.")
