validate_public_universe <- function(points) {
  checks <- tibble::tibble(
    teste = c("Total após censura", "Coordenadas válidas", "Confissão preenchida"),
    resultado = c(nrow(points)==3848, all(stats::complete.cases(points[,c("latitude","longitude")])), all(!is.na(points$confissao)))
  )
  if (!all(checks$resultado)) rlang::abort("Falha na validação do universo público de estabelecimentos.")
  checks
}

validate_coverage <- function(result) {
  stopifnot(all(result$icr >= 0 & result$icr <= 1), all(result$populacao_coberta >= 0))
  invisible(TRUE)
}
