read_public_trips <- function(path = project_path("data", "public", "od_religiao_public.csv")) {
  readr::read_csv(path, show_col_types = FALSE)
}

read_public_establishments <- function(path = project_path("data", "public", "pontos_religiosos_bh.csv")) {
  readr::read_csv(path, show_col_types = FALSE)
}

read_private_survey <- function(path, encoding = "ISO-8859-1") {
  if (!file.exists(path)) {
    rlang::abort(c(
      "Base confidencial não encontrada.",
      i = "Coloque o arquivo em data/private/ sem adicioná-lo ao Git."
    ))
  }
  readr::read_csv(path, locale = readr::locale(encoding = encoding), show_col_types = FALSE)
}

write_csv_atomic <- function(x, path) {
  fs::dir_create(fs::path_dir(path))
  tmp <- paste0(path, ".tmp")
  readr::write_csv(x, tmp, na = "")
  if (file.exists(path)) fs::file_delete(path)
  fs::file_move(tmp, path)
  invisible(path)
}
