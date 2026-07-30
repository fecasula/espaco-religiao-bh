# Carrega os módulos do projeto nos testes, independentemente do diretório
# temporariamente utilizado por testthat::test_dir().

.find_test_project_root <- function(start = getwd()) {
  current <- normalizePath(start, winslash = "/", mustWork = TRUE)

  repeat {
    has_description <- file.exists(file.path(current, "DESCRIPTION"))
    has_r_directory <- dir.exists(file.path(current, "R"))

    if (has_description && has_r_directory) {
      return(current)
    }

    parent <- dirname(current)
    if (identical(parent, current)) {
      stop(
        "Não foi possível localizar a raiz do projeto para executar os testes.",
        call. = FALSE
      )
    }

    current <- parent
  }
}

TEST_PROJECT_ROOT <- .find_test_project_root()

test_project_path <- function(...) {
  file.path(TEST_PROJECT_ROOT, ...)
}

r_files <- sort(list.files(
  test_project_path("R"),
  pattern = "\\.R$",
  full.names = TRUE
))

if (!length(r_files)) {
  stop("Nenhum arquivo R foi localizado na pasta R/ do projeto.", call. = FALSE)
}

for (file in r_files) {
  sys.source(file, envir = globalenv())
}
