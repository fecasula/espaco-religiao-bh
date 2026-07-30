# Executa a suíte de testes a partir de qualquer diretório de trabalho.

find_project_root <- function(start = getwd()) {
  current <- normalizePath(start, winslash = "/", mustWork = TRUE)

  repeat {
    if (
      file.exists(file.path(current, "DESCRIPTION")) &&
        dir.exists(file.path(current, "tests", "testthat"))
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

if (!requireNamespace("testthat", quietly = TRUE)) {
  stop("Instale o pacote testthat antes de executar os testes.", call. = FALSE)
}

project_root <- find_project_root()
old_wd <- setwd(project_root)
on.exit(setwd(old_wd), add = TRUE)

message("Projeto: ", project_root)
message("Executando testes em: ", file.path(project_root, "tests", "testthat"))

testthat::test_dir(
  file.path(project_root, "tests", "testthat"),
  reporter = "summary"
)
