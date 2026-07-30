proportion_ci <- function(x, method = c("wilson", "wald"), conf_level = 0.95) {
  method <- match.arg(method)
  n <- length(x)
  k <- sum(x, na.rm = TRUE)
  p <- k / n
  z <- stats::qnorm(1 - (1 - conf_level) / 2)
  if (method == "wald") {
    se <- sqrt(p * (1 - p) / n)
    return(tibble::tibble(estimate = p, conf.low = pmax(0, p-z*se), conf.high = pmin(1, p+z*se)))
  }
  den <- 1 + z^2 / n
  center <- (p + z^2/(2*n)) / den
  half <- z * sqrt((p*(1-p) + z^2/(4*n))/n) / den
  tibble::tibble(estimate = p, conf.low = pmax(0, center-half), conf.high = pmin(1, center+half))
}

summarise_category <- function(data, variable, method = "wilson") {
  variable <- rlang::enquo(variable)
  n_total <- nrow(data)
  data |>
    dplyr::count(!!variable, name = "n") |>
    dplyr::rowwise() |>
    dplyr::mutate(ci = list(proportion_ci(c(rep(TRUE, n), rep(FALSE, n_total-n)), method))) |>
    tidyr::unnest(ci) |>
    dplyr::ungroup()
}

summarise_modes <- function(data, method = "wilson") {
  prop <- summarise_category(data, modo_transporte, method)
  time <- data |>
    dplyr::group_by(modo_transporte) |>
    dplyr::summarise(
      tempo_medio = mean(tempo_minutos, na.rm = TRUE),
      n_tempo = sum(!is.na(tempo_minutos)),
      sd_tempo = stats::sd(tempo_minutos, na.rm = TRUE),
      erro = dplyr::if_else(n_tempo > 1, stats::qt(.975, n_tempo-1) * sd_tempo/sqrt(n_tempo), NA_real_),
      tempo_ic_inf = tempo_medio - erro,
      tempo_ic_sup = tempo_medio + erro,
      .groups = "drop"
    )
  dplyr::left_join(prop, time, by = "modo_transporte")
}
