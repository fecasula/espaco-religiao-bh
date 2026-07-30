prepare_model_data <- function(data) {
  data |>
    dplyr::mutate(
      renda = stringr::str_replace(renda, stringr::fixed("R$2300 a R$4600"), "R$2600 a R$4600"),
      sexo = factor(sexo, levels = c("Masculino", "Feminino")),
      raca = factor(raca, levels = c("Brancos", "Negros")),
      estadocivil = factor(estadocivil, levels = c("Solteiro/a", "Separado/a", "Casado/a", "Viúvo/a")),
      renda = factor(renda, levels = c("Até R$1620", "R$1620 a R$2600", "R$2600 a R$4600", "Acima de R$4600")),
      dif_andar = factor(dif_andar, levels = c("Sem mobilidade reduzida", "Com mobilidade reduzida"))
    ) |>
    tidyr::drop_na(sexo, raca, idade1, estadocivil, renda, dif_andar, religiao, religiao2)
}

fit_religion_models <- function(data) {
  data <- prepare_model_data(data)
  f_demo_1 <- religiao ~ idade1 + sexo + raca + estadocivil
  f_socio_1 <- update(f_demo_1, . ~ . + renda)
  f_general_1 <- update(f_socio_1, . ~ . + dif_andar)
  f_demo_2 <- update(f_demo_1, religiao2 ~ .)
  f_socio_2 <- update(f_socio_1, religiao2 ~ .)
  f_general_2 <- update(f_general_1, religiao2 ~ .)
  purrr::map(
    list(demo_1=f_demo_1, socio_1=f_socio_1, geral_1=f_general_1,
         demo_2=f_demo_2, socio_2=f_socio_2, geral_2=f_general_2),
    ~stats::glm(.x, family=stats::binomial(), data=data)
  )
}

model_tidy_or <- function(models) {
  purrr::imap_dfr(models, ~broom::tidy(.x, exponentiate=TRUE, conf.int=TRUE) |>
    dplyr::mutate(modelo=.y, .before=1))
}
