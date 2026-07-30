library(testthat)

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

project_root <- find_project_root()
old_wd <- setwd(project_root)
on.exit(setwd(old_wd), add = TRUE)

testthat::test_dir(
  file.path(project_root, "tests", "testthat"),
  reporter = "summary"
)
