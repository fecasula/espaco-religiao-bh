# Executa o pipeline targets a partir de qualquer diretório de trabalho.

find_project_root <- function(start = getwd()) {
  current <- normalizePath(start, winslash = "/", mustWork = TRUE)

  repeat {
    if (
      file.exists(file.path(current, "DESCRIPTION")) &&
        file.exists(file.path(current, "_targets.R"))
    ) {
      return(current)
    }

    parent <- dirname(current)
    if (identical(parent, current)) {
      stop("Não foi possível localizar a raiz do projeto.", call. = FALSE)
    }

    current <- parent
  }
}

if (!requireNamespace("targets", quietly = TRUE)) {
  stop("Instale o pacote targets antes de executar o pipeline.", call. = FALSE)
}

project_root <- find_project_root()
old_wd <- setwd(project_root)
on.exit(setwd(old_wd), add = TRUE)

message("Projeto: ", project_root)
message(
  "Executando o pipeline com a base censitária definitiva configurada em config/censo.yml."
)

targets::tar_make()
