clean_income <- function(x) {
  raw <- as.character(x)

  # Mantém a convenção brasileira: vírgula decimal e ponto de milhar.
  # Exemplo: "R$ 1.620,00" deve resultar em 1620, e não em NA.
  cleaned <- raw |>
    stringr::str_squish() |>
    stringr::str_replace_all("[^0-9,.-]", "")

  missing_code <- is.na(raw) | cleaned %in% c("", ".", "99", "99999")

  value <- suppressWarnings(
    readr::parse_number(
      raw,
      locale = readr::locale(
        decimal_mark = ",",
        grouping_mark = "."
      ),
      trim_ws = TRUE
    )
  )

  value[missing_code] <- NA_real_
  as.numeric(value)
}

count_religious_trips <- function(data) {
  motive_cols <- names(data)[stringr::str_detect(names(data), "^motivo_trajeto[0-9]+(seg|ter|quar|quin|sex|sab|dom)$")]
  if (!length(motive_cols)) rlang::abort("Nenhuma coluna de motivo de trajeto foi encontrada.")
  data |>
    dplyr::mutate(
      n_deslocamentos = rowSums(
        dplyr::across(
          dplyr::all_of(motive_cols),
          ~ as.integer(stringr::str_detect(stringr::str_to_lower(dplyr::coalesce(as.character(.x), "")), "^religi"))
        ),
        na.rm = TRUE
      )
    )
}

prepare_survey_model_base <- function(data, municipality = NULL) {
  if (!is.null(municipality)) data <- dplyr::filter(data, municipio == municipality)
  data |>
    count_religious_trips() |>
    dplyr::mutate(
      renda_num = clean_income(renda1),
      renda = cut(
        renda_num,
        breaks = c(-Inf, 1620, 2600, 4600, Inf),
        labels = c("Até R$1620", "R$1620 a R$2600", "R$2600 a R$4600", "Acima de R$4600"),
        right = TRUE
      ),
      raca = dplyr::case_when(
        cor_raca %in% c("Branca", "Amarela") ~ "Brancos",
        cor_raca %in% c("Preta", "Parda") ~ "Negros",
        TRUE ~ NA_character_
      ),
      sexo = genero1,
      dif_andar = dplyr::case_when(
        dif_andar == "n_o_tem_dificuldade" ~ "Sem mobilidade reduzida",
        !is.na(dif_andar) ~ "Com mobilidade reduzida",
        TRUE ~ NA_character_
      ),
      estadocivil = dplyr::case_when(
        estadocivil %in% c("casado_a__com_pessoa_do_sexo_diferente", "uni_o_est_vel_com_pessoa_do_mesmo_sexo", "uni_o_est_vel_com_pessoa_do_sexo_diferente") ~ "Casado/a",
        estadocivil == "solteiro_a" ~ "Solteiro/a",
        estadocivil == "vi_vo_a" ~ "Viúvo/a",
        estadocivil == "separado_a_desquitado_a" ~ "Separado/a",
        TRUE ~ NA_character_
      ),
      religiao = as.integer(n_deslocamentos > 0),
      religiao2 = as.integer(n_deslocamentos > 1)
    ) |>
    dplyr::select(sexo, raca, idade1, estadocivil, renda, dif_andar, religiao, religiao2)
}

prepare_religious_od <- function(data, municipality = "Belo Horizonte") {
  data |>
    janitor::clean_names() |>
    dplyr::mutate(person_id = as.character(person_id)) |>
    dplyr::filter(
      municipio == municipality,
      stringr::str_detect(stringr::str_to_lower(dplyr::coalesce(motivo_trajeto, "")), "^religi")
    ) |>
    dplyr::transmute(
      person_id, dia,
      municipio_resid = municipio,
      municipio_relig = cidade_destino,
      bairro_resid = bairro,
      bairro_relig = bairro_destino,
      tempo_desloc, modo_trajeto, companhia
    )
}
